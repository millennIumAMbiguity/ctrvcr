#include "/shader.h"
uniform sampler2D colortex0;
uniform vec2 resolution;

varying vec4 color;
varying vec2 coord0;

void main()
{
#if SCANLINE_INTENSITY != -1

	#if SCANLINE_PIXEL_SIZE > 1
		float scanline = (sin(gl_FragCoord.y * 1.57079632679 / (SCANLINE_PIXEL_SIZE * 2)));
		float scanlineM = scanline * scanline * SCANLINE_INTENSITY_F;
			if (scanline > 0) scanline = 1 + scanlineM;
			else scanline = 1 - scanlineM;
			gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
			return;
	#else
		float scanline = mod(gl_FragCoord.y, 2); // 0.5 - 2.0
	#endif

	#if SCANLINE_INTENSITY >= 100
		if (scanline > 1) scanline *= SCANLINE_INTENSITY_F;
		gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
	#else
		if (scanline > 1) scanline = 1 + SCANLINE_INTENSITY_F / 2;
		else scanline += 0.5 - SCANLINE_INTENSITY_F / 2;
		gl_FragData[0] = color * texture2D(colortex0,coord0) * scanline;
	#endif
#else
	gl_FragData[0] = color * texture2D(colortex0,coord0);
#endif
}