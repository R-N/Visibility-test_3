// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/My Multiply Shader" {
Properties {
_Color ("Color", color) = (1,1,1,1)
	_MainTex ("Particle Texture", 2D) = "white" {}
}

Category {
	Tags { "Queue"="Geometry+50" "RenderType"="Transparent" }
	Blend One OneMinusSrcAlpha
	Cull Off Lighting Off ZWrite Off
	
	SubShader {
		Pass {
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_particles
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _MainTex;
sampler2D_half _PersDepthTex;
half4x4 _XRAMatrix2;
half4x4 _WorldToPersCam;
half4 _PersCamPos;
half4 _PersCamFwdXZ;
half4 _Color;
half tolerance;
			
			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 worldPosX : WORLD_POSITION;
			};
			
			float4 _MainTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.worldPosX = mul(unity_ObjectToWorld, float4(v.vertex.xyz * 0.9995f, v.vertex.w));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{




	half4 D = mul(_WorldToPersCam, i.worldPosX);
	D = D / D.w;

	half myDot2 = dot (_PersCamFwdXZ.xz, i.worldPosX.xz - _PersCamPos.xz);

	half4 newUV = half4(clamp(D.xy * 0.5 + 0.5, 0.0, 1.0), 0, 0);
	half XRAdepth2 = dot(tex2Dlod(_PersDepthTex, newUV), half4(1.0, 1/255.0, 1/65025.0, 1/16581375.0));

	#if defined(SHADER_API_OPENGL)
	half4 XRAH2 = half4(newUV.x * 2.0 - 1.0, newUV.y * 2.0 - 1.0, XRAdepth2 * 2.0 - 1.0, 1.0);
	#else
	half4 XRAH2 = half4(newUV.x * 2.0 - 1.0, newUV.y * 2.0 - 1.0, XRAdepth2, 1.0);
	#endif

	half4 XRAD2 = mul(_XRAMatrix2, XRAH2);

	half4 worldPos2 = XRAD2 / XRAD2.w;
	half distReal = distance(_PersCamPos.xyz, i.worldPosX.xyz);
	half distReal2 = distance(_PersCamPos.xyz, worldPos2.xyz);

	half dist2D = distance(_PersCamPos.xz, i.worldPosX.xz);
	half ret = ceil(clamp(myDot2, 0, 1)) *(1 - ceil(clamp(abs(D.x) - 1, 0, 1))) * (1 - clamp(distReal - distReal2 - tolerance , 0, 1)) *  (1 - clamp(dist2D - 10, 0, 10) * 0.1);
	half ret2 = (1 - clamp(distReal - 2.5, 0, 5) * 0.2) * (1 - clamp(abs(i.worldPosX.y - _PersCamPos.y) - 2.5, 0, 2.5) * 0.4);
	half alphaMultiplier = clamp(ret + ret2, 0, 1);




				
				half4 prev = i.color * tex2D(_MainTex, i.texcoord) * _Color;
				prev = float4(prev.rgb * 1.5 * ret, prev.a * alphaMultiplier);
				return prev;
			}
			ENDCG 
		}
	}
}
}
