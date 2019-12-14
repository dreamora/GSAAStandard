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
            if (DoNormal())
            {
                DoSpecularOcclusion();
            }

            EditorGUILayout.Space();
            DoPBR();

            EditorGUILayout.Space();
            DoEmission();

            EditorGUILayout.Space();
            DoDithering();

            EditorGUILayout.Space();
            DoDefaultOptions();
        }

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

        private bool DoNormal()
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

            return hasNormal;
        }

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
                EditorGUI.indentLevel -= 1;
            }
        }

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