
float OldFog(float isEyeInWater) {
    float fog_d = max(gl_Fog.density, 0.05 * FOG_MULT_F);
    float fog_s = max(gl_Fog.scale, 0.005 * FOG_MULT_F);

    //Calculate fog intensity in or out of water.
    float fog = (isEyeInWater > 0) ? 1.-exp(-gl_FogFragCoord * fog_d):
    clamp((gl_FogFragCoord-gl_Fog.start) * fog_s, 0., 1.);

    return fog;
}

float OldFogS(float isEyeInWater, float scale) {
    float fog_d = max(gl_Fog.density, 0.05 * scale);
    float fog_s = max(gl_Fog.scale, 0.005 * scale);

    //Calculate fog intensity in or out of water.
    float fog = (isEyeInWater > 0) ? 1.-exp(-gl_FogFragCoord * fog_d):
    clamp((gl_FogFragCoord-gl_Fog.start) * fog_s, 0., 1.);

    return fog;
}

float FogNDF(float isEyeInWater, float far) {
    #ifdef DISTANT_HORIZONS
        float fog_l = linearDepth;
        float fog_d = max(gl_Fog.density, 0.05 * FOG_MULT_F);
        float fog_start = dhFarPlane - fog_l;

        float fog_s = (5 * FOG_MULT_F)/dhFarPlane;
        fog_start = far/2.;
    #else
        float fog_l = gl_FogFragCoord;
        float fog_d = max(gl_Fog.density, 0.5 * FOG_MULT_F) + 0.0000001;
        float fog_start = gl_Fog.start/5 + 10 * FOG_MULT_F;
    #endif

    float fog = 0;
    if (isEyeInWater > 0) {
        fog = 1.-exp(-fog_l * fog_d);
    }
    else
    {
        fog = clamp((fog_l - fog_start) / (far - fog_start) + fog_d*(1-1/fog_l), 0., 1.);
    }

    //if (fog >= 1) discard;
    return fog;
}

float Fog(float isEyeInWater, float time8_rf, float far) {
    //#ifdef DITTER_FOG
    //#else
    //    return FogNDF(isEyeInWater);
    //#endif

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
        float fog_d = max(gl_Fog.density, 0.5 * FOG_MULT_F) + 0.0000001;
        float fog_start = gl_Fog.start/5 + 10 * FOG_MULT_F;
    #endif

    float fog = 0;

    if (isEyeInWater > 0) {
        fog = 1.-exp(-fog_l * fog_d);
    }
    else
    {
        fog = clamp((fog_l - fog_start) / (far - fog_start) + fog_d*(1-1/fog_l), 0., 1.);
    }

    #ifdef DITTER_FOG
        if (time8_rf < fog * 1.5 - 0.5) {
            //gl_FragDepth = 0;
            
            //return 1;
            discard;
        }
        return 0;
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
