#include "/shader.h"
#include "/common/fog.glsl"

//0-1 amount of blindness.
uniform float blindness;
//0 = default, 1 = water, 2 = lava.
uniform int isEyeInWater;

uniform float far;

//Vertex color.
varying vec4 color;

void main()
{

    #if defined(DISCARD_SKY) && defined(SKYBASIC)
        discard;
    #endif

    vec4 col = color;

    #if defined(SKYBASIC)
    if (col.r < 0.5)
    #endif
    // Apply the fog.
    col.rgb = mix(col.rgb, gl_Fog.color.rgb,FogNDF(isEyeInWater, far));

    // Apply blindness
    col.rgb *= vec3(1.-blindness);

    //Output the result.
    gl_FragData[0] = col;
}
