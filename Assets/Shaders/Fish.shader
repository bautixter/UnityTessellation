Shader "Custom/FishShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB) Alpha (A)", 2D) = "white" {}
        _SwimSpeed ("Swim Speed", Float) = 2.0
        _TailMaxAngle ("Tail Max Angle", Range(0, 90)) = 45.0
        _Height ("Height", Float) = 1.0
        _Length ("Length", Float) = 0.5
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
            float _SwimSpeed;
            float _TailMaxAngle;
            float _Height;
            float _Length;
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
                float swimSpeed = _SwimSpeed * 0.5;
                float flapAngle = sin(_Time.y * _SwimSpeed) * radians(_TailMaxAngle);

                // Obtener direcciones y puntos
                float3 forward = float3(0, 0, 1);
                float3 up = float3(0, 1, 0);
                float3 right = float3(1, 0, 0);

                float3 front  = forward * _Length * 0.5;
                float3 back   = -front;
                float3 top    = up * _Height * 0.5;
                float3 bottom = -top;
                
                float4x4 bodyRot = rotateAroundAxis(up, flapAngle * 0.5);
                float4x4 tailRot = rotateAroundAxis(up, -flapAngle);

                // Emit body triangles
                g2f o;
                
                o.pos = UnityObjectToClipPos(input[0].vertex + top);
                o.uv = float2(0.7, 1.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bottom);
                o.uv = float2(0.7, 0.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + mul(bodyRot, top + front));
                o.uv = float2(0.0, 1.0);
                o.normal = right;
                triStream.Append(o);
                
                triStream.RestartStrip();
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bottom);
                o.uv = float2(0.7, 0.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + mul(bodyRot, bottom + front));
                o.uv = float2(0.0, 0.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + mul(bodyRot, top + front));
                o.uv = float2(0.0, 1.0);
                o.normal = right;
                triStream.Append(o);
                
                triStream.RestartStrip();

                // Emit tail triangles
                o.pos = UnityObjectToClipPos(input[0].vertex + top);
                o.uv = float2(0.7, 1.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bottom);
                o.uv = float2(0.7, 0.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + mul(tailRot, top + back));
                o.uv = float2(1.0, 1.0);
                o.normal = right;
                triStream.Append(o);
                
                triStream.RestartStrip();
                
                o.pos = UnityObjectToClipPos(input[0].vertex + bottom);
                o.uv = float2(0.7, 0.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + mul(tailRot, bottom + back));
                o.uv = float2(1.0, 0.0);
                o.normal = right;
                triStream.Append(o);
                
                o.pos = UnityObjectToClipPos(input[0].vertex + mul(tailRot, top + back));
                o.uv = float2(1.0, 1.0);
                o.normal = right;
                triStream.Append(o);
                
                triStream.RestartStrip();
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