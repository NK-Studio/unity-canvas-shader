Shader "UGUI Canvas/HDR"
{
    Properties
    {
        [MainTexture][NoScaleOffset]_MainTex("MainTex", 2D) = "white" {}
        [HDR]_BaseColor("BaseColor", Color) = (0, 0, 0, 1)
        [HideInInspector]_StencilComp("Stencil Comparison", Float) = 8
        [HideInInspector]_Stencil("Stencil ID", Float) = 0
        [HideInInspector]_StencilOp("Stencil Operation", Float) = 0
        [HideInInspector]_StencilWriteMask("Stencil Write Mask", Float) = 255
        [HideInInspector]_StencilReadMask("Stencil Read Mask", Float) = 255
        [HideInInspector]_ColorMask("ColorMask", Float) = 15
        [HideInInspector]_ClipRect("ClipRect", Vector, 4) = (0, 0, 0, 0)
        [HideInInspector]_UIMaskSoftnessX("UIMaskSoftnessX", Float) = 1
        [HideInInspector]_UIMaskSoftnessY("UIMaskSoftnessY", Float) = 1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
            // DisableBatching: <None>
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
        Pass
        {
            Name "Default"
            Tags
            {
                // LightMode: <None>
            }

            // Render State
            Cull Off
            Blend One OneMinusSrcAlpha
            ZTest [unity_GUIZTestMode]
            ZWrite Off
            ColorMask [_ColorMask]
            Stencil
            {
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Ref [_Stencil]
                CompFront [_StencilComp]
                PassFront [_StencilOp]
                CompBack [_StencilComp]
                PassBack [_StencilOp]
            }

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM
            // Pragmas
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            // Keywords
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            // GraphKeywords: <None>

            #define CANVAS_SHADERGRAPH

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_COLOR
            #define ATTRIBUTES_NEED_VERTEXID
            #define ATTRIBUTES_NEED_INSTANCEID
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TEXCOORD1
            #define VARYINGS_NEED_COLOR

            #define REQUIRE_DEPTH_TEXTURE
            #define REQUIRE_NORMAL_TEXTURE

            #define SHADERPASS SHADERPASS_CUSTOM_UI
            #define _DISABLE_COLOR_TINT 1

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

            // --------------------------------------------------
            // Structs and Packing


            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
                uint instanceID : INSTANCEID_SEMANTIC;
                #endif
                uint vertexID : VERTEXID_SEMANTIC;
            };

            struct SurfaceDescriptionInputs
            {
                float4 uv0;
                float4 VertexColor;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS;
                float3 normalWS;
                float4 texCoord0;
                float4 texCoord1;
                float4 color;
                #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
            };
            
            struct PackedVaryings
            {
                float4 positionCS : SV_POSITION;
                float4 texCoord0 : INTERP0;
                float4 texCoord1 : INTERP1;
                float4 color : INTERP2;
                float3 positionWS : INTERP3;
                float3 normalWS : INTERP4;
                #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
                uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
            };

            PackedVaryings PackVaryings(Varyings input)
            {
                PackedVaryings output;
                ZERO_INITIALIZE(PackedVaryings, output);
                output.positionCS = input.positionCS;
                output.texCoord0.xyzw = input.texCoord0;
                output.texCoord1.xyzw = input.texCoord1;
                output.color.xyzw = input.color;
                output.positionWS.xyz = input.positionWS;
                output.normalWS.xyz = input.normalWS;
                #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
                output.instanceID = input.instanceID;
                #endif
                return output;
            }

            Varyings UnpackVaryings(PackedVaryings input)
            {
                Varyings output;
                output.positionCS = input.positionCS;
                output.texCoord0 = input.texCoord0.xyzw;
                output.texCoord1 = input.texCoord1.xyzw;
                output.color = input.color.xyzw;
                output.positionWS = input.positionWS.xyz;
                output.normalWS = input.normalWS.xyz;
                #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
                output.instanceID = input.instanceID;
                #endif
                return output;
            }


            // -- Property used by ScenePickingPass
            #ifdef SCENEPICKINGPASS
            float4 _SelectionID;
            #endif

            // -- Properties used by SceneSelectionPass
            #ifdef SCENESELECTIONPASS
            int _ObjectId;
            int _PassValue;
            #endif

            //UGUI has no keyword for when a renderer has "bloom", so its nessecary to hardcore it here, like all the base UI shaders.
            half4 _TextureSampleAdd;

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_TexelSize;
                float4 _BaseColor;
                float _Stencil;
                float _StencilOp;
                float _StencilWriteMask;
                float _StencilReadMask;
                float _ColorMask;
                float4 _ClipRect;
                float _UIMaskSoftnessX;
                float _UIMaskSoftnessY;
                UNITY_TEXTURE_STREAMING_DEBUG_VARS;
            CBUFFER_END
            
            // Object and Global properties
            SAMPLER(SamplerState_Linear_Repeat);
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            struct Bindings_CanvasColor_74f647076bca3d442bc4a6ace5daf59f_float
            {
                float4 VertexColor;
            };
 
            // Graph Pixel
            struct SurfaceDescription
            {
                float3 BaseColor;
                float Alpha;
                float3 Emission;
            };

            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                
                surface.BaseColor = float3(1, 1, 1);
                surface.Alpha = 1;
                surface.Emission = (_BaseColor.xyz);
                return surface;
            }
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
                
                output.uv0 = input.texCoord0;
                output.VertexColor = input.color;
                
                return output;
            }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/CanvasPass.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Shader Graph/FallbackError"
}