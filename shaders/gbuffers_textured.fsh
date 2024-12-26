#version 130
#define PortalParticles

//Diffuse (color) texture.
uniform sampler2D texture;
//Lighting from day/night + shadows + light sources.
uniform sampler2D lightmap;

//RGB/intensity for hurt entities and flashing creepers.
uniform vec4 entityColor;
//0-1 amount of blindness.
uniform float blindness;
//0 = default, 1 = water, 2 = lava.
uniform int isEyeInWater;

uniform int renderStage;

//Vertex color.
varying vec4 color;
//Diffuse and lightmap texture coordinates.
varying vec2 coord0;
varying vec2 coord1;
varying float mcEntity;

bool MYMatch (vec3 rgb) {
    float r = rgb.r;
    float g = rgb.g;
    float b = rgb.b;
    float k = min(1.0 - r, min(1.0 - g, 1.0 - b));
    vec3 cmy = vec3(0.0);
    float invK = 1.0 - k;
    if (invK != 0.0) {
		cmy.x = (1.0 - r - k) / invK;
        cmy.y = (1.0 - g - k) / invK;
        cmy.z = (1.0 - b - k) / invK;
    }
    return cmy.x < 0.109 && cmy.x > 0.07 && abs(cmy.y - .7) < 0.01 && abs(cmy.z) < 0.01;
}

/* DRAWBUFFERS:01 */
void main()
{
    //Combine lightmap with blindness.
    vec3 light = (1.-blindness) * texture2D(lightmap,coord1).rgb;
    //Sample texture times lighting.
    vec4 col = color * vec4(light,1) * texture2D(texture,coord0);
    //Apply entity flashes.
    col.rgb = mix(col.rgb,entityColor.rgb,entityColor.a);

    //Calculate fog intensity in or out of water.
    float fog = (isEyeInWater>0) ? 1.-exp(-gl_FogFragCoord * gl_Fog.density):
    clamp((gl_FogFragCoord-gl_Fog.start) * gl_Fog.scale, 0., 1.);

    //Apply the fog.
    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);

    //Output the result.
	float e = mcEntity;
#ifdef PortalParticles
	if (renderStage == MC_RENDER_STAGE_PARTICLES && MYMatch(color.rgb)) {e = 2;}
#endif
    gl_FragData[0] = col;
	gl_FragData[1] = vec4(e-1,0,0,0);
}
