vec4 iMouse = vec4(MouseXY*RENDERSIZE, MouseClick, MouseClick);


			//******** Common Code Begins ********


// Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// Inigo Quilez
// https://iquilezles.org/articles/distfunctions
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
float smoothing(float d1, float d2, float k) { return clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 ); }

// rotation matrix
mat2 rot(float a) { return mat2(cos(a),-sin(a),sin(a),cos(a)); }

#define repeat(p,r) (mod(p,r)-r/2.)

			//******** BuffA Code Begins ********

#define GRID_SIZE 30.0
#define BUBBLE_R 0.1
#define SPACE_SPEED 0.1
#define BLEND 0.1

vec4 renderPassA() {
	vec4 fragColor = vec4(0.0);
	vec2 fragCoord = _xy;

    vec2 mouse = iMouse.xy / RENDERSIZE.xx;

    if(mouse == vec2(0.0, 0.0)) {
        mouse = vec2(0.5, 0.3);
    }

    vec2 uv = fragCoord / RENDERSIZE.xx * 2.0;
    vec2 bubbleSpace = fract(GRID_SIZE * (fragCoord/RENDERSIZE.xx - mouse));
    vec2 gridSpace = GRID_SIZE * fragCoord/RENDERSIZE.xx;
    gridSpace.x += SPACE_SPEED * TIME * GRID_SIZE;
    gridSpace.y += SPACE_SPEED * TIME * GRID_SIZE * 0.2;
    gridSpace = fract(gridSpace);

    float distSq = (mouse.x - uv.x) * (mouse.x - uv.x) + (mouse.y - uv.y) * (mouse.y - uv.y);
    float dist = sqrt(distSq);

    float mask = smoothstep(dist - BLEND, dist + BLEND, BUBBLE_R);


    gridSpace -= vec2(0.5);
    gridSpace = 2.0*abs(gridSpace);

    bubbleSpace -= vec2(0.5);
    bubbleSpace = 2.0*abs(bubbleSpace);

    vec2 finalSpace = mix(gridSpace, bubbleSpace, mask);


    float thickness = 0.5;
    float col = step(thickness, finalSpace.x) + step(thickness, finalSpace.y);


    fragColor = vec4(col);
	return fragColor;
 }


#define SHRINK 0.009

// While watching this video: https://www.youtube.com/watch?v=Vk5bxHetL4s (3:19) I was
// dissatisfied with the visual effect provided. The "space bubble" warped only on the
// edges, leaving the enclosed space still stationary, completely missing the point in
// my opinion.

// This visualisation makes the space near your mouse moving relative to the
// surroundings, so any matter living inside the bubble would "move" together with the
// bubble, while staying stationary relative to the space it sits in.



vec4 renderMainImage() {
	vec4 fragColor = vec4(0.0);
	vec2 fragCoord = _xy;

    vec2 uv = fragCoord / RENDERSIZE.xy;

    float col = 1.0;

    int shrink = 5;

    for(int x = -shrink; x <= shrink; x++) {
        for(int y = -shrink; y <= shrink; y++) {
            col *= texture(BuffA, (fragCoord + vec2(float(x), float(y))) / RENDERSIZE.xy).x;
        }
    }


    fragColor = vec4(col);
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
