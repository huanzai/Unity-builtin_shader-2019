// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Standard"
{
    Properties
    {
        // albedo = _Color.rgb * tex2D(_MainTex, uv).rgb;
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        // frag 做 alpha 测试，小于 0.5 的像素被丢弃
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // 光滑度 + 金属度
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        // 是否显示直接光高光效果
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        // 是否显示间接光高光效果
        [ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

        // 法线贴图
        _BumpScale("Scale", Float) = 1.0
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}

        // 高度图(存放在 g 值)和缩放系数
        _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" {}

        // 遮挡系数+遮挡纹理 occlusion 的范围 (occ ~ 1.0) 通过 _OcclusionStrength 调整
        // 作用于间接光（IBL）的漫反射和高光部分
        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

        // 自发光 = tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb
        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        // 一同作用于 Albedo 
        _DetailMask("Detail Mask", 2D) = "white" {}
        _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}

        // 作用于 normal
        _DetailNormalMapScale("Scale", Float) = 1.0
        [Normal] _DetailNormalMap("Normal Map", 2D) = "bump" {}

        // 用于判断 detail albedo 和 detail normal 使用 uv0 还是 uv1
        [Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0

        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 300


        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature_local _PARALLAXMAP

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------


            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature_local _PARALLAXMAP

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------


            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _PARALLAXMAP
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Deferred pass
        Pass
        {
            Name "DEFERRED"
            Tags { "LightMode" = "Deferred" }

            CGPROGRAM
            #pragma target 3.0
            #pragma exclude_renderers nomrt


            // -------------------------------------

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature_local _PARALLAXMAP

            #pragma multi_compile_prepassfinal
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertDeferred
            #pragma fragment fragDeferred

            #include "UnityStandardCore.cginc"

            ENDCG
        }

        // ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"
            ENDCG
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 150

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _GLOSSYREFLECTIONS_OFF
            // SM2.0: NOT SUPPORTED shader_feature_local _DETAIL_MULX2
            // SM2.0: NOT SUPPORTED shader_feature_local _PARALLAXMAP

            #pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local _DETAIL_MULX2
            // SM2.0: NOT SUPPORTED shader_feature_local _PARALLAXMAP
            #pragma skip_variants SHADOWS_SOFT

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }

        // ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"
            ENDCG
        }
    }


    FallBack "VertexLit"
    CustomEditor "StandardShaderGUI"
}
