Shader "Dreamora/Standard"
{
    Properties
    {
        // Albedo Map and Tint Color
        _MainTex("MainTex", 2D) = "white" {}
        [HDR]_Color("Color Tint", Color) = (1,1,1,1)

        // Normal Map
        [Normal]_BumpMap("Normal", 2D) = "bump" {}
        _BumpScale("Normal scale", Range(0.01, 5)) = 1.0

        // PBR as metallic, roughness, AO
        _MetallicGlossMap("PBR (M, R, AO)", 2D) = "white"{}
        _Metallic("Metallic", Range(0,1)) = 1.0
        _Glossiness("Smoothness", Range(0,1)) = 1.0
        _OcclusionStrength("AO Strength", Range(0.0, 1.0)) = 1.0

        // Emission
        [Toggle(EMISSION_ALBEDO_BOOST)] _EmissionAlbedoBoostOn("USE EMISSION ALBEDO BOOST ", Int) = 0
        _EmissionMap("Emission Map", 2D) = "white" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)

        // Dithering
       [Toggle(DITHERING_ON)] _DitheringOn("USE DITHERING", Int) = 0
        _NoiseScale("Dithering Scale", Range(0,0.2)) = 0.001

        // Specular Lightmap Occlusion
        [Toggle(SPECULAROCCLUSION_ON)] _SpecularOcclusionOn("USE SPECULAR OCCLUSION", Int) = 0
        _SpecularLightmapOcclusion("Specular Lightmap Occlusion Scale", Range(0,1)) = 1
        
        [ToggleOff(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Int) = 1.0
        [ToggleOff(_GLOSSYREFLECTIONS_OFF)] _GlossyReflections("Glossy Reflections", Int) = 1.0

        // Hacks
        [HideInInspector] _texcoord("", 2D) = "white" {}
        [HideInInspector] __dirty("", Int) = 1
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }
        Cull Back

        CGINCLUDE
        #pragma multi_compile _ ALBEDO_TEX_ON
        #pragma multi_compile _ NORMAL_ON
        #pragma multi_compile _ EMISSION_ON
        #pragma multi_compile _ EMISSION_TEX_ON
        #pragma multi_compile _ EMISSION_ALBEDO_BOOST
        #pragma multi_compile _ PBR_TEX_ON
        #pragma multi_compile _ DITHERING_ON
        #pragma multi_compile _ SPECULAROCCLUSION_ON
        #pragma multi_compile _ _SPECULARHIGHLIGHTS_OFF
        #pragma multi_compile _ _GLOSSYREFLECTIONS_OFF
        
        #include "UnityPBSLighting.cginc"
        #include "Lighting.cginc"
        #pragma target 3.0

        #ifdef UNITY_PASS_SHADOWCASTER
            #undef INTERNAL_DATA
            #undef WorldReflectionVector
            #undef WorldNormalVector
            #define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
            #define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
            #define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
        #endif

        #include "StandardLightingModelDithered.cginc"
        
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        ENDCG

        CGPROGRAM
        #pragma surface surf DitheredStandard keepalpha addshadow fullforwardshadows
        ENDCG
    }
    Fallback "Diffuse"
    CustomEditor "Dreamora.GSAAStandard.Editor.GSAAStandardEditor"
}
