#region

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

#endregion

namespace Dreamora.GSAAStandard.Editor
{
    /// <summary>
    ///     Custom shader editor for the DreamoraVR GSAA Shaders in an optimized way.
    /// </summary>
    public class GSAAStandardEditor : ShaderGUI
    {
        private static readonly GUIContent StaticLabel = new GUIContent();

        private static readonly string _forwardText = "Forward Rendering Options";
        private static readonly GUIContent _highlightsText = EditorGUIUtility.TrTextContent("Specular Highlights", "Specular Highlights");
        private static readonly GUIContent _reflectionsText = EditorGUIUtility.TrTextContent("Reflections", "Glossy Reflections");
        private MaterialEditor _editor;
        private MaterialProperty[] _properties;
        private Material _target;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            _editor = materialEditor;
            _target = _editor.target as Material;
            _properties = materialProperties;

            DoAlbedo();

            EditorGUILayout.Space();
            DoNormal();

            EditorGUILayout.Space();
            DoPBR();

            EditorGUILayout.Space();
            DoEmission();

            EditorGUILayout.Space();
            DoDithering();

            EditorGUILayout.Space();
            DoSpecularOcclusion();

            EditorGUILayout.Space();
            DoDefaultOptions();
        }

        /// <summary>
        /// Draw the Albedo and color editor.
        /// This is also responsible for setting the ALBEDO_TEX_ON shader keyword that controls texture fetching.
        /// </summary>
        private void DoAlbedo()
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty albedoMap = FindProperty("_MainTex");
            if (_target.shader.renderQueue >= (int) RenderQueue.AlphaTest)
            {
                _editor.TexturePropertySingleLine(MakeLabel(albedoMap, "Albedo (RGBA)"), albedoMap, FindProperty("_Color"));
            }
            else
            {
                _editor.TexturePropertySingleLine(MakeLabel(albedoMap, "Albedo (RGB)"), albedoMap, FindProperty("_Color"));
            }

            if (albedoMap.textureValue != null)
            {
                EditorGUI.indentLevel += 1;
                _editor.TextureScaleOffsetProperty(albedoMap);
                EditorGUI.indentLevel -= 1;
            }

            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("ALBEDO_TEX_ON", albedoMap.textureValue != null);
            }
        }
        
        /// <summary>
        /// Draw the normal map and normal scale editor.
        /// This is also responsible for setting the NORMAL_ON shader keyword that controls the usage of normal mapping.
        /// </summary>
        private void DoNormal()
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty normalMap = FindProperty("_BumpMap");
            _editor.TexturePropertySingleLine(MakeLabel(normalMap), normalMap);

            bool hasNormal = normalMap.textureValue != null;
            if (hasNormal)
            {
                EditorGUI.indentLevel += 1;
                _editor.TextureScaleOffsetProperty(normalMap);
                MaterialProperty normalScale = FindProperty("_BumpScale");
                _editor.ShaderProperty(normalScale, MakeLabel(normalScale));
                EditorGUI.indentLevel -= 1;
                EditorGUILayout.Space();
            }

            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("NORMAL_ON", hasNormal);
            }
        }
        
        /// <summary>
        /// Draw the PBR editor part including the pbr texture map and the metallic, smoothness and AO strength.
        /// This is also responsible for setting the PBR_TEX_ON shader keyword that controls if the pbr texture is being used to calculate
        /// the materials PBR attributes.
        /// </summary>
        private void DoPBR()
        {
            EditorGUI.BeginChangeCheck();
            MaterialProperty pbrMap = FindProperty("_MetallicGlossMap");
            _editor.TexturePropertySingleLine(MakeLabel(pbrMap, "PBR (Metallic, Roughness, AO)"), pbrMap);

            EditorGUI.indentLevel += 1;
            if (pbrMap.textureValue != null)
            {
                _editor.TextureScaleOffsetProperty(pbrMap);
            }

            MaterialProperty metallicSlider = FindProperty("_Metallic");
            _editor.ShaderProperty(metallicSlider, MakeLabel(metallicSlider));
            MaterialProperty smoothnessSlider = FindProperty("_Glossiness");
            _editor.ShaderProperty(smoothnessSlider, MakeLabel(smoothnessSlider));
            MaterialProperty aoSlider = FindProperty("_OcclusionStrength");
            _editor.ShaderProperty(aoSlider, MakeLabel(aoSlider));
            EditorGUI.indentLevel -= 1;

            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("PBR_TEX_ON", pbrMap.textureValue != null);
            }
        }

        /// <summary>
        /// Draw the emission and albedo boost editor.
        /// This is also responsible for setting the EMISSION_ON, EMISSION_TEX_ON and EMISSION_ALBEDO_BOOST shader keywords that control
        /// the presence of emission but also if it is driven by an emission mask texture and if the albedo color is being boosted.
        /// </summary>
        private void DoEmission()
        {
            EditorGUI.BeginChangeCheck();
            bool hasEmission = _editor.EmissionEnabledProperty();

            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("EMISSION_ON", hasEmission);
            }

            if (hasEmission)
            {
                EditorGUI.BeginChangeCheck();
                MaterialProperty emissionAlbedoBoost = FindProperty("_EmissionAlbedoBoostOn");
                _editor.ShaderProperty(emissionAlbedoBoost, MakeLabel(emissionAlbedoBoost));
                MaterialProperty emissionMap = FindProperty("_EmissionMap");
                _editor.TexturePropertySingleLine(MakeLabel(emissionMap, "Emission"), emissionMap, FindProperty("_EmissionColor"));
                if (emissionMap.textureValue != null)
                {
                    EditorGUI.indentLevel += 1;
                    _editor.TextureScaleOffsetProperty(emissionMap);
                    EditorGUI.indentLevel -= 1;
                }

                if (EditorGUI.EndChangeCheck())
                {
                    SetKeyword("EMISSION_TEX_ON", emissionMap.textureValue != null);
                }
            }
        }

        /// <summary>
        /// Draw the dithering noise editor.
        /// This is also responsible for setting the DITHERING_ON and DITHERING_MOBILE shader keywords that control the usage of the
        /// dithering noise as well is the quality and computational cost of the dithering.
        /// </summary>
        private void DoDithering()
        {
            MaterialProperty useDithering = FindProperty("_DitheringOn");
            if (useDithering == null)
            {
                return;
            }

            _editor.ShaderProperty(useDithering, MakeLabel(useDithering));
            if (useDithering.floatValue == 1)
            {
                EditorGUI.indentLevel += 1;
                MaterialProperty ditheringNoiseScaleSlider = FindProperty("_NoiseScale");
                _editor.ShaderProperty(ditheringNoiseScaleSlider, MakeLabel(ditheringNoiseScaleSlider));
                MaterialProperty mobileDithering = FindProperty("_DitheringMobile");
                _editor.ShaderProperty(mobileDithering, MakeLabel(mobileDithering));
                EditorGUI.indentLevel -= 1;
            }
            
        }

        /// <summary>
        /// Draw the specular occlusion editor.
        /// This is also responsible for setting the SPECULAROCCLUSION_ONshader keyword that control the usage of the
        /// specular occlusion of the lightmap by reducing the lightmaps impact.
        /// </summary>
        private void DoSpecularOcclusion()
        {
            MaterialProperty useSpecularOcclusion = FindProperty("_SpecularOcclusionOn");
            if (useSpecularOcclusion == null)
            {
                return;
            }

            _editor.ShaderProperty(useSpecularOcclusion, MakeLabel(useSpecularOcclusion));
            if (useSpecularOcclusion.floatValue == 1)
            {
                EditorGUI.indentLevel += 1;
                MaterialProperty specularOcclusionSlider = FindProperty("_SpecularLightmapOcclusion");
                _editor.ShaderProperty(specularOcclusionSlider, MakeLabel(specularOcclusionSlider));
                EditorGUI.indentLevel -= 1;
            }
        }

        /// <summary>
        /// Draw the default editors for specular hightlight and glossy reflection.
        /// This is also responsible for setting the _SPECULARHIGHLIGHTS_OFF and _GLOSSYREFLECTIONS_OFF keyword that control the standard
        /// pipeliens usage of specular highlights and metallic glossy reflections of reflection probes (scene or lighting).
        /// </summary>
        private void DoDefaultOptions()
        {
            MaterialProperty highlights = FindProperty("_SpecularHighlights");
            MaterialProperty reflections = FindProperty("_GlossyReflections");

            // Third properties
            GUILayout.Label(_forwardText, EditorStyles.boldLabel);
            if (highlights != null)
            {
                _editor.ShaderProperty(highlights, _highlightsText);
            }

            if (reflections != null)
            {
                _editor.ShaderProperty(reflections, _reflectionsText);
            }
        }

        #region Utility Functionality

        private MaterialProperty FindProperty(string name)
        {
            return FindProperty(name, _properties, false);
        }

        private static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
        {
            StaticLabel.text = property.displayName;
            if (tooltip != null)
            {
                StaticLabel.tooltip = tooltip;
            }
            else
            {
                StaticLabel.tooltip = property.displayName;
            }

            return StaticLabel;
        }

        private void SetKeyword(string keyword, bool state)
        {
            if (state)
            {
                _target.EnableKeyword(keyword);
            }
            else
            {
                _target.DisableKeyword(keyword);
            }
        }

        private bool GetKeyword(string keyword)
        {
            return _target.IsKeywordEnabled(keyword);
        }

        #endregion // Utility Functionality
    }
}