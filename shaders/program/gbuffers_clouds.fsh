#include "/shader.h"
#include "/common/fog.fsh"

//Diffuse (color) texture.
uniform sampler2D texture;

//0-1 amount of blindness.
uniform float blindness;
//0 = default, 1 = water, 2 = lava.
uniform int isEyeInWater;

//Vertex color.
varying vec4 color;
//Diffuse texture coordinates.
varying vec2 coord0;

void main()
{
    #ifdef DISTANT_HORIZONS
        discard;
    #endif

    //Visibility amount.
    vec3 light = vec3(1.-blindness);
    //Sample texture times Visibility.
    vec4 col = color * vec4(light,1) * texture2D(texture,coord0);

    // Apply the fog.
    #ifdef DISTANT_HORIZONS
        float fog = FogNDF(isEyeInWater, gl_FogFragCoord / 10);
    #else
        float fog = FogNDF(isEyeInWater, gl_FogFragCoord / 10);
    #endif
    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);

    //Output the result.
    gl_FragData[0] = col;
}
