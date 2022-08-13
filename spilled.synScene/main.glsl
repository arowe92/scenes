vec4 iMouse = vec4(MouseXY*RENDERSIZE, MouseClick, MouseClick);


			//******** BuffA Code Begins ********

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// single pass CFD
// ---------------
// this is some "computational flockarooid dynamics" ;)
// the self-advection is done purely rotational on all scales.
// therefore i dont need any divergence-free velocity field.
// with stochastic sampling i get the proper "mean values" of rotations
// over time for higher order scales.
//
// try changing "SPIN" for different accuracies of rotation calculation
// for even SPIN uncomment the line #define SUPPORT_EVEN_ROTNUM

#define SPIN SPIN
//#define SUPPORT_EVEN_ROTNUM

#define Res RENDERSIZE.xy
#define Res1 RENDERSIZE.xy

#define keyTex _loadUserImage();
#define KEY_I texture(image5,vec2((105.5-32.0)/256.0,(0.5+0.0)/3.0)).x

float SPIN = syn_BassHits * 5 + SLIDER5;
float ang = 2.0*3.1415926535/float(SPIN);
mat2 m = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
mat2 mh = mat2(cos(ang*0.5),sin(ang*0.5),-sin(ang*0.5),cos(ang*0.5));
vec4 img = _loadUserImage();

vec4 randS(vec2 uv)
{
    return texture(image5,uv*Res.xy/Res1.xy)-vec4(0.5);
}

float getRot(vec2 pos, vec2 b)
{
    vec2 p = b;
    float rot=0.0;
    for(int i=0;i<SPIN;i++)
    {
        vec2 coord = fract((pos+p)/Res.xy);
        rot+=dot(texture(BuffA, coord).xy-vec2(0.5),p.yx*vec2(1,-1));
        p = m*p;
    }
    return rot/floor(SPIN)/dot(b,b);
}

vec4 renderPassA() {
	vec4 fragColor = vec4(0.0);
	vec2 fragCoord = _xy;

    vec2 pos = fragCoord.xy;
    float rnd = randS(vec2(float(FRAMECOUNT)/Res.x,0.5/Res1.y)).x;

    vec2 b = vec2(cos(ang*rnd),sin(ang*rnd));
    vec2 v=vec2(0);
    float bbMax=(1.0 + SLIDER4) * 0.7 *Res.y; bbMax*=bbMax;
    for(int l=0;l<20;l++)
    {
        if ( dot(b,b) > bbMax ) break;
        vec2 p = b;
        for(int i=0;i < SPIN; i++)
        {
            /* if (i == floor(SPIN) - 1 && _rand(vec2(l, i + TIME * 1000)) < mod(SPIN, 1)) { */
            if (i == floor(SPIN) - 1 && _rand(vec2(l, i + TIME * 1000)) < mod(SPIN, 1)) {
                /* break; */
            }
#ifdef SUPPORT_EVEN_ROTNUM
            v+=p.yx*getRot(pos+p,-mh*b);
#else
            // this is faster but works only for odd SPIN
            v+=p.yx*getRot(pos+p,b) * (1 + SLIDER6 * syn_Hits);
#endif
            p = m*p;
        }
        b*=2.0;
    }

    fragColor=texture(BuffA,fract((pos+v*vec2(-1,1)*2.0)/Res.xy));

    // add a little "motor" in the center
    vec2 scr=(fragCoord.xy/Res.xy)*2.0-vec2(1.0);
    fragColor.xy += (0.01*scr.xy / (dot(scr,scr)/0.1+0.3));

    /* if (length(_uvc.xy) < 0.2) { */
    fragColor.xyz = mix(fragColor.xyz,
            img.xyz,
            fragColor.w
            );
            /* max(max(img.z, img.y), img.z)); */
    /* } */


    if (_uv.x < 0.015 || _uv.y < 0.05 ||1 - _uv.x <0.015 || 1 - _uv.y < 0.05) {
        fragColor.xyzw *= 0.9;
    }

    vec3 hsv = _rgb2hsv(fragColor.xyz);
    fragColor.w = mix(fragColor.w,
        syn_BassHits,
     pow(10, SLIDER1 * -2));
    fragColor.w *= SLIDER2 * SLIDER2;

    if(FRAMECOUNT<=4 || RESET == 1) {
        fragColor=_loadUserImage();
        fragColor.w = 0.0;
    }
	return fragColor;
 }



// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// single pass CFD
// ---------------
// this is some "computational flockarooid dynamics" ;)
// the self-advection is done purely rotational on all scales.
// therefore i dont need any divergence-free velocity field.
// with stochastic sampling i get the proper "mean values" of rotations
// over time for higher order scales.
//
// try changing "SPIN" for different accuracies of rotation calculation
// for even SPIN uncomment the line #define SUPPORT_EVEN_ROTNUM

float getVal(vec2 uv)
{
    return length(texture(BuffA,uv).xyz);
}

vec2 getGrad(vec2 uv,float delta)
{
    vec2 d=vec2(delta,0);
    return vec2(
        getVal(uv+d.xy)-getVal(uv-d.xy),
        getVal(uv+d.yx)-getVal(uv-d.yx)
    )/delta;
}

vec4 renderMainImage() {
	vec4 fragColor = vec4(0.0);
	vec2 fragCoord = _xy;

	vec2 uv = fragCoord.xy / RENDERSIZE.xy;
    vec3 n = vec3(getGrad(uv,1.0/RENDERSIZE.y),150.0);
    //n *= n;
    n=normalize(n);
    fragColor=vec4(n,1);
    vec3 light = normalize(vec3(1,1,2));
    float diff=clamp(dot(n,light),0.5,1.0);
    float spec=clamp(dot(reflect(light,n),vec3(0,0,-1)),0.0,1.0);
    spec = pow(spec,36.0)*2.5;
    //spec=0.0;
	fragColor = texture(BuffA,uv);
    vec3 c = fragColor.xyz;
	float w = fragColor.w;

    /* if ( fragColor.w. < 0.5) { */
    /*     /1* return vec4(1, 0, 0, 0); *1/ */
    /* } */
    /* if (_uv.x < hsv.r) { */
    /* fragColor.rgb = mix(fragColor.rgb, rgb, dot(c, c) / 3); */
    /* } */

    vec3 hsv = _rgb2hsv(fragColor.xyz);
    vec3 rgb = _hsv2rgb(vec3(hsv.x, 1.0, 1.0));
    fragColor.xyz = mix(fragColor.xyz, rgb, spec * SLIDER3);

    /* fragColor = mix(fragColor, fragColor*diff+spec, spec); */
    /* fragColor = mix(fragColor, fragColor, spec); */
    /* fragColor.x = 0; */
    fragColor = fragColor * diff;
    /* fragColor.z = 0; */
	return fragColor;
 }


vec4 renderMain(){
	if(PASSINDEX == 0){
		return renderPassA();
	}
	if(PASSINDEX == 1){
		return renderMainImage();
	}
}

// TODO
// Fluid Spawn Rate
// Rotation Bias
