Shader "Custom/ToonShader"
{
    Properties
	{
        [HDR]
		_Color("Color", Color) = (0.5, 0.65, 1, 1)
        [HDR]
        _AmbientColor("Ambient Color", Color) = (0.4, 0.4,0.4,1)
        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32
        [HDR]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0,1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0,1)) = 0.1
		_MainTex("Main Texture", 2D) = "white" {}	
	}
	SubShader
	{
		Pass
		{
            Tags
            {
                "LightMode" = "ForwardBase"
                "PassFlags" = "OnlyDirectional"
            }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _MainTex_ST;
			sampler2D _MainTex;

            float4 _AmbientColor;
            float _Glossiness;
            float4 _SpecularColor;

            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;

			struct appdata
			{
				float4 vertex : POSITION;				
				float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 worldNormal : NORMAL;
                float3 viewDir : TEXCOORD1;
                SHADOW_COORDS(2)
			};
			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                TRANSFER_SHADOW(o)
				return o;
			}
			
			float4 _Color;

			float4 frag (v2f i) : SV_Target
			{
                // USE THE WORLD NORMAL TO COMPARE TO LIGHT'S DIR
                float3 normal = normalize(i.worldNormal);
                // NDOTL RETURNS THE DOT PRODUCT BETWEEN LIGHT NORMAL AND WORLD NORMAL
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                // FOR THE TOON LOOK WE DIVIDE TO EITHER LIGHT AND SHADOW
                float shadow = SHADOW_ATTENUATION(i);// SHADOWS
                float lightIntensity = smoothstep(0,0.01, NdotL * shadow);
                // MULTIPLY INTENSITY WITH DIRECTIONAL LIGHT (_LightColor0 is obtained with the Lighting.cginc)
                float4 light = lightIntensity * _LightColor0;

                // SPECULAR COMPONENT
                float3 viewDir = normalize(i.viewDir);
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;
                
                // RIM LIGHTING
                float4 rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;

				
                float4 sample = tex2D(_MainTex, i.uv);
				
                return (_AmbientColor + light + specular + rim) *  _Color * sample ;
			}
			ENDCG
		}
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}
