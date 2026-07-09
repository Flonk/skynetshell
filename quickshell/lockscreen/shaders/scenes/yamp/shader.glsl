// yasuo quadtree scene, X glyphs replaced by the and& ampersand.
// Per tile, on its own clock (speed n*2*SPEED), the loop runs:
//   off (long) -> rotate (J/P counter-spin 360) -> off (short)
//   -> fill J (white wipe) -> fill P (offset wipe) -> on -> unfill -> loop
// sdJ/sdP are exact bezier SDFs; the design gap (PAD) of the J is carved
// out of the P, so the pieces stay separated even mid-spin.

// --- knobs ------------------------------------------------------------------
const float SPEED      = 0.125;  // global animation speed multiplier
const float T_OFF1     = 5.0;   // off, long (dark grey)
const float T_ROTATE   = 0.583;  // J/P fast 360 spin (3x faster)
const float T_OFF2     = 2.0;   // off, short
const float T_FILL     = 0.184;  // duration of each white fill wipe (6x faster)
const float T_FILL_LAG = 0.067; // P wipe starts this long after J wipe (6x faster)
const float T_ON       = 1.55;  // fully white hold
const float T_UNFILL   = 0.134;  // wipes reverse out (6x faster)
const float T_REST     = 0.2;   // grey tail before the loop restarts

const float AMP_SCALE  = 0.94;  // glyph size within its tile
const float BIG_CHANCE = 0.15;  // chance a cell promotes to one huge amp
const float SCROLL     = 0.1;   // background scroll speed

// derived state boundaries — don't touch, tune the knobs above
const float ROT_START    = T_OFF1;
const float FILLJ_START  = ROT_START + T_ROTATE + T_OFF2;
const float FILLP_START  = FILLJ_START + T_FILL_LAG;
const float ON_START     = FILLP_START + T_FILL;
const float UNFILL_START = ON_START + T_ON;
const float LOOP_LEN     = UNFILL_START + T_UNFILL + T_REST;

#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(iResolution.y,iResolution.x)
#define S(d) 1.-smoothstep(-1.3,1.3, (d)*iResolution.y )
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)

float random (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

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

// --- and& ampersand: exact SDF data (J = [0,NJ), P = [NJ,NSEG)) ------------
const int NJ = 41;              // segments [0,NJ) = J
const int NSEG = 76;         // segments [NJ,NSEG) = P
const float PAD = 0.0464;      // design gap, measured from the artwork
const vec2 AMP[228] = vec2[228](
vec2(0.0145,-0.2568),vec2(-0.0054,-0.2725),vec2(-0.0252,-0.2885),vec2(-0.0252,-0.2885),vec2(-0.0755,-0.3300),vec2(-0.1287,-0.3307),
vec2(-0.1287,-0.3307),vec2(-0.1819,-0.3314),vec2(-0.2145,-0.2930),vec2(-0.2145,-0.2930),vec2(-0.2470,-0.2530),vec2(-0.2433,-0.2057),
vec2(-0.2433,-0.2057),vec2(-0.2396,-0.1583),vec2(-0.1967,-0.1199),vec2(-0.1967,-0.1199),vec2(-0.1827,-0.1079),vec2(-0.1688,-0.0958),
vec2(-0.1688,-0.0958),vec2(-0.1782,-0.0836),vec2(-0.1902,-0.0675),vec2(-0.1902,-0.0675),vec2(-0.2022,-0.0514),vec2(-0.2156,-0.0326),
vec2(-0.2156,-0.0326),vec2(-0.2291,-0.0139),vec2(-0.2425,0.0061),vec2(-0.2425,0.0061),vec2(-0.2560,0.0261),vec2(-0.2682,0.0461),
vec2(-0.2682,0.0461),vec2(-0.2865,0.0305),vec2(-0.3047,0.0147),vec2(-0.3047,0.0147),vec2(-0.3491,-0.0207),vec2(-0.3794,-0.0696),
vec2(-0.3794,-0.0696),vec2(-0.4097,-0.1184),vec2(-0.4201,-0.1724),vec2(-0.4201,-0.1724),vec2(-0.4305,-0.2264),vec2(-0.4179,-0.2841),
vec2(-0.4179,-0.2841),vec2(-0.4053,-0.3418),vec2(-0.3624,-0.3965),vec2(-0.3624,-0.3965),vec2(-0.3225,-0.4498),vec2(-0.2633,-0.4734),
vec2(-0.2633,-0.4734),vec2(-0.2041,-0.4971),vec2(-0.1427,-0.4986),vec2(-0.1427,-0.4986),vec2(-0.0813,-0.5000),vec2(-0.0244,-0.4831),
vec2(-0.0244,-0.4831),vec2(0.0326,-0.4660),vec2(0.0696,-0.4394),vec2(0.0696,-0.4394),vec2(0.0946,-0.4198),vec2(0.1194,-0.4000),
vec2(0.1194,-0.4000),vec2(0.1471,-0.3765),vec2(0.1757,-0.3513),vec2(0.1757,-0.3513),vec2(0.2043,-0.3261),vec2(0.2276,-0.3054),
vec2(0.2276,-0.3054),vec2(0.2512,-0.2842),vec2(0.2648,-0.2722),vec2(0.2648,-0.2722),vec2(0.3451,-0.1976),vec2(0.4253,-0.1228),
vec2(0.4253,-0.1228),vec2(0.3677,-0.0599),vec2(0.3100,0.0029),vec2(0.3100,0.0029),vec2(0.3098,0.0028),vec2(0.3042,-0.0024),
vec2(0.3042,-0.0024),vec2(0.2987,-0.0076),vec2(0.2890,-0.0165),vec2(0.2890,-0.0165),vec2(0.2794,-0.0254),vec2(0.2671,-0.0368),
vec2(0.2671,-0.0368),vec2(0.2548,-0.0481),vec2(0.2413,-0.0605),vec2(0.2413,-0.0605),vec2(0.2279,-0.0730),vec2(0.2146,-0.0851),
vec2(0.2146,-0.0851),vec2(0.2013,-0.0973),vec2(0.1897,-0.1079),vec2(0.1897,-0.1079),vec2(0.1781,-0.1185),vec2(0.1695,-0.1262),
vec2(0.1695,-0.1262),vec2(0.1610,-0.1339),vec2(0.1569,-0.1373),vec2(0.1569,-0.1373),vec2(0.1528,-0.1407),vec2(0.1447,-0.1475),
vec2(0.1447,-0.1475),vec2(0.1366,-0.1543),vec2(0.1257,-0.1634),vec2(0.1257,-0.1634),vec2(0.1149,-0.1725),vec2(0.1026,-0.1829),
vec2(0.1026,-0.1829),vec2(0.0903,-0.1932),vec2(0.0778,-0.2037),vec2(0.0778,-0.2037),vec2(0.0653,-0.2141),vec2(0.0540,-0.2236),
vec2(0.0540,-0.2236),vec2(0.0427,-0.2331),vec2(0.0338,-0.2406),vec2(0.0338,-0.2406),vec2(0.0249,-0.2480),vec2(0.0198,-0.2524),
vec2(0.0198,-0.2524),vec2(0.0147,-0.2567),vec2(0.0145,-0.2568),vec2(-0.1235,-0.0770),vec2(-0.1090,-0.0954),vec2(-0.0901,-0.1189),
vec2(-0.0901,-0.1189),vec2(-0.0711,-0.1424),vec2(-0.0529,-0.1647),vec2(-0.0529,-0.1647),vec2(-0.0347,-0.1869),vec2(-0.0227,-0.2015),
vec2(-0.0227,-0.2015),vec2(-0.0107,-0.2160),vec2(-0.0103,-0.2166),vec2(-0.0103,-0.2166),vec2(0.0746,-0.3221),vec2(0.1596,-0.4274),
vec2(0.1596,-0.4274),vec2(0.1798,-0.4542),vec2(0.2001,-0.4809),vec2(0.2001,-0.4809),vec2(0.3153,-0.4810),vec2(0.4305,-0.4808),
vec2(0.4305,-0.4808),vec2(0.3624,-0.3949),vec2(0.2941,-0.3091),vec2(0.2941,-0.3091),vec2(0.2108,-0.2055),vec2(0.1273,-0.1020),
vec2(0.1273,-0.1020),vec2(0.0393,0.0090),vec2(-0.0488,0.1198),vec2(-0.0488,0.1198),vec2(-0.0784,0.1538),vec2(-0.0954,0.1812),
vec2(-0.0954,0.1812),vec2(-0.1124,0.2085),vec2(-0.1094,0.2456),vec2(-0.1094,0.2456),vec2(-0.1036,0.2855),vec2(-0.0783,0.3069),
vec2(-0.0783,0.3069),vec2(-0.0532,0.3283),vec2(-0.0147,0.3284),vec2(-0.0147,0.3284),vec2(0.0237,0.3284),vec2(0.0526,0.3010),
vec2(0.0526,0.3010),vec2(0.0814,0.2736),vec2(0.0977,0.2263),vec2(0.0977,0.2263),vec2(0.1761,0.2551),vec2(0.2545,0.2840),
vec2(0.2545,0.2840),vec2(0.2441,0.3284),vec2(0.2190,0.3683),vec2(0.2190,0.3683),vec2(0.1938,0.4083),vec2(0.1576,0.4371),
vec2(0.1576,0.4371),vec2(0.1213,0.4660),vec2(0.0755,0.4830),vec2(0.0755,0.4830),vec2(0.0296,0.5000),vec2(-0.0236,0.5000),
vec2(-0.0236,0.5000),vec2(-0.0769,0.5000),vec2(-0.1249,0.4822),vec2(-0.1249,0.4822),vec2(-0.1731,0.4645),vec2(-0.2100,0.4334),
vec2(-0.2100,0.4334),vec2(-0.2470,0.4023),vec2(-0.2685,0.3580),vec2(-0.2685,0.3580),vec2(-0.2899,0.3136),vec2(-0.2914,0.2603),
vec2(-0.2914,0.2603),vec2(-0.2929,0.2293),vec2(-0.2899,0.2071),vec2(-0.2899,0.2071),vec2(-0.2870,0.1849),vec2(-0.2810,0.1671),
vec2(-0.2810,0.1671),vec2(-0.2810,0.1669),vec2(-0.2775,0.1591),vec2(-0.2775,0.1591),vec2(-0.2741,0.1512),vec2(-0.2677,0.1383),
vec2(-0.2677,0.1383),vec2(-0.2613,0.1254),vec2(-0.2526,0.1099),vec2(-0.2526,0.1099),vec2(-0.2439,0.0945),vec2(-0.2333,0.0791),
vec2(-0.2333,0.0791),vec2(-0.2329,0.0785),vec2(-0.2214,0.0614),vec2(-0.2214,0.0614),vec2(-0.2099,0.0444),vec2(-0.1923,0.0189),
vec2(-0.1923,0.0189),vec2(-0.1748,-0.0066),vec2(-0.1563,-0.0325),vec2(-0.1563,-0.0325),vec2(-0.1378,-0.0585),vec2(-0.1235,-0.0770)
);
float dot2(vec2 v) { return dot(v,v); }

// unsigned distance to a quadratic bezier — iq
float udBezier(vec2 pos, vec2 qa, vec2 qb, vec2 qc)
{
    vec2 a = qb - qa, b = qa - 2.0*qb + qc, c = a*2.0, d = qa - pos;
    float kk = 1.0/dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b))/3.0;
    float kz = kk * dot(d,a);
    float p  = ky - kx*kx;
    float q  = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h  = q*q + 4.0*p*p*p;
    float res;
    if (h >= 0.0)
    {
        h = sqrt(h);
        vec2 x = (vec2(h,-h)-q)/2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp(uv.x+uv.y-kx, 0.0, 1.0);
        res = dot2(d + (c + b*t)*t);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos(q/(p*z*2.0))/3.0;
        float m = cos(v), n = sin(v)*1.732050808;
        vec2 t = clamp(vec2(m+m,-n-m)*z - kx, 0.0, 1.0);
        res = min(dot2(d+(c+b*t.x)*t.x), dot2(d+(c+b*t.y)*t.y));
    }
    return sqrt(res);
}

// exact SDF of segments [i0,i1) of AMP — one closed even-odd shape
float sdShape(vec2 p, int i0, int i1)
{
    float d = 1e9;
    bool inside = false;
    for (int i = i0; i < i1; i++)
    {
        vec2 qa = AMP[3*i], qb = AMP[3*i+1], qc = AMP[3*i+2];
        // the curve stays within 0.29 of qa (max control-point extent is
        // 0.284), so segments that can't beat d skip the exact solve
        float bound = d + 0.29;
        if (dot2(p - qa) < bound*bound)
            d = min(d, udBezier(p, qa, qb, qc));

        float ay = qa.y - 2.0*qb.y + qc.y;
        float by = qb.y - qa.y;
        float cy = qa.y - p.y;
        float ax = qa.x - 2.0*qb.x + qc.x;
        float bx = qb.x - qa.x;
        if (abs(ay) < 1e-5)
        {
            if (abs(by) > 1e-7)
            {
                float t = cy / (-2.0*by);
                if (t >= 0.0 && t < 1.0 && ax*t*t + 2.0*bx*t + qa.x > p.x) inside = !inside;
            }
        }
        else
        {
            float disc = by*by - ay*cy;
            if (disc > 0.0)
            {
                float r  = sqrt(disc) * (by >= 0.0 ? 1.0 : -1.0);
                float hh = -(by + r);
                float t1 = hh/ay;
                float t2 = cy/hh;
                if (t1 >= 0.0 && t1 < 1.0 && ax*t1*t1 + 2.0*bx*t1 + qa.x > p.x) inside = !inside;
                if (t2 >= 0.0 && t2 < 1.0 && ax*t2*t2 + 2.0*bx*t2 + qa.x > p.x) inside = !inside;
            }
        }
    }
    return inside ? -d : d;
}

float sdJ(vec2 p) { return sdShape(p, 0, NJ); }
float sdP(vec2 p) { return sdShape(p, NJ, NSEG); }

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

vec3 drawAmp(vec2 p, float n, vec3 col, vec2 prevP){
    // outside the tile circle only the ring can show through the
    // max(length(prevP)-1., ...) clip — skip both glyph SDFs entirely
    float clip = length(prevP) - 1.;
    if (clip * iResolution.y > 1.5) {
        float dring = abs(length(prevP)-0.99)-0.01;
        return mix(col, vec3(1.), S(dring));
    }

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
    dAmp = max(length(prevP)-1., dAmp);
    col = mix(col, vec3(0.3), S(dAmp));           // grey base

    // fill states: white circular wipes clipped inside each piece
    float fj = fillAnim(frame, FILLJ_START);
    float fp = fillAnim(frame, FILLP_START);
    float wj = max(dj, length(pJ-SEED_J) - (fj*(RJ+0.02)-0.02));
    float wp = max(dp, length(pP-SEED_P) - (fp*(RP+0.02)-0.02));
    float dw = min(wj, wp) * AMP_SCALE;
    dw = max(length(prevP)-1., dw);
    dw = min(dw, abs(length(prevP)-0.99)-0.01);   // tile ring stays
    col = mix(col, vec3(1.), S(dw));
    return col;
}

vec3 quadTree(vec2 p, vec3 col, float nn){
    p*=2.;
    vec2 prevP = p;

    // extra-large level: sometimes the whole cell is one huge ampersand
    if(fract(nn*57.31) < BIG_CHANCE){
        return drawAmp(p*0.5, nn+0.3, col, prevP);
    }

    if(nn<0.5){
        p.y-=iTime*SCROLL+nn;
        p*=1.2;
    } else {
        p*=1.2+pulseAnim(nn)*0.5;
    }

    vec2 id = floor(p);
    vec2 gr = (p-id)-0.5;

    float n = random(id)*nn;
    float n2 = n;
    vec2 cell = id;

    // three subdivision levels (third one adds the extra-small amps)
    float thresholds[3] = float[](0.3+nn, 0.8+nn, 0.9+nn*0.5);

    for (int i = 0; i < 3; i++)
    {
        n = random(cell + id + float(i) * 12.34+nn);

        if (n < thresholds[i])
            break;

        gr *= 2.0;
        cell = floor(gr);
        gr = fract(gr) - 0.5;
    }

    col = drawAmp(gr, n2+nn, col, prevP);

    return col;
}

vec3 render(vec2 p, vec3 col){
    p.y-=iTime*SCROLL;
    p*=2.;
    vec2 id = floor(p);
    vec2 gr = (p-id)-0.5;

    float n = random(id);
    float n2 = n;
    vec2 cell = id;

    float thresholds[2] = float[](0.6, 0.8);

    for (int i = 0; i < 2; i++)
    {
        n = random(cell + id + float(i) * 12.34);

        if (n < thresholds[i])
            break;

        if(i<2){
            gr *= 2.0;
            cell = floor(gr);
            gr = fract(gr) - 0.5;
        }
    }

    col = quadTree(gr,col,n2);
    float d = abs(B(gr,vec2(0.47)))-0.007;
    d = max(-(abs(gr.x)-0.4),d);
    d = max(-(abs(gr.y)-0.4),d);
    col = mix(col,vec3(1.),S(d));

    gr = abs(gr)-0.42;
    d = length(gr)-0.01;
    col = mix(col,vec3(1.),S(d));
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (fragCoord-0.5*iResolution.xy)/iResolution.y;

    vec3 col = vec3(0.);

    col = render(p,col);

    fragColor = vec4(col,1.0);
}
