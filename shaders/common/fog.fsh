
#ifdef DISTANT_HORIZONS
    uniform float dhNearPlane;
    uniform float dhFarPlane;
#endif
uniform float far;

#if defined(DYNAMIC_FOG) && !defined(THE_NETHER) && !defined(THE_END)
    uniform ivec2 eyeBrightnessSmooth;
    float eyeBrightnessSmooth_f() {return eyeBrightnessSmooth.y/240.;}
#else
    float eyeBrightnessSmooth_f() {return 1.;}
#endif

vec3 FogCol() {
    #if defined(DYNAMIC_FOG) && !defined(THE_NETHER) && !defined(THE_END)
        return gl_Fog.color.rgb * eyeBrightnessSmooth_f();
    #else
        return gl_Fog.color.rgb;
    #endif
}

float OldFog(float isEyeInWater) {
    float fog_d = max(gl_Fog.density, 0.05 * FOG_MULT_F);
    float fog_s = max(gl_Fog.scale, 0.005 * FOG_MULT_F);

    //Calculate fog intensity in or out of water.
    float fog = (isEyeInWater > 0.0) ? 1.-exp(-gl_FogFragCoord * fog_d):
    clamp((gl_FogFragCoord-gl_Fog.start) * fog_s, 0., 1.);

    return fog;
}

float OldFogS(float isEyeInWater, float scale) {
    float fog_d = max(gl_Fog.density, 0.05 * scale);
    float fog_s = max(gl_Fog.scale, 0.005 * scale);

    //Calculate fog intensity in or out of water.
    float fog = (isEyeInWater > 0.0) ? 1.-exp(-gl_FogFragCoord * fog_d):
    clamp((gl_FogFragCoord-gl_Fog.start) * fog_s, 0., 1.);

    return fog;
}

float FogNDF(float isEyeInWater, float fog_l) {
    //return 0;
    float fog_d = max(gl_Fog.density, 0.5 * FOG_MULT_F);
    #ifdef DISTANT_HORIZONS
        float f = far;
        float fog_s = (5 * FOG_MULT_F)/f;
        float fog_start = f/2.;
    #else
        float f = far;
        float fog_start = gl_Fog.start/5. + 10. * FOG_MULT_F;
    #endif

    float fog = 0.0;
    if (isEyeInWater > 0.0) {
        fog = 1.-exp(-fog_l * fog_d);
    }
    #if defined(DYNAMIC_FOG) && !defined(THE_NETHER) && !defined(THE_END)
        if (f - fog_start <= 0.) return 1.-eyeBrightnessSmooth_f();
    #else
        if (f - fog_start <= 0.) return 0.;
    #endif
    else
    {
        fog = clamp((fog_l - fog_start) / (f - fog_start) + fog_d*(1.-1./fog_l), 0., 1.);
    }

    //if (fog >= 1) discard;
    return fog;
}

float Fog(float isEyeInWater, float time8_rf, float fog_l) {
    //#ifdef DITTER_FOG
    //#else
    //    return FogNDF(isEyeInWater);
    //#endif

    float fog_d = max(gl_Fog.density, 0.5 * FOG_MULT_F);
    #ifdef DISTANT_HORIZONS
        float f = dhFarPlane;

        #ifdef DITTER_FOG
            float fog_s = (10 * FOG_MULT_F)/dhFarPlane;
            float fog_start = dhFarPlane - fog_l;
        #else
            float fog_s = (5 * FOG_MULT_F)/dhFarPlane;
            float fog_start =  10 * FOG_MULT_F;
        #endif
    #else
        float f = far;
        float fog_start = gl_Fog.start/5 + 10 * FOG_MULT_F;
    #endif

    float fog = 0.;

    if (isEyeInWater > 0.) {
        fog = 1.-exp(-fog_l * fog_d);
    }
    if (f - fog_start <= 0.) return 0.;
    else
    {
        fog = clamp((fog_l - fog_start) / (f - fog_start) + fog_d*(1.-1./fog_l), 0., 1.);
    }

    #ifdef DITTER_FOG
        if (time8_rf < fog * 1.5 - 0.5) {
            //gl_FragDepth = 0;
            
            //return 1;
            discard;
        }
        return 0.0;
        //return (time8_rf < fog * 1.5 - 0.5) ? 1f: 0f;
    #endif

    //if (fog >= 1) discard;
    return fog;
}

void DhDitterFog(float time8_rf, float linearDepth){
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
}
