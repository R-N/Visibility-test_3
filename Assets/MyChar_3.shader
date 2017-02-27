// Derived from diffuse shader
// Linearch

Shader "Custom/My Char Shader Vert" {
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
sampler2D_float _PersDepthTex;
float4x4 _XRAMatrix2;
float4x4 _WorldToPersCam;
float4 _PersCamPos;
float4 _PersCamFwdXZ;
float4 _Color;
float tolerance;

struct Input {
	float2 uv_MainTex;
	float ret;
	float alphaMultiplier;
};

void vert (inout appdata_base v, out Input o){

    UNITY_INITIALIZE_OUTPUT(Input,o);

	float4 worldPosX = mul(_Object2World, float4(v.vertex.xyz * 0.965f, v.vertex.w));



	float4 D = mul(_WorldToPersCam, worldPosX);
	D = D / D.w;

	float myDot2 = dot (_PersCamFwdXZ.xz, worldPosX.xz - _PersCamPos.xz);

	float4 newUV = float4(clamp(D.xy * 0.5 + 0.5, 0.0, 1.0), 0, 0);
	float XRAdepth2 = dot(tex2Dlod(_PersDepthTex, newUV), float4(1.0, 1/255.0, 1/65025.0, 1/16581375.0));

	#if defined(SHADER_API_OPENGL)
	float4 XRAH2 = float4(newUV.x * 2.0 - 1.0, newUV.y * 2.0 - 1.0, XRAdepth2 * 2.0 - 1.0, 1.0);
	#else
	float4 XRAH2 = float4(newUV.x * 2.0 - 1.0, newUV.y * 2.0 - 1.0, XRAdepth2, 1.0);
	#endif

	float4 XRAD2 = mul(_XRAMatrix2, XRAH2);

	float4 worldPos2 = XRAD2 / XRAD2.w;
	float distReal = distance(_PersCamPos.xyz, worldPosX.xyz);
	float distReal2 = distance(_PersCamPos.xyz, worldPos2.xyz);

	float dist2D = distance(_PersCamPos.xz, worldPosX.xz);
	o.ret = ceil(clamp(myDot2, 0, 1)) *(1 - ceil(clamp(abs(D.x) - 1, 0, 1))) * (1 - clamp(distReal - distReal2 - tolerance , 0, 1)) *  (1 - clamp(dist2D - 10, 0, 10) * 0.1);

	o.alphaMultiplier = clamp(o.ret + (1 - clamp(distReal - 2.5, 0, 5) * 0.2) * (1 - clamp(abs(worldPosX.y - _PersCamPos.y) - 2.5, 0, 2.5) * 0.4) - 0.5 * frac(abs(sin(dot(v.vertex.xyz, float3(12.9898, 78.233, 45.5432)))) * 43758.5453), 0, 1);


}

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
	o.Emission = c.rgb * _Color.rgb * IN.ret;

	o.Alpha = c.a * IN.alphaMultiplier * _Color.a;
}
ENDCG
}

Fallback "Mobile/VertexLit"
}
