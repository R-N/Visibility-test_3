// Derived from diffuse shader
// Linearch

Shader "Custom/My Char Shader" {
Properties {
	_Color("Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
}
SubShader {
	Tags { "RenderType"="Transparent" "Queue" = "Geometry+100"}
	LOD 200
	Blend One OneMinusSrcAlpha
	ColorMask RGBA
	Pass{
	ZWrite On
	ColorMask 0
	}
CGPROGRAM
#pragma surface surf Lambert nolightmap noforwardadd vertex:vert keepalpha alpha

sampler2D _MainTex;
sampler2D_half _PersDepthTex;
half4x4 _XRAMatrix2;
half4x4 _WorldToPersCam;
half4 _PersCamPos;
half4 _PersCamFwdXZ;
half4 _Color;
half tolerance;

struct Input {
	float2 uv_MainTex;
	float4 worldPosX;
	float noise;
};

void vert (inout appdata_base v, out Input o){

    UNITY_INITIALIZE_OUTPUT(Input,o);

	o.worldPosX = mul(_Object2World, float4(v.vertex.xyz * 0.965f, v.vertex.w));
	o.noise = 0.5 * frac(abs(sin(dot(v.vertex.xyz, float3(12.9898, 78.233, 45.5432)))) * 43758.5453);
}

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);

	half4 D = mul(_WorldToPersCam, IN.worldPosX);
	D = D / D.w;

	half myDot2 = dot (_PersCamFwdXZ.xz, IN.worldPosX.xz - _PersCamPos.xz);

	half4 newUV = half4(clamp(D.xy * 0.5 + 0.5, 0.0, 1.0), 0, 0);
	half XRAdepth2 = dot(tex2Dlod(_PersDepthTex, newUV), half4(1.0, 1/255.0, 1/65025.0, 1/16581375.0));

	#if defined(SHADER_API_OPENGL)
	half4 XRAH2 = half4(newUV.x * 2.0 - 1.0, newUV.y * 2.0 - 1.0, XRAdepth2 * 2.0 - 1.0, 1.0);
	#else
	half4 XRAH2 = half4(newUV.x * 2.0 - 1.0, newUV.y * 2.0 - 1.0, XRAdepth2, 1.0);
	#endif

	half4 XRAD2 = mul(_XRAMatrix2, XRAH2);

	half4 worldPos2 = XRAD2 / XRAD2.w;
	half distReal = distance(_PersCamPos.xyz, IN.worldPosX.xyz);
	half distReal2 = distance(_PersCamPos.xyz, worldPos2.xyz);

	half dist2D = distance(_PersCamPos.xz, IN.worldPosX.xz);
	half ret = ceil(clamp(myDot2, 0, 1)) *(1 - ceil(clamp(abs(D.x) - 1, 0, 1))) * (1 - clamp(distReal - distReal2 - tolerance , 0, 1)) *  (1 - clamp(dist2D - 10, 0, 10) * 0.1);

	half alphaMultiplier = clamp(ret + (1 - clamp(distReal - 2.5, 0, 5) * 0.2) * (1 - clamp(abs(IN.worldPosX.y - _PersCamPos.y) - 2.5, 0, 2.5) * 0.4) - IN.noise, 0, 1);

	o.Emission = c.rgb * _Color.rgb * ret;

	o.Alpha = c.a * alphaMultiplier * _Color.a;
}
ENDCG
}

Fallback "Mobile/VertexLit"
}
