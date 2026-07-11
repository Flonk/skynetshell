// yamp: yasuo quadtree scene, X glyphs replaced by the and& ampersand.
// The build (convert-shaders.sh) concatenates NN_*.glsl in order, then
// shader.glsl:
//   00_knobs  — every tuning constant, incl. the mode table and playlist
//   10_lib    — generic helpers (rng, easing, squircle, stars)
//   20_modes  — mode sequencer machinery, structural-mode hooks
//   shader    — the scene: amp SDFs, quadtree, key indicator, mainImage
//
// Per tile, on its own clock (speed n*2*SPEED), the loop runs:
//   off (long) -> rotate (J/P counter-spin 360) -> off (short)
//   -> fill J (gradient wipe) -> fill P (offset wipe) -> on -> unfill -> loop
// sdJ/sdP sample a baked SDF texture (gen_sdf.py); the design gap (PAD) of
// the J is carved out of the P, so the pieces stay separated even mid-spin.
// Tiles are squircles (SQUIRCLENESS knob); the rim band refracts the content
// like glass (DISTORT knobs). The background noise (iChannel1) counter-scrolls
// and gets sucked toward each tile's rim, piling up into a bright event
// horizon that forms the border (PILE knobs) — no drawn ring.

// --- knobs ------------------------------------------------------------------
const float SPEED      = 0.8;    // global animation speed multiplier
const float T_OFF1     = 6.0;   // off, long (dark grey)
const float T_ROTATE   = 1.749; // J/P fast 360 spin
const float T_OFF2     = 2.5;   // off, short
const float T_FILL     = 1.104;  // duration of each white fill wipe
const float T_FILL_LAG = 0.067; // P wipe starts this long after J wipe
const float T_ON       = 2.;  // fully white hold
const float T_UNFILL   = 1.;  // wipes reverse out
const float T_REST     = 0.2;   // grey tail before the loop restarts

const float AMP_SCALE  = 0.94;  // glyph size within its tile
const float BIG_CHANCE = 0.15;  // chance a cell promotes to one huge amp
const float SCROLL     = 0.03; // vertical scroll speed

const float SQUIRCLENESS = 0.;   // tile shape: 0 = circle, 1 = square
const float DISTORT_BAND = 0.12;  // rim band that refracts

const float DARKEN = 0.25;        // off-amp darkening per subdivision level

const float NOISE_LO    = 0.0;   // background noise brightness range
const float NOISE_HI    = 0.05;
const float NOISE_SCALE = 3.0;   // background noise texture frequency
const float BG_SPEED    = 0.3;   // background scroll, fraction of SCROLL
const float STAR_BRIGHT = 0.7;   // starfield brightness

const float PILE_BAND = 0.14;    // event-horizon falloff width (tile units)
const float PILE_PULL = 0.35;    // how far the noise is sucked inward (uv units)
const float PILE_GAIN = 7.;      // brightness pile-up at the horizon

const float SCROLL_MIN = 0.045;  // tile content scroll speed, random per tile
const float SCROLL_MAX = 0.09;

// mode transitions ease over TRANS_DUR; the global zoom flips on ZOOM_PERIOD,
// offset by half — tuned so with the default two-mode playlist the four
// quarters run 2d-in, 2d-out, 3d-out, 3d-in
const float TRANS_DUR   = 1.2;   // mode/zoom flip transition duration
const float ZOOM_PERIOD = 60. * 8.; // seconds per zoom flip
const float ZOOM_OUT    = 0.30;  // global zoom-out amount
const float ZOOM_ECC    = 5.7;   // zoom target distance from screen center
const float ZOOM_DRIFT  = 2300.7;  // zoom target orbit period (s) — offbeat
                                 // vs ZOOM_PERIOD so the spot always differs

const float RING_BRIGHT = 0.3;    // border ring brightness
const float RING_WIDTH  = 0.0025; // border ring half-width, screen-height
                                  // units — same thickness at every level

// key indicator: on keypress a black circle fills the screen while a blue
// amp zooms in; each key bumps the amp, errors turn it red, inactivity
// reverses everything
const float IND_AMP    = 0.1;   // indicator amp scale (screen units)
const float IND_BUMP   = 0.04;   // per-key amp scale bump
const float IND_BRIGHT = 0.35;   // per-key brightness bump (toward white)
const float IND_LAG    = 0.08;   // circle leads the amp by this, in and out

// and& brand gradient, sampled from andamp-amp-blue.png (top -> bottom)
const vec3 GRAD_TOP = vec3(0.212, 0.671, 0.729);
const vec3 GRAD_BOT = vec3(0.063, 0.596, 0.706);

// --- modes -------------------------------------------------------------------
// a mode is one ModeParams entry in the playlist below; the sequencer
// (20_modes) walks it, easing between neighbours over TRANS_DUR
struct ModeParams {
    float pad;      // squircle padding to its cell edge
    float bg;       // background noise + stars visibility
    float light;    // spherical shade: brighten tile top toward white
    float dark;     // spherical shade: darken tile bottom toward black
    float ring;     // border ring visibility (styled by RING_BRIGHT/RING_WIDTH)
    float distort;  // glass refraction strength at the tile rim
    float wham;     // extra global zoom-out
};

const int MODE_COUNT = 2;
const ModeParams MODES[MODE_COUNT] = ModeParams[MODE_COUNT](
    //         pad   bg  light dark  ring distort wham
    // 2d: flat — border ring, no noise/stars/shade/distortion
    ModeParams(0.01, 0., 0.,   0.,   1.,  0.,     0.),
    // 3d: planetscape. the event horizon dies out within the pad, so cells
    // of different levels stay continuous
    ModeParams(0.25, 1., 0.25, 0.75, 0.,  0.12,   0.05)
);
const float MODE_DUR[MODE_COUNT] = float[MODE_COUNT](480., 480.);

// dev knobs: skip ahead in the schedule (seconds) / override every mode's
// duration. e.g. DEV_MODE_DUR = 20. cycles the whole playlist quickly, and
// DEV_MODE_OFFSET = 20.*float(k) then starts right at mode k. 0 = off
const float DEV_MODE_OFFSET = 0.;
const float DEV_MODE_DUR    = 4.;

// derived state boundaries — don't touch, tune the knobs above
const float ROT_START    = T_OFF1;
const float FILLJ_START  = ROT_START + T_ROTATE + T_OFF2;
const float FILLP_START  = FILLJ_START + T_FILL_LAG;
const float ON_START     = FILLP_START + T_FILL;
const float UNFILL_START = ON_START + T_ON;
const float LOOP_LEN     = UNFILL_START + T_UNFILL + T_REST;
