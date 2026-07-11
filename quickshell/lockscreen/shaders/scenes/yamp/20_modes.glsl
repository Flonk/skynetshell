// --- mode sequencer ------------------------------------------------------------
// The ModeParams struct and the MODES playlist live in 00_knobs. The
// sequencer walks the playlist and eases the global P between neighbours
// over TRANS_DUR at each boundary — so any mode expressible as parameters
// transitions for free. Structural modes (different traversal/tile content)
// branch on modeFrom/modeTo/modeBlend instead; keep those branches rare.

ModeParams P;          // active params, filled per frame by sequenceModes()
int   modeFrom  = 0;   // structural hooks branch on these
int   modeTo    = 0;
float modeBlend = 1.;  // eased from->to progress, 1 once settled

float modeDur(int i){ return DEV_MODE_DUR > 0. ? DEV_MODE_DUR : MODE_DUR[i]; }

ModeParams mixParams(ModeParams a, ModeParams b, float t){
    return ModeParams(
        mix(a.pad, b.pad, t), mix(a.bg, b.bg, t),
        mix(a.light, b.light, t), mix(a.dark, b.dark, t),
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
