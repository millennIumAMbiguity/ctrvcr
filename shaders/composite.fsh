#version 130
#include "settings.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform float frameTimeCounter;
uniform int blockEntityId;
uniform float viewWidth;
uniform float viewHeight;
varying vec2 texcoord_vs;

out vec4 fragColor;


float Random_float(vec2 Seed)
{
	return fract(sin(dot(Seed,vec2(12.9898,78.233)))*43758.5453123);
}

float xmy(vec4 v) { return v.x-v.y; }

void main() {

	float time = frameTimeCounter;
	float timeM60 = mod(time, 60.0);
	float timeM200 = mod(time, 200.0);

#if DistortionFactor < 0
	vec2 texcoord = texcoord_vs;
#else
	vec2 dir = texcoord_vs - vec2(0.5, 0.5);  // Direction from the center
	float dist = length(dir);                  // Distance from the center
	float distortion = 1.0 + DistortionFactor * dist * dist;  // Apply non-linear distortion
	vec2 texcoord = vec2(0.5, 0.5) + dir * distortion * (1-(DistortionFactor/3));  // Modify the UV coordinates
#endif

// Resolutino scaling
#if RenderPixelSize > 1
	vec2 texcoordScaled = texcoord - vec2(mod(texcoord.x, RenderPixelSize/viewWidth), mod(texcoord.y, RenderPixelSize/viewHeight));

	#if FXPixelSize == RenderPixelSize
		texcoord = texcoordScaled;
	#elif FXPixelSize > 1
		texcoord = texcoord - vec2(mod(texcoord.x, FXPixelSize/viewWidth), mod(texcoord.y, FXPixelSize/viewHeight));
	#endif
#else
	vec2 texcoordScaled = texcoord;

	#if FXPixelSize > 1
		texcoord = texcoord - vec2(mod(texcoord.x, FXPixelSize/viewWidth), mod(texcoord.y, FXPixelSize/viewHeight));
	#endif
#endif

	float uvy = texcoordScaled.y;
	float uvx = texcoordScaled.x;

	float v = Random_float(texcoord + vec2(timeM60, timeM200));
	float v2 = Random_float(texcoord + vec2(1.0 + timeM60, timeM200));


	float vRow = Random_float(vec2(time, int(uvy)));

	// Screen Tear
#if ScreenTearSpeed < 1
	if (ScreenTearSpeed <= 0) {
		float offset = ScreenTearDelay * 0.001;

		if (uvy < ScreenTearSize + offset && uvy > offset) {
			texcoord.y = uvy = fract(offset);
			#ifdef ScreenTearSolid
			texcoordScaled.y = uvy;
			#endif
		}
	} else 
#endif
	{
		float y1 = mod(ScreenTearSpeed * time + ScreenTearSize, ScreenTearDelay + ScreenTearSize);
		float y2 = uvy-y1;
		if (y2 < 0.0f && y2 > -ScreenTearSize) {
			texcoord.y = uvy = fract(y1);
			#ifdef ScreenTearSolid
			texcoordScaled.y = uvy;
			#endif
		}
	}

	vec3 sum = vec3(0);

	// Bloom
#if BloomSize >= 0 || defined(PortalStatic)
	#if BloomSize >= 0
		vec3 color = texture2D(colortex0, texcoordScaled).rgb;
		vec3 bloom;
	#endif

	#ifdef PortalStatic
		float staticSum = 0;
	#endif

		for(int i= -3 ;i < 3; i++)
		{
			float v3 = (0.5 - Random_float(texcoordScaled + vec2(1.0 + i*3 + timeM60, timeM200))) + i;
			float v4 = (0.5 - Random_float(texcoordScaled + vec2(2.0 + i*3 + timeM60, timeM200)));
			float v5 = (0.5 - Random_float(texcoordScaled + vec2(3.0 + i*3 + timeM60, timeM200)));
			float v6 = (0.5 - Random_float(texcoordScaled + vec2(4.0 + i*3 + timeM60, timeM200)));

			vec2 cordA = texcoordScaled + vec2(-1 + v4, v3)*0.004;
			vec2 cordB = texcoordScaled + vec2( v5, v3)*0.004;
			vec2 cordC = texcoordScaled + vec2( 1 + v6, v3)*0.004;

	#if BloomSize >= 0
			sum += texture2D(colortex0, cordA).xyz * BloomSize;
			sum += texture2D(colortex0, cordB).xyz * BloomSize;
			sum += texture2D(colortex0, cordC).xyz * BloomSize;
	#endif

	#ifdef PortalStatic
			staticSum += xmy(texture2D(colortex1, cordA));
			staticSum += xmy(texture2D(colortex1, cordB));
			staticSum += xmy(texture2D(colortex1, cordC));
	#endif
		}

	#ifdef PortalStatic
		staticSum = staticSum / 18.0;
	#endif

	#if BloomSize >= 0

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
		
		bloom = mix(color, bloom, BloomSize);

		
		float sumSingle = (bloom.r + bloom.g + bloom.b) / 3.0;
		float tanSum = tan(min(sumSingle * 1.5, 1.57079632679))/ 64;
		float _BlurSize = clamp(BlurSize * tanSum, BlurSize, 0.01);
	#else
		float _BlurSize = BlurSize;
	#endif
#else
	float _BlurSize = BlurSize;
#endif

	// blur and aberration
#if BlurSize >= 0
	float vScaled = v * _BlurSize;
	float v2Scaled = v2 * _BlurSize;

	float BlurSize2 = _BlurSize / 4;

	float vHalf = vScaled / 2;

	vec3 left1 = texture2D(colortex0, vec2(uvx - vScaled, uvy + vScaled / 3.0)).rgb;
	vec3 left2 = texture2D(colortex0, vec2(uvx - vHalf + (left1.r * BlurSize2), uvy + vScaled / 6.0 + (left1.g * BlurSize2))).rgb;
	vec3 center = texture2D(colortex0, vec2(uvx - vHalf / 2.0 + v2Scaled / 4.0, uvy - vHalf / 4.0 + v2Scaled / 8.0)).rgb;
	vec3 right1 = texture2D(colortex0, vec2(uvx + vScaled, uvy + vScaled)).rgb;
	float right2Offset = vHalf - (right1.r * BlurSize2);
	vec3 right2 = texture2D(colortex0, vec2(uvx + right2Offset, uvy + right2Offset)).rgb;
# else
	vec3 center = texture2D(colortex0, vec2(uvx - vHalf / 2.0 + v2Scaled / 4.0, uvy - vHalf / 4.0 + v2Scaled / 8.0)).rgb;
#endif

#if BloomSize >= 0
	center = center / 2.0 + bloom / 2.0;
#endif

	sum = vec3(
#if BlurSize >= 0
		(left1[0] + left2[0] + center[0])/3,
#else
		center[0],
#endif
	#if BloomSize < 0
		center[1] * Green,
	#else
		center[1] * ((1. - (BloomSize / 4.)) * Green),
	#endif
#if BlurSize >= 0
		(right1[2] + right2[2] + center[2])/3);
#else
		center[2];
#endif


	// Static and tearing
#ifdef PortalStatic
	float _static = max(Static + staticSum, Static);
#else
	float _static = Static;
#endif
	float l = abs(vRow - texcoord.y)*StaticTearChance;
	if (StaticTearChance < 400 && l < 0.004f*v) _static = 1-min(l,0.05f*v)*50/v;
	if (v < _static)
	{
		float sv = (_static+.5)*v2;
		sum = (sum + vec3(sv)) * (1-_static) + vec3(v * _static);
	}

#if DarkEdges >= 0
	// Edges
	float a = texcoord_vs.x*100-DarkEdges;
	// Left edge
	sum *= min(a*3 + v*0.2, 2.0f) - min(a*a + v2*0.2, 1.0f);
	a = (1-texcoord_vs.x)*150- int(DarkEdges * 1.5);
	// Right edge
	sum *= min(a + v2*0.2, 1.0f);
#endif

	fragColor = vec4(sum, 1.0);
}
