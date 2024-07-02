
const float PI = 3.14159265359;

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

vec3 BRDF(vec3 L, vec3 V, vec3 N, float metallic, float roghness, 
    vec3 baseColor, vec3 lightColor)
{
    roghness = max(roghness, 0.05);
    //预计算一些vector和一些dots
    vec3 H =normalize(V + L);
    float NoV = clamp(dot(N, V), 0.0, 1.0);
    float NoL = clamp(dot(N, L), 0.0, 1.0);
    float LoH = clamp(dot(L, H), 0.0, 1.0);
    float NoH = clamp(dot(N, H), 0.0, 1.0);
    float roughness2 = roughness * roughness;
    vec3 F0 = mix(vec3(0.04), baseColor, metallic);
    float k = ((roughness2 + 1.0) * (roughness2 + 1.0)) / 8.0;

    float D = Throwbridge_Reitz_GGX(NoH, roughness2);
    vec3 F = SchlickFresnel(HoV, F0);
    float G = SchlickGGX(NoV, k), SchlickGGX(NoL, k);

    vec3 k_s = F;
    vec3 k_d = (1.0 - k_s)

    // #TODO 指定light color
    // vec3 lightColor = vec3(1.0);

    vec3 color = vec3(0.0);

    

    return color;
}