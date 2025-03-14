#include "/settings.glsl"
uniform sampler2D colortex0;
uniform vec2 resolution;

varying vec4 color;
varying vec2 coord0;

void main()
{
#if ScanlineIntensity >= 0

	#if ScanlinePixelSize > 1
		float scanline = (sin(gl_FragCoord.y * 1.57079632679 / (ScanlinePixelSize * 2)));
		float scanlineM = scanline * scanline * ScanlineIntensity;
			if (scanline > 0) scanline = 1 + scanlineM;
			else scanline = 1 - scanlineM;
			gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
			return;
	#else
		float scanline = mod(gl_FragCoord.y, 2); // 0.5 - 2.0
	#endif

	#if ScanlineIntensity >= 1
		if (scanline > 1) scanline *= ScanlineIntensity;
		gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
	#else
		if (scanline > 1) scanline = 1 + ScanlineIntensity / 2;
		else scanline += 0.5 - ScanlineIntensity / 2;
		gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
	#endif
#else
	gl_FragData[0] = color * texture2D(colortex0,coord0);
#endif
}