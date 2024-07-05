#version 450

// #include "common.glsl"
#include "common3.glsl"


// // #TODO 先实现方向光
// layout (set = 3,  binding = 0) uniform LightUniform
// {
// 	vec4 worldDirection;
// 	vec4 colorIntensity; // 颜色和强度
// } lightUniform;

layout (set = 0, binding = 0) uniform UBOScene
{
	mat4 projection;
	mat4 view;
	vec4 lightPos;
	vec4 viewPos;
	vec4 lightColorIntensity;
} uboScene;




// 先用pushconstants实现一版
layout (push_constant) uniform MaterialUniform
{
	float metallic;
	float roughness;
	float specular; // 这个是一个简化管线未必有的
	float padding;
} materialUniform;

// layout (set = 1, binding = 0) uniform sampler2D samplerColorMap;
//layout (set = 1, binding = 1) uniform MaterialUniform
//{
//	float metallic;
//	float roughness;
//	float specular; // 这个是一个简化管线未必有的
//	float padding;
//} materialUniform;

layout (set = 2, binding = 1) uniform sampler2D samplerColorMap;

layout (location = 0) in vec3 inNormal;
layout (location = 1) in vec3 inColor;
layout (location = 2) in vec2 inUV;
layout (location = 3) in vec3 inViewVec;
layout (location = 4) in vec3 inLightVec;

layout (location = 0) out vec4 outFragColor;

void main() 
{
	vec4 baseColor = texture(samplerColorMap, inUV) * vec4(inColor, 1.0);

	// #TODO 加上法线贴图之后N/L/V的计算需要移动到fragment shader中实现
	vec3 N = normalize(inNormal);
	vec3 L = normalize(inLightVec);
	// L = normalize(vec3(1, 100, 100));
	vec3 V = normalize(inViewVec);
	vec3 R = reflect(L, N);
	vec3 diffuse = max(dot(N, L), 0.0) * baseColor.rgb;
	vec3 specular = pow(max(dot(R, V), 0.0), 16.0) * vec3(0.75);
	
	// outFragColor = vec4(diffuse * baseColor.rgb + specular, 1.0);
	// outFragColor = 	Test();	

	// vec4 lightColorIntensity = vec4(uboScene.lightColorIntensity.rgb, 3.0);
	vec4 lightColorIntensity = uboScene.lightColorIntensity;

	float metallic = materialUniform.metallic;
	float roughness = materialUniform.roughness;
	
	// metallic = 0.0;
	// roughness = 0.5;
	roughness = 0;
	metallic = 0;
	// baseColor.rgb = vec3(1, 0, 0);
	vec3 directShading = SurfaceShading(N, V, L, baseColor.rgb, lightColorIntensity, metallic, roughness);


	// directShading = lightColor;
	// 先实现单光源，直接光
	outFragColor = vec4(directShading, 1.0);
	// outFragColor = vec4(diffuse.rgb, 1.0);
}