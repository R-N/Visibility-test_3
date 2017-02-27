// Simplified Diffuse shader. Differences from regular Diffuse one:
// - no Main Color
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "Custom/My Diffuse Shader" {
Properties {
	_Color("Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
}
SubShader {
	Tags { "RenderType"="Opaque"}
	LOD 200

CGPROGRAM
#pragma surface surf Lambert nolightmap noforwardadd vertex:vert

sampler2D _MainTex;
sampler2D_half _PersDepthTex;
half4x4 _XRAMatrix2;
half4x4 _WorldToPersCam;
half4 _PersCamPos;
half4 _PersCamFwdXZ;
half4 _Color;
half4 _PlyrColor;
half tolerance;

struct Input {
	float2 uv_MainTex;
	float4 worldPosX;
};

void vert (inout appdata_base v, out Input o){

    UNITY_INITIALIZE_OUTPUT(Input,o);

	o.worldPosX = mul(_Object2World, v.vertex);

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
	half deltaY = IN.worldPosX.y - _PersCamPos.y;
	half alphaMultiplier = clamp(ret + (1 - clamp(distReal - 2.5, 0, 5) * 0.2) * (1 - clamp(abs(deltaY) - 2.5, 0, 2.5) * 0.4), 0, 1);

	half yClamp = 0.25 * clamp(deltaY * 0.125, 0, 1);



	o.Albedo = c.rgb * _Color.rgb * yClamp + c.rgb * _PlyrColor * alphaMultiplier * 0.75;
}
ENDCG
}

Fallback "Mobile/VertexLit"
}
