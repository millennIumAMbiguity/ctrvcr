#version 450 compatibility

uniform sampler2D colortex0;
uniform vec2 resolution;
uniform float frameTimeCounter;
in vec2 texcoord_vs;

layout(location = 0) out vec3 fragColor;

uniform float BlurSize;
uniform float Static;
uniform float ScreenTearSize;
uniform float ScreenTearDelay;
uniform float ScreenTearSpeed;
uniform float StaticTearChance;
uniform float BloomSize;
uniform float DistortionFactor;

float Random_float(vec2 Seed)
{
	return fract(sin(dot(Seed,vec2(12.9898,78.233)))*43758.5453123);
}

void main() {

	float time = frameTimeCounter;

	vec2 dir = texcoord_vs - vec2(0.5, 0.5);  // Direction from the center
	float dist = length(dir);                  // Distance from the center
	float distortion = 1.0 + DistortionFactor * dist * dist;  // Apply non-linear distortion
	vec2 texcoord = vec2(0.5, 0.5) + dir * distortion * (1-(DistortionFactor/2));  // Modify the UV coordinates

	float uvy = texcoord.y;
	float uvx = texcoord.x;
	vec2 viewSize = resolution.xy;

	float v = Random_float(texcoord + vec2(time, time*0.01));
	float v2 = Random_float(texcoord + vec2(1.0 + time, time));


	float vRow = Random_float(vec2(time, uvy));

	//	fragColor = vec3(vRow);
	//	return;

	// Screen Tear
	if (ScreenTearSpeed == 0) {
		if (uvy < ScreenTearDelay + ScreenTearSize && uvy > ScreenTearDelay) uvy = fract(ScreenTearDelay - ScreenTearSize);
	} else {
		float y1 = mod(ScreenTearSpeed * time + ScreenTearSize, ScreenTearDelay + ScreenTearSize);
		float y2 = uvy-y1;
		if (y2 < 0.0f && y2 > -ScreenTearSize) texcoord.y = uvy = fract(y1 - ScreenTearSize);
	}

	vec3 color = texture2D(colortex0, texcoord).rgb;
	vec3 sum = vec3(0);
	vec3 bloom;
	
	for(int i= -3 ;i < 3; i++)
	{
		float v3 = (0.5 - Random_float(texcoord + vec2(1.0 + i*3 + time, time))) + i;
		float v4 = (0.5 - Random_float(texcoord + vec2(2.0 + i*3 + time, time)));
		float v5 = (0.5 - Random_float(texcoord + vec2(3.0 + i*3 + time, time)));
		float v6 = (0.5 - Random_float(texcoord + vec2(4.0 + i*3 + time, time)));
		sum += texture2D(colortex0, texcoord + vec2(-1 + v4, v3)*0.004).xyz * BloomSize;
		sum += texture2D(colortex0, texcoord + vec2( v5, v3)*0.004).xyz * BloomSize;
		sum += texture2D(colortex0, texcoord + vec2( 1 + v6, v3)*0.004).xyz * BloomSize;
	}

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

	float vScaled = v * _BlurSize;
	float v2Scaled = v2 * _BlurSize;

	float BlurSize2 = _BlurSize / 4;

	float vHalf = vScaled / 2;

	//fragColor = vec3(uvx / 1000.0, y / 1000.0, 0);
	//fragColor = vec3((uvx - vScaled) / 1000.0, (y + vScaled / 3.0) / 1000.0, 0);
	//return;

	vec3 left1 = texture2D(colortex0, vec2(uvx - vScaled, uvy + vScaled / 3.0)).rgb;
	vec3 left2 = texture2D(colortex0, vec2(uvx - vHalf + (left1.r * BlurSize2), uvy + vScaled / 6.0 + (left1.g * BlurSize2))).rgb;
	vec3 center = texture2D(colortex0, vec2(uvx - vHalf / 2.0 + v2Scaled / 4.0, uvy - vHalf / 4.0 + v2Scaled / 8.0)).rgb;
	center = center / 2.0 + bloom / 2.0;
	vec3 right1 = texture2D(colortex0, vec2(uvx + vScaled, uvy + vScaled)).rgb;
	float right2Offset = vHalf - (right1.r * BlurSize2);
	vec3 right2 = texture2D(colortex0, vec2(uvx + right2Offset, uvy + right2Offset)).rgb;

	sum = vec3(
		(left1[0] + left2[0] + center[0])/3,
		center[1] * 0.9,
		(right1[2] + right2[2] + center[2])/3);



	// Static

	//float sumSingle = (sum.r + sum.g + sum.b) * 10.0;
	//float static_ = _Static / (sumSingle * sumSingle);
	float _static = Static;
	float l = abs(vRow - uvy)*StaticTearChance;
	if (StaticTearChance < 400 && l < 0.004f*v) _static = 1-min(l,0.05f*v)*50/v;
	if (v < _static)
	{
		float sv = (_static+.5)*v2;
		sum = (sum + vec3(sv)) * (1-_static) + vec3(v) * Static;
	}

	// Edges
	float a = texcoord_vs.x*100-1;
	// Left edge
	sum *= min(a*3 + v*0.2, 2.0f) - min(a*a + v2*0.2, 1.0f);
	a = (1-texcoord_vs.x)*200+1;
	// Right edge
	sum *= min(a + v2*0.1, 2.0f) - min(a*a + v*0.1, 1.0f);

	// Here's where we tell Minecraft what color we want this pixel.
	fragColor = sum;
}
