#include "/settings.glsl"

//Get Entity id.
attribute vec2 mc_Entity;

//Model * view matrix and it's inverse.
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

//Pass vertex information to fragment shader.
varying vec4 color;
varying vec2 coord0;
varying vec2 coord1;
varying vec2 mcEntity;

#if AIWS_Source == 2
varying vec3 mcEntityPos;
#endif

void main()
{
	mcEntity = mc_Entity;
    //Calculate world space position.
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
#if AIWS_Source == 2
    mcEntityPos = pos;
#endif
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;

    //Output position and fog to fragment shader.
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos,1);
    gl_FogFragCoord = length(pos);

    //Calculate view space normal.
    vec3 normal = gl_NormalMatrix * gl_Normal;
    //Use flat for flat "blocks" or world space normal for solid blocks.
    normal = (mcEntity==1.) ? vec3(0,1,0) : (gbufferModelViewInverse * vec4(normal,0)).xyz;

    //Calculate simple lighting. Thanks to @PepperCode1
    float light = min(normal.x * normal.x * 0.6f + normal.y * normal.y * 0.25f * (3.0f + normal.y) + normal.z * normal.z * 0.8f, 1.0f);

    //Output color with lighting to fragment shader.
    color = vec4(gl_Color.rgb * light, gl_Color.a);
	
    //Output diffuse and lightmap texture coordinates to fragment shader.
    coord0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    coord1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
