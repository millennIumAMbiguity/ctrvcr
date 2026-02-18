#include "/shader.h"
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

#if AIWS_SOURCE == 0 || AIWS_SOURCE == 3 || LIGHTMAP_DITERING != -1 || defined(DITTER_FOG) || defined(HAND_DYNAMIC_LIGHTING)
uniform float frameTimeCounter;
#endif

varying vec3 mcEntityPos;
#if AIWS_SOURCE == 2
#elif AIWS_SOURCE > 0
uniform vec3 cameraPosition;
#endif

//Vertex color.
varying vec4 color;
//Diffuse and lightmap texture coordinates.
varying vec2 coord0;
varying vec2 coord1;
varying vec2 mcEntity;
#if LIGHTMAP_DITERING != -1 || defined(DITTER_FOG) || defined(DISTANT_HORIZONS) || defined(HAND_DYNAMIC_LIGHTING)
varying vec3 worldPos;
#endif

#ifdef DH_WATER
    uniform sampler2D depthtex0;
    uniform float viewWidth;
    uniform float viewHeight;
#endif

#ifdef DISTANT_HORIZONS
    uniform float far;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif

#ifdef HAND_DYNAMIC_LIGHTING
   uniform int heldBlockLightValue;
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

#ifdef NOT_VANILLA_LIGHT_IRIS
vec3 CalculateLightStrengthAndColor(float x)
{
    #if MOONLIGHT_STRENGHT == -1
        float sunLightStrength = min(sin(x * PI2) * 2 + 0.2, 1.) * coord1.y;
    #else
        float sunLightStrength = clamp(sin(x * PI2) * 2 + 0.2, MOONLIGHT_STRENGHT_F, 1.) * coord1.y;
    #endif

    float sunrise = sunLightStrength * (max(cos(x * PI2 + 0.1) * 2 - 1, 0) + max(cos(x * PI2 + 0.1 + PI) * 2 - 1, 0));

    vec3 sunLight = sunLightStrength * vec3(COLOR_LIGHT_SKY_R_F, COLOR_LIGHT_SKY_G_F, COLOR_LIGHT_SKY_B_F);
    vec3 sunsetLight = sunrise * vec3(COLOR_LIGHT_SUNRISE_R_F, COLOR_LIGHT_SUNRISE_G_F, COLOR_LIGHT_SUNRISE_B_F);
    vec3 skyLight = max(sunLight, sunsetLight) * (1. - rainStrength / 2.);

    vec3 blockLight = coord1.x * vec3(COLOR_LIGHT_BLOCK_R_F, COLOR_LIGHT_BLOCK_G_F, COLOR_LIGHT_BLOCK_B_F);

    // 33% bleed between block and sky light, 67% of the stronger light.
    return (blockLight + skyLight) * .33 + max(blockLight, skyLight) * 0.67;
}
#else
vec3 CalculateLightStrengthAndColor(float x)
{
    return texture2D(lightmap, coord1).rgb;
}
#endif

void main()
{
    #ifdef DH_WATER
        vec2 depthCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
        float depth = texture2D(depthtex0, depthCoord).r;
        if (depth != 1.0) discard;
    #endif

    //Combine lightmap with blindness.
    vec3 light = CalculateLightStrengthAndColor(sunAngle);

#if defined(DISTANT_HORIZONS) || defined(HAND_DYNAMIC_LIGHTING)
    float linearDepth = length(worldPos);
#endif

#ifdef HAND_DYNAMIC_LIGHTING
    {
        float handlight = 1.05-clamp((linearDepth)/heldBlockLightValue, 0, 1.05);
        handlight *= handlight * handlight; // handlight^4
        vec3 handLightColor = vec3(COLOR_LIGHT_HAND_R_F, COLOR_LIGHT_HAND_G_F, COLOR_LIGHT_HAND_B_F) * handlight;
        light = mix(handLightColor, light + handLightColor/10, light);
    }
#endif

#if LIGHTMAP_DITERING != -1 || defined(DITTER_FOG)
    float time8 = mod(frameTimeCounter * 7.987, 8192);
    float time8_rf = Random_float(coord1 * time8 + worldPos.x + worldPos.y + worldPos.z);
#endif

#ifdef DISTANT_HORIZONS
    #ifdef DITTER_FOG
        #ifdef DH
            if (time8_rf >= (linearDepth - (far - dhNearPlane))/(far*0.1) + 2.) {
                discard;
            }
        #else
            if (time8_rf < (linearDepth - (far - dhNearPlane))/(far*0.1)) {
                discard;
            }
        #endif
    #endif
#endif

#if LIGHTMAP_DITERING != -1
    if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID) {
        light = (1. - blindness) * max(light + (LIGHTMAP_DITERING_F * time8_rf / 16.0), 0.0);
    } else
#endif
    {
        light *= 1. - blindness;
    }

    // Apply darkness and lighting strength.
#if DARKNESS_INTENSITY >= 0
    light = pow(light, vec3(DARKNESS_INTENSITY_F));
#endif

#if LIGHTNING_STRENGTH != -1
    light *= LIGHTNING_STRENGTH_F;
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

        #if AIWS_SOURCE == 0 // time
            vec2 source = vec2(frameTimeCounter, frameTimeCounter);
            source += vec2(1020, 1020);
        #elif AIWS_SOURCE == 1 // position
            vec2 source = vec2(cameraPosition.x + cameraPosition.z, cameraPosition.y + cameraPosition.z);
        #elif AIWS_SOURCE == 2 // pos rot
            vec2 source = vec2(mcEntityPos.x + mcEntityPos.z, mcEntityPos.y + mcEntityPos.z);
        #else
            vec2 source = vec2(cameraPosition.x + cameraPosition.z + frameTimeCounter, cameraPosition.y + cameraPosition.z + frameTimeCounter);
        #endif
        source *= AIWS_SPEED_F;

        #if AIWS_TYPE == 0
            float v = hash(of, sin(source.x + coord0.x*100));
            float v2 = hash(of, cos(source.y + coord0.y*100 - 1000));
        #elif AIWS_TYPE == 1
            float v = hash(of, mod(source.x + coord0.x*100, 8192)) - 0.5f;
            float v2 = hash(of, mod(source.y + coord0.y*100 - 1000, 8192)) - 0.5f;
        #elif AIWS_TYPE == 2
            float v = hash(of, tan(source.x + coord0.x*100 - 1000 + sin(source.x + coord0.y*coord0.x*100)));
            float v2 = hash(of, tan(source.y + coord0.y*100 + sin(source.y + coord0.y*coord0.x*80 - 1000)));
        #elif AIWS_TYPE == 3
            float v = hash(of, coord0.x * AIWS_SPEED_F);
            float v2 = hash(of, coord0.y * AIWS_SPEED_F);
        #elif AIWS_TYPE == 4
            float v = hash(of, source.x);
            float v2 = hash(of, source.y);
        #elif AIWS_TYPE == 5
            float v = Random_float_t(of, 1f + mod(floor(source.x * 16f), 512));
            float v2 = Random_float_t(of, 1f + mod(floor(source.y * 16f), 512));
        #endif

        c0 = offsetCoord(coord0, vec2(v, v2) * AIWS_INTENSITY_F, textureSize);
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

#if !defined(TERRAIN)
    if (col.a >= 0.999) {
        gl_FragData[0] = col;
        return;
    }
#endif

    //Apply entity flashes.
    col.rgb = mix(col.rgb,entityColor.rgb,entityColor.a);

    //Calculate fog intensity in or out of water.


#ifdef DISTANT_HORIZONS
    float fog_l = linearDepth;
    float fog_d = max(gl_Fog.density, 0.05 * FOG_MULT_F);
    float fog_start = dhFarPlane - fog_l;

    #ifdef DITTER_FOG
        float fog_s = (10 * FOG_MULT_F)/dhFarPlane;
    #else
        float fog_s = (5 * FOG_MULT_F)/dhFarPlane;
        fog_start = far/2.;
    #endif
#else
    float fog_l = gl_FogFragCoord;
    float fog_d = max(gl_Fog.density, 0.05 * FOG_MULT_F);
    float fog_s = max(gl_Fog.scale, 0.005 * FOG_MULT_F);
    float fog_start = gl_Fog.start;
#endif


#ifdef DITTER_FOG
    if (isEyeInWater>0) {
        col.rgb = mix(col.rgb, gl_Fog.color.rgb, 1.-exp(-fog_l * fog_d));
    }
    else
    {
        if (time8_rf < clamp((fog_l-fog_start) * fog_s, 0., 1.)) {
            discard;
        }
        #ifdef DISTANT_HORIZONS
        else {
            fog_s = (5 * FOG_MULT_F)/dhFarPlane;
            fog_start = far/2.;
            col.rgb = mix(col.rgb, gl_Fog.color.rgb, clamp((fog_l-fog_start) * fog_s, 0., 1.));
        }
        #endif
    }
#else
    float fog = (isEyeInWater>0) ? 1.-exp(-fog_l * fog_d):
    clamp((fog_l-fog_start) * fog_s, 0., 1.);

    col.rgb = mix(col.rgb, gl_Fog.color.rgb, fog);
#endif


    //Output the result.

#ifdef PORTAL_STATIC_IRIS
	float e = mcEntity.x;
    #ifdef PORTAL_STATIC_PARTICLES_IRIS
	    if (renderStage == MC_RENDER_STAGE_PARTICLES && MYMatch(color.rgb)) {e = 2;}
    #endif

    /* DRAWBUFFERS:07 */
    gl_FragData[0] = col;
	gl_FragData[1].b = (e > 1.5 && e < 2.5) ? 1 : 0;
#else
    gl_FragData[0] = col;
#endif
}
