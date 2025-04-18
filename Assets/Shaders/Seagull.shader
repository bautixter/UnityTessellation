Shader "Custom/SeagullGeometryShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB) Alpha (A)", 2D) = "white" {}
        _WingFlapSpeed ("Wing Flap Speed", Float) = 2.0
        _WingFlapAmount ("Wing Flap Amount", Range(0, 90)) = 45.0
        _Size ("Size", Float) = 1.0
        _BodySize ("Body Size", Float) = 0.5
        _BodyWidth ("Body Width", Float) = 0.3
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
    }
    
    SubShader
    {
        Tags { 
            "RenderType"="TransparentCutout"
            "Queue"="AlphaTest"
            "IgnoreProjector"="True"
        }
        LOD 200
        
        Pass
        {
            Cull Off // Desactivar culling para ver ambos lados

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            /******************************************/
            /*          TYPES AND VARIABLES           */
            /******************************************/

            struct appdata
            {
                float4 vertex : POSITION;
            };
            
            struct v2g
            {
                float4 vertex : POSITION;
            };
            
            struct g2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
            
            sampler2D _MainTex;
            float _WingFlapSpeed;
            float _WingFlapAmount;
            float _Size;
            float _BodySize;
            float _BodyWidth;
            float _Cutoff;
            
            /******************************************/
            /*             AUX FUNCTIONS              */
            /******************************************/

            float4x4 rotateAroundAxis(float3 axis, float angle)
            {
                float c = cos(angle);
                float s = sin(angle);
                float t = 1 - c;
                
                return float4x4(
                    t * axis.x * axis.x + c,          t * axis.x * axis.y - s * axis.z, t * axis.x * axis.z + s * axis.y, 0,
                    t * axis.x * axis.y + s * axis.z, t * axis.y * axis.y + c,          t * axis.y * axis.z - s * axis.x, 0,
                    t * axis.x * axis.z - s * axis.y, t * axis.y * axis.z + s * axis.x, t * axis.z * axis.z + c,          0,
                    0,                                0,                                0,                                1
                );
            }

            /******************************************/
            /*             PIPELINE STAGES            */
            /******************************************/
            
            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                return o;
            }
            
            [maxvertexcount(12)]
            void geom(point v2g input[1], inout TriangleStream<g2f> triStream)
            {
                float flapAngle = sin(_Time.y * _WingFlapSpeed) * radians(_WingFlapAmount);
                
                // Obtener direcciones
                float3 forward = normalize(UnityObjectToWorldDir(float3(0, 0, 1)));
                float3 up = normalize(UnityObjectToWorldDir(float3(0, 1, 0)));
                float3 right = cross(forward, up);
                
                // Tamaños
                float wingLength = _Size * 0.6;
                float bodyLength = _Size * _BodySize;
                float bodyWidth = _BodyWidth;
                
                // Vértices de las alas
                float3 leftWingTip = -right * wingLength;
                leftWingTip = mul(rotateAroundAxis(forward, flapAngle), leftWingTip);
                
                float3 rightWingTip = right * wingLength;
                rightWingTip = mul(rotateAroundAxis(forward, -flapAngle), rightWingTip);
                
                // Vértices del cuerpo
                float3 bodyFront = forward * bodyLength * 0.5;
                float3 bodyBack = -forward * bodyLength * 0.5;

                float3 bodyLF = forward * bodyLength * 0.5 + -right * bodyWidth;
                float3 bodyLB = -forward * bodyLength * 0.5 + -right * bodyWidth;
                float3 bodyRF = forward * bodyLength * 0.5 + right * bodyWidth;
                float3 bodyRB = -forward * bodyLength * 0.5 + right * bodyWidth;

                g2f o;
                
                // Ala izquierda (triángulo)
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyLF);
                o.uv = float2(0.44, 0.8);
                o.normal = up;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + leftWingTip);
                o.uv = float2(0.0, 0.5);
                o.normal = up;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyLB);
                o.uv = float2(0.44, 0.0);
                o.normal = up;
                triStream.Append(o);
                
                triStream.RestartStrip();
                
                // Ala derecha (triángulo)
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyRF);
                o.uv = float2(0.56, 0.8);
                o.normal = up;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + rightWingTip);
                o.uv = float2(1.0, 0.5);
                o.normal = up;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyRB);
                o.uv = float2(0.56, 0.0);
                o.normal = up;
                triStream.Append(o);
                
                triStream.RestartStrip();
                
                // Cuerpo (quad - dos triángulos)
                // Esquina izquierda
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyLF);
                o.uv = float2(0.45, 1);
                o.normal = forward;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyLB);
                o.uv = float2(0.45, 0.0);
                o.normal = forward;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyRF);
                o.uv = float2(0.55, 1);
                o.normal = forward;
                triStream.Append(o);
                
                triStream.RestartStrip();

                // Esquina derecha
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyRF);
                o.uv = float2(0.55, 1.0);
                o.normal = forward;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyRB);
                o.uv = float2(0.55, 0.0);
                o.normal = forward;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bodyLB);
                o.uv = float2(0.48, 0.0);
                o.normal = forward;
                triStream.Append(o);
            }
            
            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                if (col.a < _Cutoff) discard;
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}