Shader "Custom/ToonWater"
{
    Properties
    {
        
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971,
            0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1	
        
        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0,1)) = 0.27
        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0,1)) = 0.777
        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0,0)
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04
        _FoamColor("Foam Color", Color) = (1,1,1,1)

        _TessellationUniform ("Tessellation Uniform", Range(1,64)) = 1
        _MaxCameraDistance ("Max Camera Distance", Range(0,100)) = 50
        _DisplacementStrength("Displacement Strength", Range(0,1)) = 0.1
        _WaveSpeed ("Wave Speed", Float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
			CGPROGRAM
            #define SMOOTHSTEP_AA 0.01
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
          
            #pragma target 4.6

            #include "UnityCG.cginc"
            #include "Tessellation.cginc"

            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthMaxDistance;

            float2 _SurfaceNoiseScroll;
    
            sampler2D _CameraDepthTexture;
            sampler2D _CameraNormalsTexture;
            
            sampler2D _SurfaceNoise;
            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
            float4 _SurfaceDistortionAmount;
            float4 _SurfaceNoise_ST;
            float _SurfaceNoiseCutoff;
            
            float _FoamMaxDistance;
            float _FoamMinDistance;

            float _FoamColor;

            float _TessellationUniform;
            float _MaxCameraDistance;
            float _DisplacementStrength;
            float _WaveSpeed;  
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD2;
                float2 noiseUV : TEXCOORD0;
                float2 distortUV : TEXCOORD1;
                float3 viewNormal : NORMAL;
                float cameraDistance : TEXCOORD3;
            };

            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            float4 alphaBlend(float4 top, float4 bottom)
            {
            	float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
            	float alpha = top.a + bottom.a * (1 - top.a);
            
            	return float4(color, alpha);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

          
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.screenPosition = o.vertex;
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                o.viewNormal = COMPUTE_VIEW_NORMAL;
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.cameraDistance = distance(worldPos, _WorldSpaceCameraPos);
                return o;
            }
            float4 frag (v2f i) : SV_Target
            {
                float existingDepth01 = tex2Dproj(_CameraDepthTexture,
                    UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);

                float depthDifference = existingDepthLinear - i.screenPosition.w;
                
                float waterDepthDifference01 = saturate(depthDifference/_DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep,
                    waterDepthDifference01);
                
                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPosition));
                float3 normalDot = saturate(dot(existingNormal, i.viewNormal));

                float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);
                float foamDepthDifference01 = saturate(depthDifference / foamDistance);


                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;

                float2 distortSample = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;

                float2 noiseUV = float2((i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x, (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y) + distortSample.y);

                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA,
                    surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
                float4 surfaceNoiseColor = _FoamColor * surfaceNoise;
                surfaceNoiseColor.a *= surfaceNoise;

                
                return alphaBlend(surfaceNoise, waterColor);
                

            }

            TessellationFactors patchConstantFunction(InputPatch<v2f,3> patch)
            {
                TessellationFactors f;

                float tessClose = _TessellationUniform * 4.0;
                float tessFar = _TessellationUniform * 0.1;

                float distance01 = saturate(patch[0].cameraDistance / _MaxCameraDistance);
                float tessLevel = lerp(tessClose, tessFar, distance01);
                
                f.edge[0] = tessLevel;

                f.edge[1] = tessLevel;

                f.edge[2] = tessLevel;

                f.inside = tessLevel;
                
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("patchConstantFunction")]
            v2f hull (InputPatch<v2f,3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }
            v2f tessVert(v2f v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.noiseUV = v.noiseUV;
                o.distortUV = v.distortUV;
                o.viewNormal = v.viewNormal;
                return o;
            }
            [UNITY_domain("tri")]
            v2f domain(TessellationFactors factors, OutputPatch<v2f,3> patch,
                float3 barycentricCoordinates : SV_DomainLocation)
            {
                v2f v;
                
              

                #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
                    patch[0].fieldName * barycentricCoordinates.x + \
                    patch[1].fieldName * barycentricCoordinates.y + \
                    patch[2].fieldName * barycentricCoordinates.z;

                MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
                MY_DOMAIN_PROGRAM_INTERPOLATE(screenPosition)
                MY_DOMAIN_PROGRAM_INTERPOLATE(noiseUV)
                MY_DOMAIN_PROGRAM_INTERPOLATE(distortUV)
                MY_DOMAIN_PROGRAM_INTERPOLATE(viewNormal)
    
                /* 
                float2 uv = v.noiseUV + _Time.y * _WaveSpeed * 0.05;
                float displacement = tex2Dlod(_SurfaceNoise, float4(uv,0,0)).r;
                v.vertex.y += displacement * _DisplacementStrength; */
                   float2 uv = v.noiseUV + _Time.y * _WaveSpeed * 0.05;
                float displacement = tex2Dlod(_SurfaceDistortion, float4(uv,0,0)).r;
                v.vertex.xyz += v.viewNormal * displacement * _DisplacementStrength;  

                return tessVert(v);
            }
            
           
            ENDCG
        }
    }
}