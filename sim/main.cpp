// Verilator harness for TOP_FLAPPY_FISH: plays the role of the DE10 board.
//   - drives CLOCK_50 and the PS/2 pins (keyboard), SW[1:0]
//   - watches OVGA (the VGA connector signals) and assembles a 640x480 frame buffer
// Built either natively (test: writes PPM frames, see NATIVE below) or with Emscripten for the browser.
#include <cstdint>
#include <ctime>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <vector>

#include "VTOP_FLAPPY_FISH.h"
#include "VTOP_FLAPPY_FISH___024root.h"   // access to the registers added to the patched vga_controller, fish position
#include "verilated.h"
#include "verilated_save.h"
#ifdef VGA_PREFIX
#define CAT2(a, b) a##b
#define CAT(a, b) CAT2(a, b)
#define VGASIG(name) top->rootp->CAT(VGA_PREFIX, name)
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <pthread.h>
#include <sched.h>
#define EXPORT extern "C" EMSCRIPTEN_KEEPALIVE
// Verilator's runtime references these thread-affinity calls even single-threaded; Emscripten has none.
extern "C" {
int pthread_getaffinity_np(pthread_t, size_t, cpu_set_t *) { return -1; }
int pthread_setaffinity_np(pthread_t, size_t, const cpu_set_t *) { return -1; }
int sched_getcpu(void) { return 0; }
}
#else
#define EXPORT extern "C"
#endif

static const int W = 640, H = 480;

static VTOP_FLAPPY_FISH *top = nullptr;
static uint32_t fb[W * H];            // RGBA (little endian: 0xAABBGGRR) for canvas ImageData
static int px = 0, py = 0;
static bool line_has_pixels = false;
static bool hs_prev = true, vs_prev = true;
static bool frame_done = false;
static uint64_t cycles = 0;
static int step_y = 1;                  // row skipping (see sim_set_vstep)

// ---- PS/2 transmitter -------------------------------------------------------------------------
static std::deque<uint8_t> ps2_bytes;
static std::vector<int> ps2_bits;      // remaining bits of the current frame (start, 8 data, parity, stop)
static size_t ps2_bit_idx = 0;
static int ps2_cnt = 0;                // cycle counter inside one bit period
static int ps2_gap = 0;
static const int PS2_HALF = 48;        // clocks per half PS2_CLK period

static void ps2_load_next() {
    uint8_t b = ps2_bytes.front();
    ps2_bytes.pop_front();
    ps2_bits.clear();
    ps2_bits.push_back(0);
    int ones = 0;
    for (int i = 0; i < 8; i++) { int v = (b >> i) & 1; ps2_bits.push_back(v); ones += v; }
    ps2_bits.push_back((ones & 1) ? 0 : 1);   // odd parity
    ps2_bits.push_back(1);
    ps2_bit_idx = 0;
    ps2_cnt = 0;
}

static void ps2_step() {
    if (ps2_bit_idx >= ps2_bits.size()) {          // idle between frames
        top->PS2_CLK = 1; top->PS2_DAT = 1;
        if (ps2_gap > 0) { ps2_gap--; return; }
        if (ps2_bytes.empty()) return;
        ps2_load_next();
    }
    if (ps2_cnt == 0) { top->PS2_DAT = ps2_bits[ps2_bit_idx]; top->PS2_CLK = 1; }
    else if (ps2_cnt == PS2_HALF) top->PS2_CLK = 0;            // falling edge: receiver samples
    if (++ps2_cnt == 2 * PS2_HALF) {
        ps2_cnt = 0;
        top->PS2_CLK = 1;
        if (++ps2_bit_idx >= ps2_bits.size()) { ps2_gap = 4 * PS2_HALF; top->PS2_DAT = 1; }
    }
}

// ---- clock / VGA capture ----------------------------------------------------------------------
static void tick() {
    ps2_step();
    top->CLOCK_50 = 0;
    top->eval();
    top->CLOCK_50 = 1;
    top->eval();
    cycles++;

    const uint32_t v = top->OVGA;
    const bool hs = (v >> 24) & 1;
    const bool vs = (v >> 25) & 1;
    const bool blank_n = (v >> 27) & 1;

    if (blank_n) {                                   // a visible pixel is on the wires
        if (px < W && py < H) {
            // OVGA = {clk, blank_n, sync_n, vs, hs, B[7:0], G[7:0], R[7:0]}  (pin assignments in Lab1Demo.qsf)
            uint32_t r = v & 0xFF, g = (v >> 8) & 0xFF, b = (v >> 16) & 0xFF;
            fb[py * W + px] = 0xFF000000u | (b << 16) | (g << 8) | r;
        }
        px++;
        line_has_pixels = true;
    }
    if (hs_prev && !hs) {                            // falling edge of HSYNC: next line
        px = 0;
        if (line_has_pixels) {
            py += step_y;
        }
        line_has_pixels = false;
    }
    if (vs_prev && !vs) {                            // falling edge of VSYNC: frame finished
        py = 0;
        frame_done = true;
    }
    hs_prev = hs;
    vs_prev = vs;
}

// With row skipping only every step_y-th row was simulated. Fill the rows in between. Measured against full-resolution
// frames, linear interpolation between the sampled rows above and below is best when every 2nd row is simulated; when
// only every 3rd or 4th is, interpolating just blurs, and the nearest sampled row is both sharper and closer.
// blend_on = 0 repeats the row above instead (original behaviour).
static int blend_on = 1;
static void fill_skipped_rows() {
    const int s = step_y;
    if (s <= 1) return;
    for (int y0 = 0; y0 < H; y0 += s) {
        const uint32_t *a = &fb[y0 * W];
        const int y1 = y0 + s;
        const uint32_t *b = (blend_on && y1 < H) ? &fb[y1 * W] : nullptr;
        for (int k = 1; k < s && y0 + k < H; k++) {
            uint32_t *dst = &fb[(y0 + k) * W];
            if (!b) { memcpy(dst, a, W * sizeof(uint32_t)); continue; }
            if (s > 2) { memcpy(dst, (2 * k < s) ? a : b, W * sizeof(uint32_t)); continue; }   // nearest sampled row
            for (int x = 0; x < W; x++) {                                                     // s == 2: average
                const uint32_t pa = a[x], pb = b[x];
                const uint32_t avg = (((pa ^ pb) & 0xFEFEFEFEu) >> 1) + (pa & pb);   // per-byte floor average
                dst[x] = 0xFF000000u | (avg & 0x00FFFFFFu);
            }
        }
    }
}

// ---- API used by the web page / test main -----------------------------------------------------
EXPORT void sim_init() {
    Verilated::randReset(0);
    top = new VTOP_FLAPPY_FISH;
    top->CLOCK_50 = 0;
    top->PS2_CLK = 1;
    top->PS2_DAT = 1;
    top->resetN_pin = 1;
    top->KEY = 1;
    top->SW = 0;
    top->AUDIN = 0;
    for (int i = 0; i < 1000; i++) tick();           // PLL "lock" releases the reset
}

// Runs until one full VGA frame has been produced (or a safety limit). Returns 1 if a frame completed.
EXPORT int sim_frame() {
    frame_done = false;
    for (int i = 0; i < 2000000 && !frame_done; i++) tick();
    if (frame_done) fill_skipped_rows();
    return frame_done ? 1 : 0;
}

// Game ticks per displayed frame = 1 + n (n = 0..7). Only available when vga_controller was patched
// (tools/patch_vga_controller.py); sim_has_ticks() tells the page.
EXPORT int sim_has_ticks() {
#ifdef VGA_PREFIX
    return 1;
#else
    return 0;
#endif
}
EXPORT void sim_set_extra_ticks(int n) {
#ifdef VGA_PREFIX
    VGASIG(extraTicks) = n & 7;
#else
    (void)n;
#endif
}

// Row skipping: only every n-th row (n = 1..4) is simulated, the harness repeats it. Call between frames.
EXPORT void sim_set_blend(int on) { blend_on = on ? 1 : 0; }

EXPORT void sim_set_vstep(int n) {
    step_y = (n < 1) ? 1 : (n > 4 ? 4 : n);
#ifdef VGA_PREFIX
    VGASIG(stepY) = step_y;
#endif
}

EXPORT uint32_t *sim_framebuffer() { return fb; }
EXPORT void sim_set_switches(int sw) { top->SW = sw & 3; }
EXPORT double sim_cycles() { return (double)cycles; }

// Queue a PS/2 scan code event. code: low byte = scan code, bit 8 = extended (E0). down: 1 = press, 0 = release.
EXPORT void sim_key(int code, int down) {
    if (code & 0x100) ps2_bytes.push_back(0xE0);
    if (!down) ps2_bytes.push_back(0xF0);
    ps2_bytes.push_back(code & 0xFF);
}

// 7-segment HEX displays (6 of them, 7 bits each, active low on the board)
EXPORT int sim_hex(int i) {
    switch (i) {
        case 0: return top->HEX0; case 1: return top->HEX1; case 2: return top->HEX2;
        case 3: return top->HEX3; case 4: return top->HEX4; default: return top->HEX5;
    }
}

// ---- "render farm" API -----------------------------------------------------------------------
// One "logic" simulator runs the game and only draws the rows where the fish can touch a pipe (collision
// detection needs nothing else). Once per game frame it saves the chip state at a point where all game ticks and
// key events of the frame are done and the first visible row has not started yet. "Render" simulators restore such a
// snapshot and draw that one frame completely; they can run in parallel (Web Workers).
static const int SNAPSHOT_CLOCKS = 3000;     // after the frame's start-of-frame pulse (see V_BACK in the VGA patch)

struct HarnessState {
    bool hs_prev, vs_prev;
    std::deque<uint8_t> ps2_bytes;
    std::vector<int> ps2_bits;
    size_t ps2_bit_idx;
    int ps2_cnt, ps2_gap;
};

static void harness_save(HarnessState &h) {
    h.hs_prev = hs_prev; h.vs_prev = vs_prev;
    h.ps2_bytes = ps2_bytes; h.ps2_bits = ps2_bits;
    h.ps2_bit_idx = ps2_bit_idx; h.ps2_cnt = ps2_cnt; h.ps2_gap = ps2_gap;
}

static void harness_load(const HarnessState &h) {
    hs_prev = h.hs_prev; vs_prev = h.vs_prev;
    ps2_bytes = h.ps2_bytes; ps2_bits = h.ps2_bits;
    ps2_bit_idx = h.ps2_bit_idx; ps2_cnt = h.ps2_cnt; ps2_gap = h.ps2_gap;
    px = 0; py = 0; line_has_pixels = false; frame_done = false;
}

static int fish_top_y() {
    int v = top->rootp->TOP_FLAPPY_FISH__DOT__fishTopLeftY & 0x7FF;
    return (v & 0x400) ? v - 0x800 : v;                 // signed 11 bit
}

static void run_clocks(int n) { for (int i = 0; i < n; i++) tick(); }

// Runs the chip up to the next start of a frame (VS falling edge), so that logic frames can start there.
EXPORT void sim_sync() {
    frame_done = false;
    for (int i = 0; i < 2000000 && !frame_done; i++) tick();
}

// 1st half of a logic frame: the start-of-frame pulse(s) happen here (extra = additional game ticks).
EXPORT void sim_logic_begin(int extra) {
    sim_set_extra_ticks(extra);
#ifdef VGA_PREFIX
    VGASIG(rowLo) = 0; VGASIG(rowHi) = H - 1;
#endif
    frame_done = false;
    run_clocks(SNAPSHOT_CLOCKS);
}

// Save the chip + harness state (call between sim_logic_begin and sim_logic_end). Returns the file size.
static int snapshot_to(const char *path) {
    VerilatedSave os;
    os.open(path);
    os << *top;
    HarnessState h;
    harness_save(h);
    uint8_t flags = (h.hs_prev ? 1 : 0) | (h.vs_prev ? 2 : 0);
    os << flags;
    uint32_t n = (uint32_t)h.ps2_bytes.size();
    os << n;
    for (uint8_t b : h.ps2_bytes) os << b;
    n = (uint32_t)h.ps2_bits.size();
    os << n;
    for (int b : h.ps2_bits) { uint8_t v = (uint8_t)b; os << v; }
    uint32_t idx = (uint32_t)h.ps2_bit_idx, cnt = (uint32_t)h.ps2_cnt, gap = (uint32_t)h.ps2_gap;
    os << idx << cnt << gap;
    os.close();
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fclose(f);
    return (int)size;
}

#ifdef __EMSCRIPTEN__
#define SNAP_FILE "/snap.bin"                    // in the in-memory file system
#else
#define SNAP_FILE "/tmp/farm.snap"
#endif
EXPORT int sim_snapshot() { return snapshot_to(SNAP_FILE); }

// 2nd half of a logic frame: only the rows around the fish are drawn (collision detection); runs to the next frame.
EXPORT int sim_logic_end() {
    const int y = fish_top_y();
    int lo = y - 4, hi = y + 36;
    if (lo < 0) lo = 0;
    if (hi > H - 1) hi = H - 1;
    if (hi < lo) hi = lo;
#ifdef VGA_PREFIX
    VGASIG(rowLo) = lo; VGASIG(rowHi) = hi;
#endif
    for (int i = 0; i < 2000000 && !frame_done; i++) tick();
    return frame_done ? 1 : 0;
}

// Render role: restore a snapshot (into this model) ...
static int restore_from(const char *path) {
    VerilatedRestore is;
    is.open(path);
    is >> *top;
    HarnessState h;
    uint8_t flags = 0;
    is >> flags;
    h.hs_prev = flags & 1; h.vs_prev = (flags >> 1) & 1;
    uint32_t n = 0;
    is >> n;
    h.ps2_bytes.clear();
    for (uint32_t i = 0; i < n; i++) { uint8_t b = 0; is >> b; h.ps2_bytes.push_back(b); }
    is >> n;
    h.ps2_bits.clear();
    for (uint32_t i = 0; i < n; i++) { uint8_t b = 0; is >> b; h.ps2_bits.push_back(b); }
    uint32_t idx = 0, cnt = 0, gap = 0;
    is >> idx >> cnt >> gap;
    h.ps2_bit_idx = idx; h.ps2_cnt = (int)cnt; h.ps2_gap = (int)gap;
    is.close();
    harness_load(h);
#ifdef VGA_PREFIX
    VGASIG(rowLo) = 0; VGASIG(rowHi) = H - 1; VGASIG(stepY) = 1;
#endif
    step_y = 1;
    return 1;
}

EXPORT int sim_restore() { return restore_from(SNAP_FILE); }

// ... and draw the frame completely (to the next start of a frame). The picture is in sim_framebuffer().
EXPORT int sim_render_end() {
    for (int i = 0; i < 2000000 && !frame_done; i++) tick();
    return frame_done ? 1 : 0;
}

#ifndef __EMSCRIPTEN__
// Native test harness:  ./sim <frames> <outdir> [ticksPerFrame=1] [hash]
//   - presses "8" (jump / start) at fixed GAME TICK numbers (multiples of 12, so they land on a frame
//     boundary for 1, 2, 3 or 4 ticks per frame) and dumps PPMs, or with "hash" prints a hash per frame.
static void dump(const char *dir, int n) {
    char name[256];
    snprintf(name, sizeof name, "%s/frame_%03d.ppm", dir, n);
    FILE *f = fopen(name, "wb");
    if (!f) return;
    fprintf(f, "P6\n%d %d\n255\n", W, H);
    for (int i = 0; i < W * H; i++) {
        uint32_t p = fb[i];
        fputc(p & 0xFF, f); fputc((p >> 8) & 0xFF, f); fputc((p >> 16) & 0xFF, f);
    }
    fclose(f);
}

static double band_mean(int y0, int y1) {     // mean brightness of rows [y0, y1)
    double sum = 0;
    for (int y = y0; y < y1; y++)
        for (int x = 0; x < W; x++) {
            uint32_t p = fb[y * W + x];
            sum += (p & 0xFF) + ((p >> 8) & 0xFF) + ((p >> 16) & 0xFF);
        }
    return sum / (3.0 * W * (y1 - y0));
}

static uint64_t fb_hash() {
    uint64_t h = 1469598103934665603ULL;
    for (int i = 0; i < W * H; i++) { h ^= fb[i]; h *= 1099511628211ULL; }
    return h;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    int frames = argc > 1 ? atoi(argv[1]) : 120;
    const char *dir = argc > 2 ? argv[2] : ".";
    int tpf = argc > 3 ? atoi(argv[3]) : 1;
    bool hash_mode = argc > 4;
    sim_init();
    if (getenv("FARMTEST")) {
        // Equivalence test: frames drawn by the farm (logic simulator + restored render simulator) must equal the
        // frames of a single simulator that draws everything, tick for tick.
        const int ticks = atoi(getenv("FARMTEST"));
        static const int press[] = {24, 96, 168, 240, 312};
        auto keys = [&](int n) {
            for (int p : press) {
                if (n == p)      sim_key(0x75, 1);
                if (n == p + 12) sim_key(0x75, 0);
            }
        };
        std::vector<uint64_t> A, B;
        for (int n = 0; n < ticks; n++) { keys(n); sim_frame(); A.push_back(fb_hash()); }   // reference

        VTOP_FLAPPY_FISH *L = new VTOP_FLAPPY_FISH, *R = new VTOP_FLAPPY_FISH;
        top = L;
        // bring L to reset-released state exactly like sim_init() does
        L->CLOCK_50 = 0; L->PS2_CLK = 1; L->PS2_DAT = 1; L->resetN_pin = 1; L->KEY = 1; L->SW = 0; L->AUDIN = 0;
        { ps2_bytes.clear(); ps2_bits.clear(); ps2_bit_idx = 0; ps2_cnt = 0; ps2_gap = 0; hs_prev = vs_prev = true; }
        run_clocks(1000);
        sim_sync();
        R->CLOCK_50 = 0; R->PS2_CLK = 1; R->PS2_DAT = 1; R->resetN_pin = 1; R->KEY = 1; R->SW = 0; R->AUDIN = 0;
        R->eval();                                           // first evaluation: loads the ROM contents
        double t_logic = 0, t_restore = 0, t_render = 0;
        long snap_size = 0;
        auto now_ms = []() { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec * 1e3 + t.tv_nsec / 1e6; };
        for (int n = 0; n < ticks; n++) {
            keys(n);
            double t0 = now_ms();
            sim_logic_begin(0);
            snap_size = sim_snapshot();
            sim_logic_end();
            double t1 = now_ms();
            HarnessState keep; harness_save(keep);                 // logic simulator's harness state
            int sx = px, sy = py; bool sl = line_has_pixels, sf = frame_done;
            top = R;
            sim_restore();
            double t2 = now_ms();
            sim_render_end();
            double t3 = now_ms();
            B.push_back(fb_hash());
            top = L;
            harness_load(keep); px = sx; py = sy; line_has_pixels = sl; frame_done = sf;
            t_logic += t1 - t0; t_restore += t2 - t1; t_render += t3 - t2;
        }
        int best_d = 0, best_ok = -1;
        for (int d = -3; d <= 3; d++) {
            int ok = 0, tot = 0;
            for (int m = 0; m < ticks; m++) if (m + d >= 0 && m + d < ticks) { tot++; ok += (B[m] == A[m + d]); }
            if (ok > best_ok) { best_ok = ok; best_d = d; }
        }
        printf("farm vs single simulator: best offset %+d, %d / %d frames identical\n", best_d, best_ok, ticks);
        for (int m = 0; m < ticks; m++) if (m + best_d >= 0 && m + best_d < ticks && B[m] != A[m + best_d]) { printf("  first mismatch at frame %d\n", m); break; }
        printf("snapshot %.2f MB | per frame: logic %.2f ms, restore %.2f ms, render %.2f ms\n",
               snap_size / 1048576.0, t_logic / ticks, t_restore / ticks, t_render / ticks);
        return 0;
    }
    sim_set_extra_ticks(tpf - 1);
    sim_set_vstep(getenv("SY") ? atoi(getenv("SY")) : 1);
    if (getenv("BLEND")) sim_set_blend(atoi(getenv("BLEND")));
    static const int press[] = {24, 96, 168, 240, 312, 384, 456};
    for (int n = 0; n < frames; n++) {
        long tick = (long)n * tpf;                                   // game ticks completed before this call
        for (int p : press) {
            if (tick == p)      sim_key(0x75, 1);                    // numpad 8 down
            if (tick == p + 12) sim_key(0x75, 0);                    // numpad 8 up
        }
        if (!sim_frame()) { fprintf(stderr, "no frame at %d\n", n); return 1; }
        if (hash_mode) printf("%d %016llx %.3f\n", n, (unsigned long long)fb_hash(), band_mean(8, 100));
        else if (n % 10 == 9 || n == 0) dump(dir, n);
    }
    if (!hash_mode) printf("ok: %d frames, %.0f cycles\n", frames, sim_cycles());
    return 0;
}
#endif
