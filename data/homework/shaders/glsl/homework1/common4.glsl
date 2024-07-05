
// 这个文件的实现中大部分参考UE4的shader实现，少部分参考

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
    float LoH;
};

void InitContext(inout BxDFContext context, vec3 N, vec3 V, vec3 L )
{
    vec3 H =normalize(V + L);
    context.NoV = saturate(dot(N, V));;
    context.NoL = saturate(dot(N, L));;
    context.VoL = saturate(dot(V, L));
    context.NoH = saturate(dot(N, H));
    context.VoH = saturate(dot(V, H));
    context.LoH = saturate(dot(L, H));
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

// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointApprox( float a2, float NoV, float NoL )
{
	float a = sqrt(a2);
	float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
	float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
	return 0.5 / ( Vis_SmithV + Vis_SmithL );
}

float Pow5( float x )
{
	float xx = x*x;
	return xx * xx * x;
}

vec3 F_Schlick(vec3 f0, float VoH) {
    float f = pow(1.0 - VoH, 5.0);
    return vec3(f + f0 * (1.0 - f));
}

// // [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
// vec3 F_Schlick(vec3 SpecularColor, float VoH )
// {
// 	float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
// 	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
// 	// Anything less than 2% is physically impossible and is instead considered to be shadowing
// 	return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
// }

// Normal Distribution
float Throwbridge_Reitz_GGX(float NoH, float a)
{
    float a2 = a * a;
    float NoH2 = NoH * NoH;

    float nom = a2;
    float denom = (NoH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return nom / denom;
}

// Fresnel
vec3 SchlickFresnel(float HoV, vec3 F0)
{
    float m = clamp(1 - HoV, 0, 1);
    float m2 = m * m;
    float m5 = m2 * m2 * m;
    return F0 + (1.0 - F0) * m5;
}

// Geometry term (shadow mask term)
float SchlickGGX(float NoV, float k)
{
    float nom = NoV;
    float denom = NoV * (1.0 - k) + k;

    return nom / denom;
}



vec3 SpecularGGX(float roughness, vec3 specularColor, BxDFContext context)
{
    float roughness2 = roughness * roughness;
    float k = ((roughness2 + 1.0) * (roughness2 + 1.0)) / 8.0;
    

    float D = D_GGX(roughness2, context.NoH);
    vec3 F = SchlickFresnel(context.VoH, specularColor);
    float G  = SchlickGGX(context.NoV, k) * SchlickGGX(context.NoL, k);

    vec3 f_specular = (D * F * G) / (4.0 * context.NoV * context.NoL + 0.0001);

    float test = D;
    vec3 test3 = vec3(test, test, test);
    return test3;
}
     

vec3 SurfaceShading(vec3 N,  vec3 V, vec3 L,
    vec3 baseColor, vec4 lightColorIntensity, float metallic, float perceptualRoughness
    )
{
    BxDFContext context;
    InitContext(context, N, V, L);
    context.NoV = saturate(abs( context.NoV ) + 1e-5);

    PixelParams pixel;
    pixel.perceptualRoughness = perceptualRoughness;
    pixel.roughness = PerceptualRoughnessToRoughness(pixel.perceptualRoughness);
    pixel.diffuseColor = computeDiffuseColor(baseColor, metallic);
    pixel.specularColor = computeF0(0.5, baseColor, metallic);


    vec3 diffuse = lightColorIntensity.rgb * lightColorIntensity.w * context.NoL * Diffuse_Lambert(pixel.diffuseColor);
    // float diffuse = diffuseLobe(pixel, NoV, NoL, LoH);

    vec3 specular = lightColorIntensity.rgb * lightColorIntensity.w * context.NoL * SpecularGGX(pixel.roughness, pixel.specularColor, context);

    // float test = context.NoL;
    // vec3 testColor = vec3(test, test, test); 
    // return testColor;
    vec3 test = SpecularGGX(pixel.roughness, pixel.specularColor, context);
    return test;
}