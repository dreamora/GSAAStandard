#ifndef STANDARD_LIGHTING_MODEL_DITHERED
#define STANDARD_LIGHTING_MODEL_DITHERED


//#define UNITY_PBS_USE_BRDF1


#ifdef DITHERING_ON
#define MOD3 float3(443.8975,397.2973, 491.1871)

float ditherNoiseFuncLow(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * MOD3 + _Time.y);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float3 ditherNoiseFuncHigh(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * (MOD3 + _Time.y));
    p3 += dot(p3, p3.yxz + 19.19);
    return frac(float3((p3.x + p3.y)*p3.z, (p3.x + p3.z)*p3.y, (p3.y + p3.z)*p3.x));
}
#endif

struct Input
{
    float3 worldNormal;
    INTERNAL_DATA
    float2 uv_texcoord;
};

struct SurfaceOutputDitheredStandard
{
    fixed3 Albedo;
    fixed Alpha;
    fixed3 Normal;
    half3 Emission;
    half Metallic;
    half Smoothness;
    half Occlusion;
    float3 Dithering;
    float Attenuation;
    float SpecularLightmapOcclusion;
};

uniform float4 _Color;
#ifdef ALBEDO_TEX_ON
uniform sampler2D _MainTex;
uniform float4 _MainTex_ST;
#endif
#ifdef NORMAL_ON
uniform sampler2D _BumpMap;
uniform float4 _BumpMap_ST;
uniform float _BumpScale;
#endif
#if PBR_TEX_ON
uniform sampler2D _MetallicGlossMap;
uniform float4 _MetallicGlossMap_ST;
#endif
uniform float _OcclusionStrength;
float _Glossiness;
float _Metallic;
#ifdef EMISSION_ON
uniform sampler2D _EmissionMap;
uniform float4 _EmissionMap_ST;
uniform float4 _EmissionColor;
#endif
#ifdef DITHERING_ON
float _NoiseScale;
#endif
#ifdef SPECULAROCCLUSION_ON
float _SpecularLightmapOcclusion;
#endif


inline void LightingDitheredStandard_GI(inout SurfaceOutputDitheredStandard s, UnityGIInput data, inout UnityGI gi)
{
    // Global Illumination and Environment Reflections
    #ifdef UNITY_PASS_FORWARDBASE
        Unity_GlossyEnvironmentData unityGlossyEnvironmentData = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, float3(0, 0, 0));
        gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, unityGlossyEnvironmentData);
    #endif


    #ifdef LIGHTMAP_ON
        // Quick hack to kill specular in lightmap shadows
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
        half3 bakedColor = DecodeLightmap(bakedColorTex);
        gi.indirect.specular *= lerp(1.0, saturate(Luminance(bakedColor)), s.SpecularLightmapOcclusion);
    #endif

#ifdef DITHERING_ON
    s.Attenuation = data.atten;
#endif
}

inline half4 LightingDitheredStandard(inout SurfaceOutputDitheredStandard s, half3 viewDir, UnityGI gi)
{
    SurfaceOutputStandard standardSurfaceOutput = (SurfaceOutputStandard) 0;

    // Populate SurfaceOutputStandard struct
    standardSurfaceOutput.Albedo = s.Albedo;
    standardSurfaceOutput.Alpha = s.Alpha;
    standardSurfaceOutput.Normal = s.Normal;
    standardSurfaceOutput.Emission = s.Emission;
    standardSurfaceOutput.Metallic = s.Metallic;
    standardSurfaceOutput.Smoothness = s.Smoothness;
    standardSurfaceOutput.Occlusion = s.Occlusion;

    // Standard Lighting
    float3 standardLightingResult = LightingStandard(standardSurfaceOutput, viewDir, gi).rgb;

    // Final Color
    half4 finalColor = half4(0, 0, 0, 1);
    finalColor.rgb = standardLightingResult;
#if EMISSION_ON
    finalColor.rgb += standardSurfaceOutput.Emission;
#endif
#if DITHERING_ON
    finalColor.rgb += (s.Dithering * s.Attenuation);
#endif

    // Alpha
    finalColor.a = s.Alpha;

    return finalColor;
}

void surf(Input i , inout SurfaceOutputDitheredStandard o)
{
    // Albedo and Alpha
#ifdef ALBEDO_TEX_ON
    float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
    float4 mainTex = tex2D(_MainTex, uv_MainTex);
    o.Albedo = mainTex.rgb * _Color.rgb;
    o.Alpha = mainTex.a * _Color.a;
#else
    o.Albedo = _Color.rgb;
    o.Alpha = _Color.a;
#endif

    // Normal Map
#ifdef NORMAL_ON
    float2 uv_Normal = i.uv_texcoord * _BumpMap_ST.xy + _BumpMap_ST.zw;
    o.Normal = UnpackNormalWithScale(tex2D(_BumpMap, uv_Normal), _BumpScale);
#else
    o.Normal = fixed3(0,0,1);
#endif

    // Emission
#ifdef EMISSION_ON
    half3 emission = 0;
    
    #ifdef EMISSION_TEX_ON
    float2 uv_EmissionMap = i.uv_texcoord * _EmissionMap_ST.xy + _EmissionMap_ST.zw;
    emission = (tex2D(_EmissionMap, uv_EmissionMap) * _EmissionColor).rgb;
    #endif
    
    #ifdef EMISSION_ALBEDO_BOOST
    emission += _EmissionColor.a * _EmissionColor.rgb * o.Albedo.rgb;
    #endif
    
    o.Emission = emission;
#else
    o.Emission = 0;
#endif

    // Metallic, Smoothness & AO Occlusion
#ifdef PBR_TEX_ON
    float2 uv_MetallicGlossMap = i.uv_texcoord * _MetallicGlossMap_ST.xy + _MetallicGlossMap_ST.zw;
    float4 pbrMap = tex2D(_MetallicGlossMap, uv_MetallicGlossMap);
    o.Metallic = pbrMap.r * _Metallic;
    o.Smoothness = (1-pbrMap.g) * _Glossiness;
    o.Occlusion = lerp(1.0, pbrMap.b, _OcclusionStrength);
#else
    o.Metallic = _Metallic;
    o.Smoothness = _Glossiness;
    o.Occlusion = _OcclusionStrength;
#endif

    // Geometric Specular AA (Valve Method)
    float3 vNormalWsDdx = ddx(i.worldNormal.xyz);
    float3 vNormalWsDdy = ddy(i.worldNormal.xyz);
    float flGeometricRoughnessFactor = pow(saturate(max(dot(vNormalWsDdx.xyz, vNormalWsDdx.xyz), dot(vNormalWsDdy.xyz, vNormalWsDdy.xyz))), 0.333);
    o.Smoothness = min(o.Smoothness, 1.0 - flGeometricRoughnessFactor); // Ensure we don�t double-count roughness if normal map encodes geometric roughness

#ifdef DITHERING_ON
    // Compute Dithering
    o.Dithering = (ditherNoiseFuncLow(i.uv_texcoord.xy) - 0.5) * 2 * _NoiseScale;
#else
    o.Dithering = 0.001;
#endif

#ifdef SPECULAROCCLUSION_ON
    // Specular Lightmap Occlusion
    o.SpecularLightmapOcclusion = _SpecularLightmapOcclusion;
#else
    o.SpecularLightmapOcclusion = 1;
#endif

    return;
}

#endif