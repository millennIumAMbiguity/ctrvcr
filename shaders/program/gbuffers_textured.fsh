#include "/settings.glsl"
#include "/common/hash.glsl"

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
// 0-1 sun bitghness.
uniform float sunAngle;
// 0-1 rain amount.
uniform float rainStrength;

uniform int renderStage;

#if AIWS_Source == 0 || AIWS_Source == 3
uniform float frameTimeCounter;
#endif

varying vec3 mcEntityPos;
#if AIWS_Source == 2
#elif AIWS_Source > 0
uniform vec3 cameraPosition;
#endif

//Vertex color.
varying vec4 color;
//Diffuse and lightmap texture coordinates.
varying vec2 coord0;
varying vec2 coord1;
varying vec2 mcEntity;
#if LightmapDitering >= 0
varying vec3 worldPos;
#endif

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

vec2 offsetCoord(vec2 coord, vec2 offset, vec2 size) {
    
    offset /= size;
    vec2 size2 = size / 16;
    vec2 newCoord = coord + offset;

    // Warp texture around if it goes out of bounds
    newCoord -= (16 / size) * (floor(newCoord * size2) - floor(coord * size2));

    return newCoord;
}

vec3 CalculateLightStrengthAndColor(float x)
{
    #if MoonlightStrength >= 1
        float sunLightStrength = coord1.y;
    #else
        float sunLightStrength = clamp(sin(x * PI2) * 2 + .2, MoonlightStrength, 1.) * coord1.y;
    #endif

    float sunrise = sunLightStrength * (max(cos(x * PI2 + .1) * 2 - 1, 0) + max(cos(x * PI2 + .1 + PI) * 2 - 1, 0));

    vec3 sunLight = sunLightStrength * vec3(ColorLightSkyR, ColorLightSkyG, ColorLightSkyB);
    vec3 sunsetLight = sunrise * vec3(ColorLightSunriseR, ColorLightSunriseG, ColorLightSunriseB);
    vec3 skyLight = max(sunLight, sunsetLight) * (1. - rainStrength / 2.);

    vec3 blockLight = coord1.x * vec3(ColorLightBlockR, ColorLightBlockG, ColorLightBlockB);

    // 33% bleed between block and sky light, 67% of the stronger light.
    return (blockLight + skyLight) * .33 + max(blockLight, skyLight) * .67;
}

void main()
{
    //Combine lightmap with blindness.
    vec3 light = CalculateLightStrengthAndColor(sunAngle);

    float time8 = mod(frameTimeCounter * 7.987, 8192);
#if LightmapDitering >= 0
    if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID) {
        light = (1.-blindness) * clamp(light + (LightmapDitering * Random_float(coord1 * time8 + worldPos.x + worldPos.y + worldPos.z) / 16.), 0., 1.);
    } else
#endif
    {
        light *= (1.-blindness);
    }

    // Apply darkness and lighting strength.
#if DarknessIntensity >= 0
    light = pow(light, vec3(DarknessIntensity));
#endif

#if LightingStrength > 0
    light *= LightingStrength;
#endif

    vec4 col;

#if AIWS > 0

    vec2 c0;

    #if AIWS == 2
    if (mcEntity.y > 0.5)
    #endif
    {
        vec2 textureSize = vec2(textureSize(texture,0));
        vec2 of = floor(coord0 * textureSize);

        #if AIWS_Source == 0 // time
            vec2 source = vec2(frameTimeCounter, frameTimeCounter);
            source += vec2(1020, 1020);
        #elif AIWS_Source == 1 // position
            vec2 source = vec2(cameraPosition.x + cameraPosition.z, cameraPosition.y + cameraPosition.z);
        #elif AIWS_Source == 2 // pos rot
            vec2 source = vec2(mcEntityPos.x + mcEntityPos.z, mcEntityPos.y + mcEntityPos.z);
        #else
            vec2 source = vec2(cameraPosition.x + cameraPosition.z + frameTimeCounter, cameraPosition.y + cameraPosition.z + frameTimeCounter);
        #endif
        source *= AIWS_Speed;

        #if AIWS_Type == 0
            float v = hash(of, sin(source.x + coord0.x*100));
            float v2 = hash(of, cos(source.y + coord0.y*100 - 1000));
        #elif AIWS_Type == 1
            float v = hash(of, mod(source.x + coord0.x*100, 8192)) - 0.5f;
            float v2 = hash(of, mod(source.y + coord0.y*100 - 1000, 8192)) - 0.5f;
        #elif AIWS_Type == 2
            float v = hash(of, tan(source.x + coord0.x*100 - 1000 + sin(source.x + coord0.y*coord0.x*100)));
            float v2 = hash(of, tan(source.y + coord0.y*100 + sin(source.y + coord0.y*coord0.x*80 - 1000)));
        #elif AIWS_Type == 3
            float v = hash(of, coord0.x * AIWS_Speed);
            float v2 = hash(of, coord0.y * AIWS_Speed);
        #elif AIWS_Type == 4
            float v = hash(of, source.x);
            float v2 = hash(of, source.y);
        #elif AIWS_Type == 5
            float v = Random_float_t(of, 1f + mod(floor(source.x * 16f), 512));
            float v2 = Random_float_t(of, 1f + mod(floor(source.y * 16f), 512));
        #endif

        c0 = offsetCoord(coord0, vec2(v, v2) * AIWS_Intensity, textureSize);
    }
    #if AIWS == 2
    else 
    {
        c0 = coord0;
    }
    #endif

    //Sample texture times lighting.
    col = color * vec4(light,1) * texture2D(texture,c0);
#else
    //Sample texture times lighting.
    col = color * vec4(light,1) * texture2D(texture,coord0);
#endif

    //Apply entity flashes.
    col.rgb = mix(col.rgb,entityColor.rgb,entityColor.a);

    //Calculate fog intensity in or out of water.
#ifdef DitterFog
    if (isEyeInWater>0) {
        col.rgb = mix(col.rgb, gl_Fog.color.rgb, 1.-exp(-gl_FogFragCoord * gl_Fog.density));
    }
    else if (Random_float(coord1 * time8 + worldPos.x + worldPos.y + worldPos.z) < clamp((gl_FogFragCoord-gl_Fog.start) * gl_Fog.scale, 0., 1.)) {
        discard;
    }
#else
    float fog = (isEyeInWater>0) ? 1.-exp(-gl_FogFragCoord * gl_Fog.density):
    clamp((gl_FogFragCoord-gl_Fog.start) * gl_Fog.scale, 0., 1.);

    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);
#endif

    //Output the result.

#ifdef PortalStatic
	float e = mcEntity.x;
    #ifdef PortalParticles
	    if (renderStage == MC_RENDER_STAGE_PARTICLES && MYMatch(color.rgb)) {e = 2;}
    #endif

    /* DRAWBUFFERS:07 */
    gl_FragData[0] = col;
	gl_FragData[1].b = (e > 1.5 && e < 2.5) ? 1 : 0;
#else
    gl_FragData[0] = col;
#endif
}
