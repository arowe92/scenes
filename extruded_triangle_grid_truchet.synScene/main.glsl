

/*

    Extruded Triangle Grid Truchet
    ------------------------------

    I've been making a few technical shaders lately, so wanted to take a
    break and code something simple.

    This is an extruded 2D simplex Truchet variation comprising three basic
    tile configurations. It's not a common pattern, but some may have seen
    it before. The 2D field is not difficult to construct: Simply render a
    mixture of arcs or circles between triangle cell midpoints, then extrude
    the result. Raymarching objects like this in a front-on fashion doesn't
    present any challenges either.

    I used an old extruded pattern template, then updated the colors and
    lighting a bit. This was not a difficult shader to make. I was originally
    going to give it a metallic look, but I might save that for one of the
    more interesting variations I'm working on.


    References:

    // A two tiled variation using the same extrusion template.
	Extruded Octagon Diamond Truchet - Shane
    https://www.shadertoy.com/view/3tGBWV

    // BigWIngs's popular Youtube channel. It's always informative seeing how
    // others approach various graphics topics.
    Shader Coding: Truchet Tiling Explained! -  The Art of Code
	https://www.youtube.com/watch?v=2R7h76GoIJM


*/


// Maximum ray distance.
#define FAR 10.

// Subtle textured lines.
/* #define LINES */

// Double arcs.
//#define DOUBLE_ARC

// Curve shape - Round: 0, Straight: 1.
#define SHAPE 0



// Object ID: Either the back plane, extruded object or beacons.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }



// Distance metrics.
float dist(vec2 p){

    // Circular or hexagonal bounds.
    #if SHAPE == 0
    return length(p);
    #else
    // Not a proper distance field, but it'll get the job done.
    p = abs(p);
    return max(p.y*.8660254 + p.x*.5, p.x);
    #endif

}

/*
// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}
*/


////////
// A 2D triangle partitioning. I've dropped in an old routine here.
// It works fine, but could do with some fine tuning. By the way, this
// will partition all repeat grid triangles, not just equilateral ones.

// Skewing coordinates. "s" contains the X and Y skew factors.
vec2 skewXY(vec2 p, vec2 s){ return mat2(1, -s.yx, 1)*p; }

// Unskewing coordinates. "s" contains the X and Y skew factors.
vec2 unskewXY(vec2 p, vec2 s){ return inverse(mat2(1, -s.yx, 1))*p; }

// Triangle scale: Smaller numbers mean smaller triangles, oddly enough. :)
float scale = 1./1.5;

float gTri;

vec4 getTriVerts(in vec2 p, inout vec2[3] v){

    // Rectangle scale.
    vec2 rect = (vec2(1./.8660254, 1))*scale;
    // Skewing half way along X, and not skewing in the Y direction.
    vec2 sk = vec2(rect.x*.5, 0)/scale; // 12 x .2

    // Skew the XY plane coordinates.
    p = skewXY(p, sk);

    // Unique position-based ID for each cell. Technically, to get the central position
    // back, you'd need to multiply this by the "rect" variable, but it's kept this way
    // to keep the calculations easier. It's worth putting some simple numbers into the
    // "rect" variable to convince yourself that the following makes sense.
	vec2 id = floor(p/rect) + .5;
    // Local grid cell coordinates -- Range: [-rect/2., rect/2.].
	p -= id*rect;


    // Equivalent to:
    //gTri = p.x/rect.x < -p.y/rect.y? 1. : -1.;
    // Base on the bottom (-1.) or upside down (1.);
    gTri = dot(p, 1./rect)<0.? 1. : -1.;

    // Puting the skewed coordinates back into unskewed form.
    p = unskewXY(p, sk);

    // Vertex IDs for the quad.
    vec2[3] vID;

    // Vertex IDs for each partitioned triangle.
    if(gTri<0.){
        vID = vec2[3](vec2(-.5, .5), vec2(.5, -.5), vec2(.5));
    }
    else {
        vID = vec2[3](vec2(.5, -.5), vec2(-.5, .5), vec2(-.5));
    }

    // Specific triangle ID.
    id += vID[2]/3.; //id += (vID[0] + vID[1] + vID[2])/3.;

    // Triangle vertex points.
    for(int i = 0; i<3; i++) v[i] = unskewXY(vID[i]*rect, sk); // Unskew.

    // Centering at the zero point.
    vec2 ctr = v[2]/3.; //Equivalent to: (v[0] + v[1] + v[2])/3.;
    p -= ctr;
    v[0] -= ctr;
    v[1] -= ctr;
    v[2] -= ctr;

    // Triangle local coordinates (centered at the zero point) and
    // the central position point (which acts as a unique identifier).
    return vec4(p, id);
}

// A standard square grid 2D blobby Truchet routine: Render circles
// in opposite corners of a tile, reverse the pattern on alternate
// checker tiles, and randomly rotate.
vec3 tr(vec2 p){


        // Cell coordinate, ID and triangle orientation id.
    // Cell vertices.
    vec2[3] v;

    // Returns the local coordinates (centered on zero), cellID, the
    // triangle vertex ID and relative coordinates.
    vec4 p4 = getTriVerts(p, v);
    p = p4.xy;
    vec2 triID = p4.zw;// + (vID[0] + vID[1] + vID[2])/3.;



    // Grid triangles. Some are upside down.
    vec2 q = p*vec2(1, gTri); // Equivalent to the line above.
    float tr = max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3.;


    // Nearest vertex ID.
    float vert = 1e5;
    vec3 midD;
    float sL = length(v[0] - v[1]);

    // Random value based on the overall triangle ID.
    float rnd = hash21(triID + .11);
    float rnd2 = hash21(triID + .22);

    // Random rotation, in incrents of 120 degrees to maintain symmetry.
    p = rot2(floor(rnd*36.)*6.2831/3.)*p;

    // Nearest vertex, vertex-arc and angle (subtended from each vertex) calculations.
    vec2 vertID;
    for(int i = 0; i<3; i++){

        //vertD[i] = length(p - v[i]);
        vert = min(vert, dist(p - v[i]));

        vec2 vM = mix(v[i], v[(i + 1)%3], .5);
        midD[i] = dist(p - vM);

    }

    float pTh = sL/6.; // Arc thickness.
    // Turning the circle distance into an arc.
    float arc = abs(dist(p - v[0]) - sL/2.) - pTh;

    // Edge midpoint vertices.
    float mid = min(min(midD.x, midD.y), midD.z);

    float tile;

    // Triangle Truchet tiles.
    if(rnd2<.4){

        // Tri-pronged tile.
        //tile = min(min(arc.x, arc.y), arc.z);
        tile = -(vert - (sL/2. - pTh));
    }
    else if(rnd2<.7){

        // Arc and circle tile.
        tile = min(arc, midD.y - pTh);
    }
    else {

         // Midpoint circle tiles.
         tile = mid - pTh;
    }

    /* #ifdef DOUBLE_ARC */
    tile = mix(tile, abs(tile + pTh/2.25) - pTh/1.2, Slider1 * syn_BPMSin2); // Doubling the arcs.
    /* #endif */


    return vec3(tile, mid, tr);


}

// The scene's distance function: There'd be faster ways to do this, but it's
// more readable this way. Plus, this  is a pretty simple scene, so it's
// efficient enough.
float m(vec3 p){



    // 2D Truchet distance -- for the extrusion cross section.
    vec3 tr3 = tr(p.xy);
    float obj = tr3.x;

    // Back plane with a slight triangle cell bevel.
    float fl = -p.z - min(-tr3.z*4., .2)*.05;
    //fl -= min(-tr3.z*2., .25)*.15;
    //fl -= smoothstep(0., .07, -tr3.z)*.03;//smoothstep(.08, .15, obj)*.1;
    //fl += tr3.z*.3;

    // Extrude the 2D Truchet object along the Z-plane. Note that this is a cheap
    // hack. However, in this case, it doesn't make much of a visual difference.
    obj = max(obj, abs(p.z) - .125) - smoothstep(.05, .11, -obj)*.04;
    // Proper extrusion formula for comparisson.
    //obj = opExtrusion(obj, p.z, .125, .01) - smoothstep(.03, .25, -obj)*.1;


    // Object ID.
    objID = fl<obj? 0 : 1 ;

    // Minimum distance for the scene.
    return min(fl, obj);

}

// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float d, t = 0.; //hash21(r.xy*57. + fract(TIME + r.z))*.5;

    for(int i = min(int(FRAMECOUNT), 0); i<80; i++){

        d = m(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001 || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.

        t += d*.7;
    }

    return min(t, FAR);
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not affordable for slower machines.
    const int iter = 24;

    ro += n*.0015; // Bumping the shadow off the hit point.

    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.;
    float end = max(length(rd), 0.0001);
    rd /= end;

    //rd = normalize(rd + (hash33R(ro + n) - .5)*.03);


    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest
    // number to give a decent shadow is the best one to choose.
    for (int i = min(int(FRAMECOUNT), 0); i<iter; i++){

        float d = m(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // IQ's subtle refinement.
        t += clamp(d, .01, .2);


        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break;
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add
    // AO also just for kicks. :)
    return max(shade, 0.);
}


// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(int(FRAMECOUNT), 0); i<5; i++ ){

        float hr = float(i + 1)*.15/5.;
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;

        // Deliberately redundant line that may or may not stop the
        // compiler from unrolling.
        if(sca>1e5) break;
    }

    return clamp(1. - occ, 0., 1.);
}

// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 nr(in vec3 p) {

    const vec2 e = vec2(.001, 0);

    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),
    //                      m(p + e.yyx) - m(p - e.yyx)));

    // This mess is an attempt to speed up compiler time by contriving a break... It's
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(int(FRAMECOUNT), 0); i<6; i++){
		mp[i] = m(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }

    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}


vec4 renderMainImage() {
	vec4 c = vec4(0.0);
	vec2 u = _xy;



    // Aspect correct coordinates. Only one line necessary.
    u = (u - RENDERSIZE.xy*.5)/RENDERSIZE.y;
    u /= 5;

    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(Camera * TIME / 2.0, -3 * Slider3), l = o + vec3(.25, .25, 2);

    // Rotating the camera about the XY plane.
    r.yz = rot2(Slider2)*r.yz;
    /* r.xz = rot2(-cos(TIME*3.14159/32.)/8.)*r.xz; */
    /* r.xy = rot2(sin(TIME*3.14159/32.)/8.)*r.xy; */


    // Raymarch to the scene.
    float t = trace(o, r);


    // Object ID: Back plane (0), or the metaballs (1).
    int gObjID = objID;


    // Very basic lighting.
    // Hit point and normal.
    vec3 p = o + r*t, n = nr(p);


    // UV texture coordinate holder.
    vec2 uv = p.xy;




    // Returns the local coordinates (centered on zero), cellID, the
    // triangle vertex ID and relative coordinates.
    vec2[3] v;
    //scale /= 3.;
    vec4 p4 = getTriVerts(p.xy, v);
    vec2 triID = p4.zw;// + (vID[0] + vID[1] + vID[2])/3.;
    float svGTri = gTri;
    // Grid triangles. Some are upside down.
    vec2 q = p4.xy*vec2(1, gTri);
    float tri = max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3.;
    q = (p4.xy - normalize(p.xy/(p.z - 3.) - l.xy/(l.z - 3.))*.005)*vec2(1, gTri);
    float tri2 = max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3.;
    float b = max(tri2 - tri, 0.)/.005;


    // 2D Truchet face distace -- Used to render borders, etc.
    //scale *= 3.;
    vec3 tr3 = tr(p.xy);
    float d = tr3.x;
    p4 = getTriVerts(p.xy, v);
    q = p4.xy*vec2(1, gTri);
    float triB = tr3.z; //max(abs(q.x)*.8660254 + q.y*.5, -q.y) - scale/3.;

    // Smooth borders.
    float bord = abs(triB) - .003;



    // Subtle pattern lines for a bit of texture.
    #ifdef LINES
    float lSc = 20.;
    float pat = (abs(fract((uv.x - uv.y)*lSc - .5) - .5) - .125)/lSc;
    float pat2 = (abs(fract((uv.x + uv.y)*lSc + .5) - .5) - .125)/lSc;
    #else
    float pat = 1e5, pat2 = 1e5;
    #endif


    vec4 col1 = vec4(1, .15, .4, 0);
    vec4 col2 = vec4(.4, .7, 1, 0);

    /*
    // Extra color. Interesting, but it makes things look creepily anatomical. :)
    vec2 fID = floor(triID + .5);
    if(mod(fID.x, 2.)<.5) col1 *= vec4(1, 2.35, 1.5, 0);
    if(mod(fID.y, 2.)<.5) col1 *= vec4(2, 1.5, 1, 0);
    if(mod(fID.x, 2.)<.5) col2 *= vec4(1, 1.15, .9, 0).zxyw;
    if(mod(fID.y, 2.)<.5) col2 *= vec4(1.15, 1, .9, 0).zxyw;
    */

    // Object color.
    vec4 oCol;


    // Use whatever logic to color the individual scene components. I made it
    // all up as I went along, but things like edges, textured line patterns,
    // etc, seem to look OK.
    //
    if(gObjID == 0){

       // The blue floor:
       col2 = mix(col2, vec4(0), (1. - smoothstep(0., .01, pat2))*.35);
       // Blue with some subtle lines.
       oCol = col2;//mix(col2, vec4(1), .25);//mix(col2/1.2, vec4(0), (1. - smoothstep(0., .01, pat2))*.35);
       // Triangle borders: Omit the middle of edges where the Truchet passes through.
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);
       //oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, abs(bord - .06) - .005))*.8);
       //oCol = mix(oCol, col2/1.15, (1. - smoothstep(0., .01, tri + .07)));

       // Darken alternate triangles.
       if(gTri<.0) oCol *= .8;

       // Using the Truchet pattern for some bottom edging.
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, d - .015))*.8);


    }
    else {

        // Extruded Truchet:

        // White sides with a dark edge.
        oCol = mix(vec4(.9), vec4(0), 1. - smoothstep(0., .01, d + .05));
        //df = mix(pow(df, 4.), df, 1. - smoothstep(0., .01, d + .05));


        // Golden faces with some subtle lines.
        vec4 fCol = mix(col1, vec4(0), (1. - smoothstep(0., .01, pat))*.35);

        // Darken alternate checkers on the face only.
        if(svGTri>0.) fCol *= .8;

        // Triangle borders: Omit the middle of edges where the Truchet passes through.
        bord = abs(tri) - .003;
        fCol = mix(fCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);


        // Apply the colored face to the Truchet, but leave enough room
        // for an edge.
        oCol = mix(oCol, fCol, 1. - smoothstep(0., .01, d + .08));


    }


    // Basic point lighting.
    vec3 ld = l - p;
    float lDist = length(ld);
    ld /= lDist; // Light direction vector.
    float at = 1./(1. + lDist*lDist*.125); // Attenuation.

    // Very, very cheap shadows -- Not used here.
    //float sh = min(min(m(p + ld*.08), m(p + ld*.16)), min(m(p + ld*.24), m(p + ld*.32)))/.08*1.5;
    //sh = clamp(sh, 0., 1.);
    float sh = softShadow(p, l, n, 8.); // Shadows.
    float ao = calcAO(p, n); // Ambient occlusion.


    float df = max(dot(n, ld), 0.); // Diffuse.
    float sp = pow(max(dot(reflect(r, n), ld), 0.), 32.); // Specular.

    // Specular reflection.
    vec3 hv = normalize(-r + ld); // Half vector.
    vec3 ref = reflect(r, n); // Surface reflection.
    vec4 refTx = texture(syn_UserImage, ref.xy); refTx *= refTx; // Cube map.
    float spRef = pow(max(dot(hv, n), 0.), 8.); // Specular reflection.
    float rf = (gObjID == 0)? .1 : 1.;//mix(.5, 1., 1. - smoothstep(0., .01, d + .08));
    oCol += spRef*refTx*rf; //smoothstep(.03, 1., spRef)


    // Apply the lighting and shading.
    c = oCol*(df*sh + sp*sh + .5)*at*ao;



    // Rough gamma correction.
    c = sqrt(max(c, 0.));

	return c;
 }


vec4 renderMain(){
	if(PASSINDEX == 0){
		return renderMainImage();
	}
}
