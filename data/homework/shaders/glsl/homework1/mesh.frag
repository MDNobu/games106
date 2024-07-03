#version 450

#include "common.glsl"

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


// layout (set = 1, binding = 0) uniform sampler2D samplerColorMap;
layout (set = 1, binding = 1) uniform MaterialUniform
{
	float metallic;
	float roughness;
	float specular; // 这个是一个简化管线未必有的
	float padding;
} materialUniform;

layout (set = 4, binding = 2) uniform sampler2D samplerColorMap;

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
	vec3 V = normalize(inViewVec);
	vec3 R = reflect(L, N);
	// vec3 diffuse = max(dot(N, L), 0.15) * inColor;
	// vec3 specular = pow(max(dot(R, V), 0.0), 16.0) * vec3(0.75);
	
	// outFragColor = vec4(diffuse * color.rgb + specular, 1.0);
	// outFragColor = 	Test();	

	vec3 lightColor = uboScene.lightColorIntensity.rgb;
	float metallic = materialUniform.metallic;
	float roughness = materialUniform.roughness;
	

	vec3 directShading = SurfaceShading(N, V, L, baseColor.rgb, lightColor, metallic, roughness);


	// 先实现单光源，直接光
	outFragColor = vec4(directShading, 1.0);
}