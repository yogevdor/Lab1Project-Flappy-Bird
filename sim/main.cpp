// Verilator harness for TOP_FLAPPY_FISH: plays the role of the DE10 board.
//   - drives CLOCK_50 and the PS/2 pins (keyboard), SW[1:0]
//   - watches OVGA (the VGA connector signals) and assembles a 640x480 frame buffer
// Built either natively (test: writes PPM frames, see NATIVE below) or with Emscripten for the browser.
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <vector>

#include "VTOP_FLAPPY_FISH.h"
#include "verilated.h"
#ifdef VGA_PREFIX
#include "VTOP_FLAPPY_FISH___024root.h"   // access to the registers added to the patched vga_controller
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
            for (int k = 1; k < step_y && py + k < H && py < H; k++)    // repeat the sampled row
                memcpy(&fb[(py + k) * W], &fb[py * W], W * sizeof(uint32_t));
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
    sim_set_extra_ticks(tpf - 1);
    sim_set_vstep(getenv("SY") ? atoi(getenv("SY")) : 1);
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
