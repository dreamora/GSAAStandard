// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Dreamora/StandardLightingDitheredFade"
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
        _Metallic("Metallic", Range(0,1)) = 1
        _Glossiness("Smoothness", Range(0,1)) = 1
        _OcclusionStrength("AO Strength", Range(0.0, 1.0)) = 1.0

        // Emission
        [Toggle(EMISSION_ALBEDO_BOOST)] _EmissionAlbedoBoostOn("USE EMISSION ALBEDO BOOST ", Int) = 0
        _EmissionMap("Emission Map", 2D) = "white" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)

        // Dithering
       [Toggle(DITHERING_ON)]_DitheringOn("USE DITHERING", Int) = 0
        _NoiseScale("Dithering Scale", Range(0,0.2)) = 0.001

        // Specular Lightmap Occlusion
        [Toggle(SPECULAROCCLUSION_ON)]_SpecularOcclusionOn("USE SPECULAR OCCLUSION", Int) = 0
        _SpecularLightmapOcclusion("Specular Lightmap Occlusion Scale", Range(0,1)) = 1
        
        [ToggleOff(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Int) = 1.0
        [ToggleOff(_GLOSSYREFLECTIONS_OFF)] _GlossyReflections("Glossy Reflections", Int) = 1.0

        // Hacks
        [HideInInspector] _texcoord("", 2D) = "white" {}
        [HideInInspector] __dirty("", Int) = 1
    }

    SubShader
    {
        Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent" }
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
        #pragma surface surf DitheredStandard keepalpha fullforwardshadows alpha:fade
        ENDCG

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            ZWrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile UNITY_PASS_SHADOWCASTER
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #include "HLSLSupport.cginc"
            #if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
                #define CAN_SKIP_VPOS
            #endif
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 customPack1 : TEXCOORD1;
                float4 tSpace0 : TEXCOORD2;
                float4 tSpace1 : TEXCOORD3;
                float4 tSpace2 : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            v2f vert(appdata_full v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                Input customInputData;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                o.customPack1.xy = customInputData.uv_texcoord;
                o.customPack1.xy = v.texcoord;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
            fixed4 frag(v2f IN
            #if !defined( CAN_SKIP_VPOS )
            , UNITY_VPOS_TYPE vpos : VPOS
            #endif
            ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                Input surfIN;
                UNITY_INITIALIZE_OUTPUT(Input, surfIN);
                surfIN.uv_texcoord = IN.customPack1.xy;
                float3 worldPos = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                surfIN.worldNormal = float3(IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z);
                surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
                surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
                surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
                SurfaceOutputDitheredStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputDitheredStandard, o)
                surf(surfIN, o);
                #if defined( CAN_SKIP_VPOS )
                float2 vpos = IN.pos;
                #endif
                SHADOW_CASTER_FRAGMENT(IN)
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
    CustomEditor "Dreamora.GSAAStandard.Editor.GSAAStandardEditor"
}
