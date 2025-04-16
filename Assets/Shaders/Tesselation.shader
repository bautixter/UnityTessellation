Shader "Custom/OceanTessellation" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _DisplacementMap ("Displacement Map", 2D) = "gray" {}
        _DisplacementStrength ("Displacement Strength", Range(0, 1)) = 0.1
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _WaveSpeed ("Wave Speed", Float) = 1.0
        _Wireframe ("Wireframe", Float) = 0.0
    }
    
    SubShader {
        Tags { "RenderType"="Opaque" }
        
        CGPROGRAM
        #pragma surface surf Standard tessellate:tess vertex:vert
        #pragma target 4.6
        
        #include "Tessellation.cginc"

        struct appdata {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input {
            float2 uv_MainTex;
        };

        sampler2D _MainTex, _DisplacementMap;
        float _DisplacementStrength, _TessellationUniform, _WaveSpeed;
        float _Wireframe;
        fixed4 _Color;

        // Función de tessellation
        float4 tess() {
            return _TessellationUniform;
        }

        // Vertex shader que aplica el displacement
        void vert(inout appdata v) {
            // Mover el UV para animación de olas
            float2 uv = v.texcoord + _Time.y * _WaveSpeed * 0.05;
            
            // Obtener desplazamiento desde el mapa
            float displacement = tex2Dlod(_DisplacementMap, float4(uv, 0, 0)).r;
            
            // Aplicar desplazamiento
            v.vertex.xyz += v.normal * displacement * _DisplacementStrength;
        }

        // Surface shader
        void surf (Input IN, inout SurfaceOutputStandard o) {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            
            // Visualización wireframe
            if (_Wireframe > 0.5) {
                o.Albedo = float3(0,0,0);
                o.Emission = float3(1,1,1) - o.Albedo;
            }
        }
        ENDCG
    }
    FallBack "Standard"
}