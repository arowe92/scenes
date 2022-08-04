vec4 iMouse = vec4(MouseXY*RENDERSIZE, MouseClick, MouseClick);

//******** Common Code Begins ********

#define R RENDERSIZE.xy
#define A(U) texture(iChannel0,(U)/R)
#define B(U) texture(iChannel1,(U)/R)
#define C(U) texture(iChannel2,(U)/R)
#define D(U) texture(iChannel3,(U)/R)


#define r 1.15
#define N 15.
#define S vec4(4,7,1,1)
#define Gaussian(i) 0.3989422804/S*exp(-.5*(i)*(i)/S/S)


vec4 Q = vec4(0.0, 0.0, 0.0, 0.0);
vec2 U = _xy;

//******** BuffA Code Begins ********

vec4 renderPassA() {
    #undef iChannel0
    #undef iChannel1
    #undef iChannel2
    #undef iChannel3

    #define iChannel0 BuffC
    #define iChannel1 BuffC
    #define iChannel2 BuffC
    #define iChannel3 BuffA

    /* if (length(_uv) < 0.2) { */
    /*     return _loadUserImage(); */
    /* } */

    if (int(FRAMECOUNT)%2<1) {
        Q = vec4(0);
        for (int x = -1; x <= 1; x++)
        for (int y = -1; y <= 1; y++)
        {
            vec2 u = vec2(x,y);
            vec4 a = A(U+u);
            vec2 w1 = clamp(U+u+a.xy-0.5*r,U - 0.5,U + 0.5),
            w2 = clamp(U+u+a.xy+0.5*r,U - 0.5,U + 0.5);
            float m = (w2.x-w1.x)*(w2.y-w1.y)/(r*r);
            Q.xyz += m*a.w*a.xyz;
            Q.w += m*a.w;
        }
        if (Q.w>0.)
        Q.xyz/=Q.w;
        if (FRAMECOUNT < 1)
        {
            Q = vec4(0,0,1,0);
            if (length(U-vec2(0.5)*R)<.3*R.y)Q.w = .3;
        }
        if (iMouse.z>0.&&length(U-iMouse.xy)<20.) Q.xw = vec2(.25,.3);
        if (U.x<1.||U.y<1.||R.x-U.x<1.||R.y-U.y<1.) Q.xy *= 0.;
    } else {
        Q = A(U);vec4 q = Q, dd = D(U);
        for (int x = -1; x<=1; x++)
        for (int y = -1; y<=1; y++)
        if (x!=0||y!=0)
        {
            vec2 u = vec2(x,y);
            vec4 a = A(U+u), b = B(U+u), d = D(U+u);
            u = (u)/dot(u,u);
            Q.xy -= q.w*0.125*(-d.w*a.w+a.w*(a.w*a.z-1.-3.*a.w))*u;
            Q.z  -= q.w*0.125*a.w*dot(u,a.xy-q.xy);
        }
        Q.xy = mix(Q.xy,D(U).xy,Q.w);
        if (Q.w < 1e-3) Q.z *= 0.;
    }


    Q.xy *= clamp((Slider2 + syn_BassHits * Slider3), 0, 1.01);
    return Q;
}


//******** BuffB Code Begins ********

vec4 renderPassB () {
    #undef iChannel0
    #undef iChannel1
    #undef iChannel2
    #undef iChannel3
    #define iChannel0 BuffA
    #define iChannel1 BuffC
    #define iChannel2 BuffC
    #define iChannel3 BuffD

    vec4 a = A(U);
    Q = mix(D(U),a,a.w);

    vec4 m = 0.25*(D(U+vec2(0,1))+D(U+vec2(1,0))+D(U-vec2(0,1))+D(U-vec2(1,0)));
    Q = mix(Q,m,vec4(0,0,1,.1));

    if (length(Q.xy)>0.0)
    Q.xy =  0.2 * normalize(Q.xy)*Q.w;
    return Q;
}


//******** BuffC Code Begins ********

vec4 renderPassC () {
    #undef iChannel0
    #undef iChannel1
    #undef iChannel2
    #undef iChannel3
    #define iChannel0 BuffA
    #define iChannel1 BuffC
    #define iChannel2 BuffC
    #define iChannel3 BuffB

    if (int(FRAMECOUNT)%2<1) {
        Q = vec4(0);
        for (int x = -1; x <= 1; x++)
        for (int y = -1; y <= 1; y++)
        {
            vec2 u = vec2(x,y);
            vec4 a = A(U+u);
            vec2 w1 = clamp(U+u+a.xy-0.5*r,U - 0.5,U + 0.5),
            w2 = clamp(U+u+a.xy+0.5*r,U - 0.5,U + 0.5);
            float m = (w2.x-w1.x)*(w2.y-w1.y)/(r*r);
            Q.xyz += m*a.w*a.xyz;
            Q.w += m*a.w;
        }
        if (Q.w>0.)
        Q.xyz/=Q.w;
        if (int(FRAMECOUNT) < 1)
        {
            Q = vec4(0,0,1,0);
            if (length(U-vec2(0.5)*R)<.3*R.y)Q.w = .3;
        }
        if (iMouse.z>0.&&length(U-iMouse.xy)<20.) Q.xw = vec2(.25,.3);
        if (U.x<1.||U.y<1.||R.x-U.x<1.||R.y-U.y<1.) Q.xy *= 0.;
    } else {
        Q = A(U);vec4 q = Q, dd = D(U);
        for (int x = -1; x<=1; x++)
        for (int y = -1; y<=1; y++)
        if (x!=0||y!=0)
        {
            vec2 u = vec2(x,y);
            vec4 a = A(U+u), b = B(U+u), d = D(U+u);
            u = (u)/dot(u,u);
            Q.xy -= q.w*0.125*(-d.w*a.w+a.w*(a.w*a.z-1.-3.*a.w))*u;
            Q.z  -= q.w*0.125*a.w*dot(u,a.xy-q.xy);
        }
        Q.xy = mix(Q.xy,D(U).xy,Q.w);
        if (Q.w < 1e-3) Q.z *= 0.;
    }

    /* Q.z += (syn_BPMSin) - 0.5) * 0.01; */

    return Q;
}


//******** BuffD Code Begins ********

vec4 renderPassD () {
    #undef iChannel0
    #undef iChannel1
    #undef iChannel2
    #undef iChannel3
    #define iChannel0 BuffC
    #define iChannel1 BuffC
    #define iChannel2 BuffC
    #define iChannel3 BuffB

    vec4 a = A(U);
    Q = mix(D(U),a,a.w);

    vec4 m = 0.25*(D(U+vec2(0,1))+D(U+vec2(1,0))+D(U-vec2(0,1))+D(U-vec2(1,0)));
    Q = mix(Q,m,vec4(0,0,1,.1));

    if (length(Q.xy)>0.)
    Q.xy = .2*normalize(Q.xy)*Q.w;
    return Q;
}


// Fork of "Fluid Reaction" by wyatt. https://shadertoy.com/view/3tfBWr
// 2020-08-03 18:33:18

// Fork of "4-Substance" by wyatt. https://shadertoy.com/view/3lffzM
// 2020-08-03 02:14:45

// Fork of "Multi-Substance" by wyatt. https://shadertoy.com/view/WtffRM
// 2020-08-01 02:57:11

vec4 renderMainImage () {
    #undef iChannel0
    #undef iChannel1
    #undef iChannel2
    #undef iChannel3
    #define iChannel0 BuffA
    #define iChannel1 BuffB
    #define iChannel2 BuffC
    #define iChannel3 BuffD

    float a = 0.2;
    float b = 1.5;
    Q = Slider1 * 10.0 *sin(A(U).wwww*(
                /* vec4(1,2,3,4) */
                0.2 + 0.2 * mix(vec4(0), _loadUserImage(), syn_Level)
            ));

    return Q;
}

vec4 renderMain() {
    if(PASSINDEX == 0){
        return renderPassA();
    } else if(PASSINDEX == 1){
        return renderPassB();
    } else if(PASSINDEX == 2){
        return renderPassC();
    } else if(PASSINDEX == 3){
        return renderPassD();
    } else if(PASSINDEX == 4){
        return renderMainImage();
    }

    return vec4(0);
}
