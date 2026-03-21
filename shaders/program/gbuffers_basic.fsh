#include "/shader.h"
#include "/common/fog.fsh"

//0-1 amount of blindness.
uniform float blindness;
//0 = default, 1 = water, 2 = lava.
uniform int isEyeInWater;

//Vertex color.
varying vec4 color;

// 0-1 sun bitghness.
uniform float sunAngle;

void main()
{

    #if defined(DISCARD_SKY) && defined(SKYBASIC)
        discard;
    #endif

    vec4 col = color;

    #if defined(SKYBASIC)
    // dont fog stars
    if (col.r < 0.49999 || col.r > 0.5 || sunAngle < 0.5)
    #endif
    // Apply the fog.
    {
        #ifdef DISTANT_HORIZONS
            float fog = FogNDF(isEyeInWater, gl_FogFragCoord);
        #else
            float fog = FogNDF(isEyeInWater, gl_FogFragCoord);
        #endif
        col.rgb = mix(col.rgb, FogCol(), fog);
    }

    // Apply blindness
    col.rgb *= (1.-blindness);
    //Output the result.
    gl_FragData[0] = col;
}
