#version 120

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
    //Visibility amount.
    vec3 light = vec3(1.-blindness);
    //Sample texture times Visibility.
    vec4 col = color * vec4(light,1) * texture2D(texture,coord0);

    //Output the result.
    gl_FragData[0] = col;
}
