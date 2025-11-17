#include "/shader.h"

//0-1 amount of blindness.
uniform float blindness;
//0 = default, 1 = water, 2 = lava.
uniform int isEyeInWater;

//Vertex color.
varying vec4 color;

void main()
{

    #if defined(DISCARD_SKY) && defined(SKYBASIC)
        discard;
    #endif

    vec4 col = color;

    float fog_d = max(gl_Fog.density, 0.05 * FOG_MULT_F);
    float fog_s = max(gl_Fog.scale, 0.01 * FOG_MULT_F);

    //Calculate fog intensity in or out of water.
    float fog = (isEyeInWater>0) ? 1.-exp(-gl_FogFragCoord * fog_d):
    clamp((gl_FogFragCoord-gl_Fog.start) * fog_s, 0., 1.);

    //Apply the fog.
    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);

    //Output the result.
    gl_FragData[0] = col * vec4(vec3(1.-blindness),1);
}
