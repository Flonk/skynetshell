// --- modes -------------------------------------------------------------------
// A mode is a point in ModeParams space. The sequencer walks the MODES
// playlist and eases the global P between neighbours over TRANS_DUR at each
// boundary — so any mode expressible as parameters transitions for free.
// Structural modes (different traversal/tile content) branch on
// modeFrom/modeTo/modeBlend instead; keep those branches rare.

struct ModeParams {
    float pad;      // squircle padding to its cell edge
    float bg;       // background noise + stars visibility
    float sheen;    // spherical top-lit shading strength
    float ring;     // hard rim ring (2d border) visibility, 0..1
    float distort;  // glass refraction strength at the tile rim
    float wham;     // extra global zoom-out
};

const int MODE_COUNT = 2;
const ModeParams MODES[MODE_COUNT] = ModeParams[MODE_COUNT](
    // 2d: flat — border ring, no noise/stars/sheen/distortion
    ModeParams(TILE_PAD_2D, 0., 0.,           1., 0.,      0.),
    // 3d: planetscape
    ModeParams(TILE_PAD,    1., SPHERE_SHADE, 0., DISTORT, WHAM_ZOOM)
);
const float MODE_DUR[MODE_COUNT] = float[MODE_COUNT](480., 480.);

// dev knobs: skip ahead in the schedule (seconds) / override every mode's
// duration. e.g. DEV_MODE_DUR = 20. cycles the whole playlist quickly, and
// DEV_MODE_OFFSET = 20.*float(k) then starts right at mode k. 0 = off
const float DEV_MODE_OFFSET = 0.;
const float DEV_MODE_DUR    = 0.;

ModeParams P;          // active params, filled per frame by sequenceModes()
int   modeFrom  = 0;   // structural hooks branch on these
int   modeTo    = 0;
float modeBlend = 1.;  // eased from->to progress, 1 once settled

float modeDur(int i){ return DEV_MODE_DUR > 0. ? DEV_MODE_DUR : MODE_DUR[i]; }

ModeParams mixParams(ModeParams a, ModeParams b, float t){
    return ModeParams(
        mix(a.pad, b.pad, t), mix(a.bg, b.bg, t), mix(a.sheen, b.sheen, t),
        mix(a.ring, b.ring, t), mix(a.distort, b.distort, t),
        mix(a.wham, b.wham, t));
}

void sequenceModes(){
    float t = iTime + DEV_MODE_OFFSET;
    float total = 0.;
    for(int i = 0; i < MODE_COUNT; i++) total += modeDur(i);
    float c = mod(t, total);
    float acc = 0.;
    for(int i = 0; i < MODE_COUNT; i++){
        float d = modeDur(i);
        if(c < acc + d){
            modeTo    = i;
            modeFrom  = (i + MODE_COUNT - 1) % MODE_COUNT;
            modeBlend = smoothstep(0., TRANS_DUR, c - acc);
            break;
        }
        acc += d;
    }
    if(t < modeDur(0)) modeFrom = modeTo;   // very first block: no flip-in
    P = mixParams(MODES[modeFrom], MODES[modeTo], modeBlend);
}
