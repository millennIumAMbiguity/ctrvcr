#include "/shader.h"
#include "/common/hash.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform float frameTimeCounter;
//uniform int blockEntityId;
uniform float viewWidth;
uniform float viewHeight;
varying vec2 texcoord_vs;

// Dont remove this two lines, they are needed for the shader reconise BNW_PRE_TINT as a config
#ifdef BNW_PRE_TINT
#endif

void main() {

	float time = mod(frameTimeCounter, 8192);
	float time8 = mod(frameTimeCounter * 7.987, 8192);

#if DISTRORTION_FACTOR == -1
	vec2 texcoord = texcoord_vs;
#else
	vec2 dir = texcoord_vs - vec2(0.5, 0.5);  // Direction from the center
	float dist = length(dir);                  // Distance from the center
	float distortion = 1.0 + DISTRORTION_FACTOR_F * dist * dist;  // Apply non-linear distortion
	vec2 texcoord = vec2(0.5, 0.5) + dir * distortion * (1-(DISTRORTION_FACTOR_F/3));  // Modify the UV coordinates
#endif

// Resolutino scaling
#if RENDER_PIXEL_SIZE > 1
	vec2 texcoordScaled = texcoord - vec2(mod(texcoord.x, RENDER_PIXEL_SIZE/viewWidth), mod(texcoord.y, RENDER_PIXEL_SIZE/viewHeight));

	#if FX_PIXEL_SIZE == RENDER_PIXEL_SIZE
		texcoord = texcoordScaled;
	#elif FX_PIXEL_SIZE > 1
		texcoord = texcoord - vec2(mod(texcoord.x, FX_PIXEL_SIZE/viewWidth), mod(texcoord.y, FX_PIXEL_SIZE/viewHeight));
	#endif
#else
	vec2 texcoordScaled = texcoord;

	#if FX_PIXEL_SIZE > 1
		texcoord = texcoord - vec2(mod(texcoord.x, FX_PIXEL_SIZE/viewWidth), mod(texcoord.y, FX_PIXEL_SIZE/viewHeight));
	#endif
#endif

	float uvy = texcoordScaled.y;
	float uvx = texcoordScaled.x;

	float v = hash(texcoord_vs, time8);
	float v2 = hash(texcoord_vs, time8 + 456.789);


	float vRow = Random_float(vec2(time, int(uvy)));

	// Screen Tear
#if SCREEN_TEAR_SIZE != -1
	#if SCREEN_TEAR_SPEED != -1
		float y1 = mod(SCREEN_TEAR_SPEED_F * time + SCREEN_TEAR_SIZE_F, SCREEN_TEAR_DELAY_F + SCREEN_TEAR_SIZE_F);
		float y2 = uvy-y1;
		if (y2 < 0.0f && y2 > -SCREEN_TEAR_SIZE_F) {
			texcoord.y = uvy = fract(y1);
			#ifdef SCREEN_TEAR_SOLID
			texcoordScaled.y = uvy;
			#endif
		}
	#else
		float offset = SCREEN_TEAR_DELAY_F * 0.001;

		if (uvy < SCREEN_TEAR_SIZE_F + offset && uvy > offset) {
			texcoord.y = uvy = fract(offset);
			#ifdef SCREEN_TEAR_SOLID
			texcoordScaled.y = uvy;
			#endif
		}
	#endif
#endif

	vec3 sum = vec3(0);

	// Bloom
#if BLOOM_SIZE != -1 || defined PORTAL_STATIC_IRIS
	#if BLOOM_SIZE != -1
		vec3 color = texture2D(colortex0, texcoordScaled).rgb;
		vec3 bloom;
	#endif

	#ifdef PORTAL_STATIC_IRIS
		float staticSum = 0;
	#endif

		for(int i= -3 ;i < 3; i++)
		{
			float i3 = i * 3;
			float v3 = (0.5 - Random_float(texcoordScaled + vec2(1.0 + i3, 0) + time)) + i;
			float v4 = (0.5 - Random_float(texcoordScaled + vec2(2.0 + i3, 0) + (time + 100.2)));
			float v5 = (0.5 - Random_float(texcoordScaled + vec2(3.0 + i3, 0) + (time + 200.5)));
			float v6 = (0.5 - Random_float(texcoordScaled + vec2(4.0 + i3, 0) + (time + 300.8)));

			vec2 cordA = texcoordScaled + vec2(-1 + v4, v3)*0.004;
			vec2 cordB = texcoordScaled + vec2( v5, v3)*0.004;
			vec2 cordC = texcoordScaled + vec2( 1 + v6, v3)*0.004;

	#if BLOOM_SIZE != -1
			sum += texture2D(colortex0, cordA).xyz * BLOOM_SIZE_F;
			sum += texture2D(colortex0, cordB).xyz * BLOOM_SIZE_F;
			sum += texture2D(colortex0, cordC).xyz * BLOOM_SIZE_F;
	#endif

	#ifdef PORTAL_STATIC_IRIS
			staticSum += texture2D(colortex7, cordA).b;
			staticSum += texture2D(colortex7, cordB).b;
			staticSum += texture2D(colortex7, cordC).b;
	#endif
		}

	#ifdef PORTAL_STATIC_IRIS
		staticSum = min(staticSum / 6.0, 1.0);
	#endif

	#if BLOOM_SIZE != -1

		if (color.r < 0.3 && color.g < 0.3 && color.b < 0.3)
		{
			bloom = sum.xyz*sum.xyz*0.012 + color;
		}
		else
		{
			if (color.r < 0.5 && color.g < 0.5 && color.b < 0.5)
			{
				bloom = sum.xyz*sum.xyz*0.009 + color;
			}
			else
			{
				bloom = sum.xyz*sum.xyz*0.0075 + color;
			}
		}
		
		bloom = mix(color, bloom, BLOOM_SIZE_F);

		
		float sumSingle = (bloom.r + bloom.g + bloom.b) / 3.0;
		float tanSum = tan(min(sumSingle * 1.5, 1.57079632679))/ 64;
		float _BLUR_SIZE = clamp(BLUR_SIZE_F * tanSum, BLUR_SIZE_F , 0.01);
	#else
		float _BLUR_SIZE = BLUR_SIZE_F ;
	#endif
#else
	float _BLUR_SIZE = BLUR_SIZE_F ;
#endif

	// blur and aberration
	float v2Scaled = v2 * _BLUR_SIZE;
	float vScaled = v * _BLUR_SIZE;
	float vHalf = vScaled / 2;
#if BLUR_SIZE != -1
	float BLUR_SIZE2 = _BLUR_SIZE / 4;

	vec3 left1 = texture2D(colortex0, vec2(uvx - vScaled, uvy + vScaled / 3.0)).rgb;
	vec3 left2 = texture2D(colortex0, vec2(uvx - vHalf + (left1.r * BLUR_SIZE2), uvy + vScaled / 6.0 + (left1.g * BLUR_SIZE2))).rgb;
	vec3 center = texture2D(colortex0, vec2(uvx - vHalf / 2.0 + v2Scaled / 4.0, uvy - vHalf / 4.0 + v2Scaled / 8.0)).rgb;
	vec3 right1 = texture2D(colortex0, vec2(uvx + vScaled, uvy + vScaled)).rgb;
	float right2Offset = vHalf - (right1.r * BLUR_SIZE2);
	vec3 right2 = texture2D(colortex0, vec2(uvx + right2Offset, uvy + right2Offset)).rgb;
# else
	vec3 center = texture2D(colortex0, vec2(uvx, uvy)).rgb;
#endif

#if BLOOM_SIZE != -1
	center = center / 2.0 + bloom / 2.0;
#endif

	sum = vec3(
#if BLUR_SIZE != -1
		(left1[0] + left2[0] + center[0])/3,
		center[1] * (1. - (BLOOM_SIZE_F / 4.)),
		(right1[2] + right2[2] + center[2])/3);
#else
		center[0],
		center[1],
		center[2]);
#endif

#if defined(BNW_PRE_TINT) && BNW != -1
	float bnw = (sum[0] + sum[1] + sum[2]) / 3;
	sum = mix(sum, vec3(bnw), BNW_F);
#endif

	sum[0] *= TINT_RED_F;
	sum[1] *= TINT_GREEN_F;
	sum[2] *= TINT_BLUE_F;

#if GRAIN_INTENSITY != -1
	sum += sum * (0.5f-v) * GRAIN_INTENSITY_F;
#endif

#if !defined(BNW_PRE_TINT) && BNW != -1
	float bnw = (sum[0] + sum[1] + sum[2]) / 3;
	sum = mix(sum, vec3(bnw), BNW_F);
#endif

	// STATIC and tearing
#ifdef PORTAL_STATIC_IRIS
	float _static = max(STATIC_F + staticSum, STATIC_F);
#else
	float _static = STATIC_F;
#endif

#if STATIC_TEAR_CHANCE != -1
	float l = abs(vRow - texcoord.y)*STATIC_TEAR_CHANCE_F;
	if (l < 0.004f*v) _static = 1-min(l,0.05f*v)*50/v;
#endif

	if (v < _static)
	{
		float sv = (_static+.5)*v2;
		sum = (sum + vec3(sv)) * (1-_static) + vec3(v * _static);
	}

#if DARK_EDGES >= 0
	// Edges
	float a = texcoord_vs.x*100-DARK_EDGES;
	// Left edge
	sum *= min(a*3 + v*0.2, 2.0f) - min(a*a + v2*0.2, 1.0f);
	a = (1-texcoord_vs.x)*150- int(DARK_EDGES * 1.5);
	// Right edge
	sum *= min(a + v2*0.2, 1.0f);
#endif

	gl_FragData[0] = vec4(sum, 1.0);
}
