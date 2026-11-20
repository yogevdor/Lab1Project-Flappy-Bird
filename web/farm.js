// Web Worker of the "render farm" (see README). One worker plays the LOGIC role, the others the RENDER role.
//
//  logic : runs the game in real time (72.8 game ticks/s, the board's frame rate). The chip is clocked through the
//          whole frame, but only the rows around the fish are drawn (collision detection needs nothing else).
//          Once per game frame it saves the chip state (a few KB) and posts it.
//  render: restores such a snapshot into its own copy of the chip and draws that one frame completely.
//
// The page forwards snapshots to idle render workers and shows the frames they return.
importScripts('game.js');

const SNAP = '/snap.bin';
const TICK_HZ = 31.5e6 / (832 * 520);
const MAX_TICKS = 8;                           // 1 real + 7 extra start-of-frame pulses per logic frame

let M = null, role = '', fbPtr = 0;
const pool = [];                               // frame buffers handed back by the page

async function init(r) {
  role = r;
  M = await FlappyFish();
  M._sim_init();                               // also runs the first evaluation, which loads the ROM contents
  if (role === 'logic') {
    M._sim_sync();                             // logic frames start at a start-of-frame pulse
    loop();
  } else {
    fbPtr = M._sim_framebuffer();
  }
  postMessage({ type: 'ready', role });
}

// ---- logic role ------------------------------------------------------------------------------------
let acc = 1, last = 0, statT = 0, ticksDone = 0, frameId = 0, lastEmit = 0;
let minInterval = 1000 / TICK_HZ;                // ms between snapshots; the page raises it when renderers cannot keep up

function loop() {
  const now = performance.now();
  if (!last) { last = now; statT = now; }
  const dt = Math.min(Math.max(now - last, 0), 100);   // ms; clamp after the tab slept
  last = now;
  acc += dt * TICK_HZ / 1000;
  const n = Math.min(Math.floor(acc), MAX_TICKS);
  if (n >= 1 && now - lastEmit >= minInterval - 0.5) {   // several ticks per picture when pictures are rarer than ticks
    lastEmit = now;
    acc -= n;
    if (acc > MAX_TICKS) acc = MAX_TICKS;
    M._sim_logic_begin(n - 1);                 // the game ticks happen here
    M._sim_snapshot();                         // -> /snap.bin
    M._sim_logic_end();                        // rest of the frame; only the rows around the fish are drawn
    const data = M.FS.readFile(SNAP);
    postMessage({ type: 'snap', id: ++frameId, data: data.buffer }, [data.buffer]);
    ticksDone += n;
  }
  if (now - statT >= 1000) {
    postMessage({ type: 'stats', ticks: ticksDone, sec: (now - statT) / 1000 });
    ticksDone = 0; statT = now;
  }
  setTimeout(loop, 1);
}

// ---- messages --------------------------------------------------------------------------------------
onmessage = (e) => {
  const m = e.data;
  switch (m.type) {
    case 'init':
      init(m.role);
      break;
    case 'key':                                // PS/2 scan code event
      if (M && role === 'logic') M._sim_key(m.sc, m.down);
      break;
    case 'pace':                               // minimum ms between snapshots
      minInterval = m.ms;
      break;
    case 'recycle':                            // a displayed frame buffer comes back
      if (pool.length < 8) pool.push(m.fb);
      break;
    case 'sw':                                 // SW[1:0]
      if (M && role === 'logic') M._sim_set_switches(m.v);
      break;
    case 'render': {                           // draw one frame from a snapshot
      const t0 = performance.now();
      M.FS.writeFile(SNAP, new Uint8Array(m.data));
      M._sim_restore();
      M._sim_render_end();
      const fb = new Uint8Array(pool.pop() || new ArrayBuffer(640 * 480 * 4));
      fb.set(M.HEAPU8.subarray(fbPtr, fbPtr + 640 * 480 * 4));
      const hex = [];
      for (let i = 0; i < 6; i++) hex.push(M._sim_hex(i));
      postMessage({ type: 'frame', id: m.id, fb: fb.buffer, hex, ms: performance.now() - t0 }, [fb.buffer]);
      break;
    }
  }
};
