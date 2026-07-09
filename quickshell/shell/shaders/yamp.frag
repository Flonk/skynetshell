#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

// ---------------------------------------------------------------------------
// Uniform block — Qt maps QML properties to these by name
// ---------------------------------------------------------------------------

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    // Shadertoy-compatible inputs
    float iTime;
    int iFrame;
    int u_indicator_type;

    float u_last_key_time;
    float u_last_failed_unlock_time;
    float u_auth_started_time;
    vec2 u_key_bases;

    vec3 iResolution;
    vec3 u_indicator_color;

    vec4 iMouse;
    vec4 iClock;
};

// Up to four input textures, resolved from QML properties.
layout(binding = 1) uniform sampler2D iChannel0;
layout(binding = 2) uniform sampler2D iChannel1;
layout(binding = 3) uniform sampler2D iChannel2;
layout(binding = 4) uniform sampler2D iChannel3;

// ---------------------------------------------------------------------------
// Shared constants
// ---------------------------------------------------------------------------

/// Canonical fail colour (227, 85, 50) in linear [0, 1] range.
const vec3 sk_fail_color = vec3(227.0 / 255.0, 85.0 / 255.0, 50.0 / 255.0);

// ---------------------------------------------------------------------------
// sk_ — skynetlock standard library
// ---------------------------------------------------------------------------

float sk_ease_out_back(float t) {
    const float c1 = 4.0;
    const float c3 = c1 + 1.0;
    float x = t - 1.0;
    return 1.0 + c3 * x * x * x + c1 * x * x;
}

float sk_keypulse_envelope() {
    float age = iTime - u_last_key_time;
    float ramp = clamp(age / 0.03, 0.0, 1.0);
    float p = mix(u_key_bases.x, 1.0, ramp);
    float decay = clamp((age - 0.03) / 0.08, 0.0, 1.0);
    return p * (1.0 - decay * decay);
}

float sk_key_envelope() {
    float age = iTime - u_last_key_time;
    float ramp = clamp(age / 0.06, 0.0, 1.0);
    float p = mix(u_key_bases.y, 1.0, ramp);
    float decay = clamp((age - 1.06) / 2.0, 0.0, 1.0);
    return p * (1.0 - sk_ease_out_back(pow(decay, 0.65)));
}

float sk_fail_envelope() {
    float age = iTime - u_last_failed_unlock_time;
    float p = clamp(age / 0.03, 0.0, 1.0);
    float decay = clamp((age - 0.27) / 2.0, 0.0, 1.0);
    return p * pow(1.0 - decay, 3.0);
}

float sk_load_envelope() {
    float isLoading = step(-999.0, u_auth_started_time);
    float authAge = iTime - u_auth_started_time;
    float endedAge = iTime - u_last_failed_unlock_time;
    float loading = isLoading * clamp((authAge - 0.1) / 0.03, 0.0, 1.0);
    float unloading = (1.0 - isLoading) * clamp(1.0 - endedAge / 0.03, 0.0, 1.0);
    return loading + unloading;
}

float sk_attention_envelope() {
    float kf = sk_key_envelope() + sk_fail_envelope();
    float load = sk_load_envelope();
    kf = max(kf, load - 1.0);
    return min(kf + load, 1.0);
}

// ---------------------------------------------------------------------------
// Shader body follows (injected by convert-shaders.sh)
// ---------------------------------------------------------------------------
// yasuo quadtree scene, X glyphs replaced by the and& ampersand.
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
const float T_OFF1     = 5.0;   // off, long (dark grey)
const float T_ROTATE   = 1.749; // J/P fast 360 spin
const float T_OFF2     = 2.0;   // off, short
const float T_FILL     = 1.104;  // duration of each white fill wipe
const float T_FILL_LAG = 0.067; // P wipe starts this long after J wipe
const float T_ON       = 1.55;  // fully white hold
const float T_UNFILL   = 0.134;  // wipes reverse out
const float T_REST     = 0.2;   // grey tail before the loop restarts

const float AMP_SCALE  = 0.94;  // glyph size within its tile
const float BIG_CHANCE = 0.15;  // chance a cell promotes to one huge amp
const float SCROLL     = 0.03; // vertical scroll speed

const float SQUIRCLENESS = 0.;   // tile shape: 0 = circle, 1 = square
const float DISTORT      = 0.12;  // glass refraction strength at the tile rim
const float DISTORT_BAND = 0.12;  // rim band that refracts
const float TILE_PAD     = 0.15;   // squircle padding to its cell edge; the
                                  // horizon dies out within it, so cells of
                                  // different levels stay continuous
const float SPHERE_SHADE = 0.15;   // 3d: brighten tile top / darken bottom

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

// 2d/3d cycle: starts flat (border, no noise/stars/sheen/distortion), then
// flips to the 3d planetscape and back every MODE_PERIOD. The global zoom
// flips on the same period, offset by half — so the four quarters run
// 2d-in, 2d-out, 3d-out, 3d-in.
const float MODE_PERIOD = 40.;   // seconds per mode
const float TRANS_DUR   = 1.2;   // flip transition duration
const float WHAM_ZOOM   = 0.05;  // extra zoom-out in 3d mode
const float ZOOM_OUT    = 0.30;  // global zoom-out amount
const float ZOOM_ECC    = 5.7;   // zoom target distance from screen center
const float ZOOM_DRIFT  = 2300.7;  // zoom target orbit period (s) — offbeat
                                 // vs MODE_PERIOD so the spot always differs
const float RING_2D     = 0.3;   // 2d-mode border brightness
const float BORDER_2D   = 0.01;  // 2d-mode border half-width
const float TILE_PAD_2D = 0.01;  // tile padding in 2d mode

// key indicator: on keypress a black circle fills the screen while a blue
// amp zooms in; each key bumps the amp, errors turn it red, inactivity
// reverses everything
const float IND_AMP    = 0.45;   // indicator amp scale (screen units)
const float IND_BUMP   = 0.12;   // per-key amp scale bump
const float IND_BRIGHT = 0.35;   // per-key brightness bump (toward white)

// and& brand gradient, sampled from andamp-amp-blue.png (top -> bottom)
const vec3 GRAD_TOP = vec3(0.212, 0.671, 0.729);
const vec3 GRAD_BOT = vec3(0.063, 0.596, 0.706);

// derived state boundaries — don't touch, tune the knobs above
const float ROT_START    = T_OFF1;
const float FILLJ_START  = ROT_START + T_ROTATE + T_OFF2;
const float FILLP_START  = FILLJ_START + T_FILL_LAG;
const float ON_START     = FILLP_START + T_FILL;
const float UNFILL_START = ON_START + T_ON;
const float LOOP_LEN     = UNFILL_START + T_UNFILL + T_REST;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define S(d) (1.-smoothstep(-1.3,1.3, (d)*iResolution.y ))

float random (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

// alternates 0/1 every `period`, easing over TRANS_DUR at each flip;
// block 0 (and anything before it) is 0
float flipflop(float t, float period){
    float k = floor(t/period);
    float s = mod(k, 2.);
    float prev = (k < 0.5) ? 0. : 1.-s;
    return mix(prev, s, smoothstep(0., TRANS_DUR, t - k*period));
}
float mode3d(){ return flipflop(iTime, MODE_PERIOD); }

// tile zoom pulse: up during rotate, hold, down during unfill
float pulseAnim(float n){
    float frame = mod(iTime*n*2.*SPEED, LOOP_LEN);
    if(frame >= ROT_START && frame < ROT_START+T_ROTATE)
        return cubicInOut((frame-ROT_START)/T_ROTATE);
    if(frame >= ROT_START+T_ROTATE && frame < UNFILL_START)
        return 1.;
    if(frame >= UNFILL_START && frame < UNFILL_START+T_UNFILL)
        return 1.-cubicInOut((frame-UNFILL_START)/T_UNFILL);
    return 0.;
}

// --- and& ampersand: baked SDF texture (gen_sdf.py) -------------------------
// iChannel0: R = J piece, G = P piece, glyph space [-SDF_BOX,SDF_BOX]^2
// (v flipped), distances clamped to +-SDF_RANGE/2
const float PAD = 0.0464;      // design gap, measured from the artwork
const float SDF_BOX   = 0.75;
const float SDF_RANGE = 0.25;

float sdJ(vec2 p) {
    float far = length(p) - 0.57;   // J fits in radius 0.554
    if (far > 0.05) return far;
    vec2 uv = vec2(p.x, -p.y)/(2.0*SDF_BOX) + 0.5;
    return (texture(iChannel0, uv).r - 0.5) * SDF_RANGE;
}
float sdP(vec2 p) {
    float far = length(p) - 0.66;   // P fits in radius 0.646
    if (far > 0.09) return far;
    vec2 uv = vec2(p.x, -p.y)/(2.0*SDF_BOX) + 0.5;
    return (texture(iChannel0, uv).g - 0.5) * SDF_RANGE;
}

// --- ampersand tile animation ----------------------------------------------
const vec2  CJ = vec2(-0.0644,-0.2581);   // J centroid (spin pivot)
const vec2  CP = vec2( 0.0148, 0.0562);   // P centroid
const vec2  SEED_J = vec2(-0.2871, 0.0267);  // wedge tip
const vec2  SEED_P = vec2(-0.0192, 0.4142);  // top of the loop
const float RJ = 0.76;                    // wipe radii covering each piece
const float RP = 1.04;

float fillAnim(float frame, float start){
    if(frame < start) return 0.;
    if(frame < start+T_FILL) return cubicInOut((frame-start)/T_FILL);
    if(frame < UNFILL_START) return 1.;
    if(frame < UNFILL_START+T_UNFILL) return 1.-cubicInOut((frame-UNFILL_START)/T_UNFILL);
    return 0.;
}

vec2 rotAround(vec2 p, vec2 c, float a){ return (p-c)*Rot(a)+c; }

// squircle tile: circle/rounded-box mix (Hyeve, shadertoy) — a true SDF,
// unlike the superellipse. Returns (distance, gradient); the gradient is
// the same mix of both shapes' gradients (mix is linear, so it's exact).
vec3 sdSquircle(vec2 p, float r, float n){
    float lp = max(length(p), 1e-6);
    vec2 q = abs(p) - n*r;
    vec2 mq = max(q, 0.);
    float lmq = length(mq);
    float square = min(max(q.x,q.y),0.) + lmq - (r - n*r);
    vec2 gsq = (lmq > 1e-6) ? sign(p)*mq/lmq
             : ((q.x > q.y) ? vec2(sign(p.x),0.) : vec2(0.,sign(p.y)));
    vec2 g = mix(p/lp, gsq, n);
    g /= max(length(g), 1e-6);
    return vec3(mix(lp - r, square, n), g);
}

// brand gradient across the glyph (glyph space spans y in [-0.5,0.5])
vec3 ampGradient(vec2 p){
    return mix(GRAD_BOT, GRAD_TOP, clamp(p.y + 0.5, 0., 1.));
}

// two-layer sparse starfield, points jittered within their grid cell
float stars(vec2 p){
    float v = 0.;
    for(int i = 0; i < 2; i++){
        vec2 g = p * (6. + 5.*float(i)) + float(i)*3.7;
        vec2 id = floor(g);
        vec2 f = fract(g) - 0.5;
        float rn = random(id);
        vec2 off = (vec2(random(id + 4.2), random(id + 8.4)) - 0.5)*0.7;
        v += smoothstep(0.06, 0., length(f - off)) * step(0.9, rn) * fract(rn*91.17);
    }
    return v;
}

vec3 drawAmp(vec2 p, float n, vec3 sq, float depth, float tileDepth, vec2 tp){
    float m3d = mode3d();
    float pad = mix(TILE_PAD_2D, TILE_PAD, m3d);

    // spherical vertical coordinate (+1 top rim .. -1 bottom)
    float ny = clamp(sq.z * (1. - pad + sq.x) / (1. - pad), -1., 1.);
    float tshade = pow(1. - DARKEN, tileDepth);

    // event horizon (3d): outside the tile the noise and stars get sucked
    // toward the rim and pile up into a bright horizon — background and tile
    // border in one. windowed to zero within the pad so neighbouring cells
    // agree
    float pull = PILE_BAND / (max(sq.x, 0.) + PILE_BAND);
    pull *= pull * smoothstep(pad, 0., sq.x);
    vec2 tps = tp + sq.yz * pull * PILE_PULL;
    float nse = texture(iChannel1, fract(tps)).r;
    float v3 = (mix(NOISE_LO, NOISE_HI, nse) + stars(tps) * STAR_BRIGHT)
             * (1. + PILE_GAIN * pull);
    vec3 col = mix(vec3(v3) * m3d, vec3(0.), S(sq.x));

    // outside pixels are done — skip both glyph SDFs entirely
    if (sq.x * iResolution.y > 1.5) return col;

    float frame = mod(iTime*n*2.*SPEED, LOOP_LEN);
    p /= AMP_SCALE;

    // rotate state: J and P counter-spin a full turn
    vec2 pJ = p, pP = p;
    if(frame >= ROT_START && frame < ROT_START+T_ROTATE){
        float a = cubicInOut((frame-ROT_START)/T_ROTATE)*6.28318530718;
        float dir = (fract(n)<0.5)? -1. : 1.;
        pJ = rotAround(p, CJ, dir*a);
        pP = rotAround(p, CP, -dir*a);
    }

    float dj = sdJ(pJ);
    float dp = max(sdP(pP), PAD - dj);            // P with the J carved out
    float dAmp = min(dj, dp) * AMP_SCALE;
    dAmp = max(sq.x, dAmp);
    // grey base, darker per subdivision level
    col = mix(col, vec3(0.3) * pow(1. - DARKEN, depth), S(dAmp));

    // fill states: brand-gradient wipes clipped inside each piece
    float fj = fillAnim(frame, FILLJ_START);
    float fp = fillAnim(frame, FILLP_START);
    float wj = max(dj, length(pJ-SEED_J) - (fj*(RJ+0.02)-0.02));
    float wp = max(dp, length(pP-SEED_P) - (fp*(RP+0.02)-0.02));
    float dw = min(wj, wp) * AMP_SCALE;
    dw = max(sq.x, dw);
    col = mix(col, ampGradient(p), S(dw));

    // 3d: spherical top-lit sheen — blend toward white above the equator
    // and black below. scaled by the TILE's depth shade (never the per-amp
    // one, which would break the gradient inside a tile), and off in 2d
    col = mix(col, vec3(step(0., ny)),
              abs(ny) * SPHERE_SHADE * tshade * m3d * S(sq.x));

    // 2d mode: hard border ring on the rim
    float dring = abs(sq.x + BORDER_2D) - BORDER_2D;
    col = mix(col, vec3(RING_2D), S(dring) * (1. - m3d));
    return col;
}

vec3 quadTree(vec2 p, float nn, float depth, vec2 tp){
    p*=2.;
    vec3 sq = sdSquircle(p, 1. - mix(TILE_PAD_2D, TILE_PAD, mode3d()), SQUIRCLENESS);

    // glass: inside the rim band the content is sampled outward along the
    // squircle gradient, so the amps look refracted near the edge (3d only)
    float lens = smoothstep(-DISTORT_BAND, 0., sq.x);
    p += sq.yz * lens*lens * DISTORT * mode3d();

    // extra-large level: sometimes the whole cell is one huge ampersand
    if(fract(nn*57.31) < BIG_CHANCE){
        return drawAmp(p*0.5, nn+0.3, sq, depth, depth, tp);
    }

    if(nn<0.5){
        p.y-=iTime*mix(SCROLL_MIN, SCROLL_MAX, nn*2.)+nn;
        p*=1.2;
    } else {
        p*=1.2+pulseAnim(nn)*0.5;
    }

    vec2 id = floor(p);
    vec2 gr = (p-id)-0.5;

    float n = random(id)*nn;
    float n2 = n;
    vec2 cell = id;
    float ad = depth;   // per-amp depth; `depth` stays the tile's

    // four subdivision levels (the last two add the extra-small amps)
    float thresholds[4] = float[](0.3+nn, 0.8+nn, 0.9+nn*0.5, 0.93+nn*0.5);

    for (int i = 0; i < 4; i++)
    {
        n = random(cell + id + float(i) * 12.34+nn);

        if (n < thresholds[i])
            break;

        gr *= 2.0;
        cell = floor(gr);
        gr = fract(gr) - 0.5;
        ad += 1.;
    }

    return drawAmp(gr, n2+nn, sq, ad, depth, tp);
}

vec3 render(vec2 p, vec2 tp){
    p.y-=iTime*SCROLL;
    p*=2.;
    vec2 id = floor(p);
    vec2 gr = (p-id)-0.5;

    float n = random(id);
    float n2 = n;
    vec2 cell = id;
    float depth = 0.;

    float thresholds[3] = float[](0.6, 0.8, 0.9);

    for (int i = 0; i < 3; i++)
    {
        n = random(cell + id + float(i) * 12.34);

        if (n < thresholds[i])
            break;

        gr *= 2.0;
        cell = floor(gr);
        gr = fract(gr) - 0.5;
        depth += 1.;
    }

    return quadTree(gr, n2, depth, tp);
}

// --- key indicator -----------------------------------------------------------
vec3 keyIndicator(vec3 col, vec2 q){
    float pres = sk_attention_envelope();
    if(pres < 0.001) return col;

    // black circle growing from the center to past the corners
    float maxR = length(iResolution.xy) / iResolution.y * 0.51;
    col = mix(col, vec3(0.), S(length(q) - maxR * cubicInOut(pres)));

    // the amp zooms in with overshoot; each key bumps size and brightness
    float pulse = sk_keypulse_envelope();
    float fail = sk_fail_envelope();
    float sc = IND_AMP * sk_ease_out_back(pres) * (1. + pulse * IND_BUMP);
    if(sc < 1e-3) return col;
    vec2 ap = q / sc;
    float dj = sdJ(ap);
    float dp = max(sdP(ap), PAD - dj);
    vec3 ac = mix(ampGradient(ap), vec3(1.), pulse * IND_BRIGHT);
    ac = mix(ac, sk_fail_color, fail);
    return mix(col, ac, S(min(dj, dp) * sc));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec2 q = p;

    // global zoom-out (offset half a mode) plus the 3d wham zoom, centered
    // on a target orbiting off-screen so each zoom lands somewhere new
    float zo = flipflop(iTime + MODE_PERIOD*0.5, MODE_PERIOD);
    float ang = 6.2831853 * iTime / ZOOM_DRIFT;
    vec2 zc = ZOOM_ECC * vec2(cos(ang), sin(ang));
    p = zc + (p - zc) * (1. + ZOOM_OUT*zo) * (1. + WHAM_ZOOM*mode3d());

    // noise coords, counter-scrolling slowly against the grid
    vec2 tp = vec2(p.x, p.y + iTime*SCROLL*BG_SPEED) * NOISE_SCALE;

    fragColor = vec4(keyIndicator(render(p, tp), q), 1.0);
}

// --- Qt entry point ---
void main() {
    vec2 fragCoord = qt_TexCoord0 * iResolution.xy;
    fragCoord.y = iResolution.y - fragCoord.y;
    mainImage(fragColor, fragCoord);
    fragColor *= qt_Opacity;
}
