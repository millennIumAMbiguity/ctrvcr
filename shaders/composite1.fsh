#version 120
#include "settings.glsl"
uniform sampler2D colortex0;
uniform vec2 resolution;

varying vec4 color;
varying vec2 coord0;

void main()
{
	#if ScanlineIntensity >= 1
		float scanline = mod(gl_FragCoord.y, 2); // 0.5 - 2.0
		if (scanline >= 1) scanline *= ScanlineIntensity;
		gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
	#elif ScanlineIntensity >= 0
		float scanline = mod(gl_FragCoord.y, 2); // 0.5 - 2.0
		if (scanline >= 1) scanline -= 1 - ScanlineIntensity;
		else scanline += 0.5 - ScanlineIntensity / 2;
		gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
	#else
		gl_FragData[0] = color * texture2D(colortex0,coord0);
	#endif
}