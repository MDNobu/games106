
#define saturate(x)        clamp(x, 0.0, 1.0)

const float PI = 3.14159265359;

struct PixelParams
{
    vec3 diffuseColor;
    vec3 specularColor;
    float perceptualRoughness; // 这个是外部输入的更接近，感知上更接近线性的，实际渲染时需要用的需要需要映射到roughness
    float roughness;
};

struct BxDFContext
{
    float NoV;
    float NoL;
    float VoL;
    float NoH;
    float VoH;
};

void InitContext(inout BxDFContext context, vec3 N, vec3 V, vec3 L )
{
    vec3 H =normalize(V + L);
    context.NoV = saturate(dot(N, V));;
    context.NoL = saturate(dot(N, L));;
    context.VoL = saturate(dot(V, L));
    context.NoH = saturate(dot(N, H));
    context.VoH = saturate(dot(V, H));
}

float PerceptualRoughnessToRoughness(float perceptualRoughness)
{
    return perceptualRoughness * perceptualRoughness;
}

//------------------------------------------------------------------------------
// Diffuse BRDF implementations
//------------------------------------------------------------------------------

float Fd_Lambert() {
    return 1.0 / PI;
}

vec3 Diffuse_Lambert(vec3 diffuseColor)
{
    return diffuseColor * (1/ PI);
}

// float Fd_Burley(float roughness, float NoV, float NoL, float LoH) {
//     // Burley 2012, "Physically-Based Shading at Disney"
//     float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
//     float lightScatter = F_Schlick(1.0, f90, NoL);
//     float viewScatter  = F_Schlick(1.0, f90, NoV);
//     return lightScatter * viewScatter * (1.0 / PI);
// }

float diffuseBRDF(float roughness, float NoV, float NoL, float LoH)
{
    // diffuse 计算方法常用的有2种 lambert和 burley，先用lambert
    return Fd_Lambert();
}

vec3 diffuseLobe(const PixelParams pixel, float NoV, float NoL, float LoH)
{
    return pixel.diffuseColor * diffuseBRDF(pixel.roughness, NoV, NoL, LoH);
}

vec3 computeDiffuseColor(const vec3 baseColor, float metallic)
{
    return baseColor * (1.0 - metallic);
}

// 这里specular的典型输入是0.04
float dielectricSpecularToF0(float specular)
{
    return 0.08f * specular;
}

vec3 computeF0(float specular, vec3 baseColor, float metallic)
{
    return mix(dielectricSpecularToF0(specular).xxx, baseColor, metallic);
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
float D_GGX( float a2, float NoH )
{
	float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
	return a2 / ( PI*d*d );					// 4 mul, 1 rcp
}



vec3 SpecularGGX(float roughness, float specularColor, BxDFContext context)
{
    
}

vec3 SurfaceShading(vec3 N,  vec3 V, vec3 L,
    vec3 baseColor, vec4 lightColorIntensity, float metallic, float perceptualRoughness
    )
{
    BxDFContext context;
    InitContext(context, N, V, L);
    PixelParams pixel;
    pixel.perceptualRoughness = perceptualRoughness;
    pixel.roughness = PerceptualRoughnessToRoughness(pixel.perceptualRoughness);
    pixel.diffuseColor = computeDiffuseColor(baseColor, metallic);
    pixel.specularColor = computeF0(0.5, baseColor, metallic);


    vec3 diffuse = lightColorIntensity.rgb * lightColorIntensity.w * context.NoL * Diffuse_Lambert(pixel.diffuseColor);
    // float diffuse = diffuseLobe(pixel, NoV, NoL, LoH);

    vec3 specular = lightColorIntensity.rgb * lightColorIntensity.w * context.NoL * SpecularGGX(roughness, pixel.specularColor, context);

    // float test = context.NoL;
    // vec3 testColor = vec3(test, test, test); 
    // return testColor;
    return diffuse;
}