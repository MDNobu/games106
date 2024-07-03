
struct Light 
{
    vec4 colorIntensity; //rgb, intensity
    // vec3 l;
    float attenuation;
    highp vec3 worldPosition;
}

struct PixelParams
{
    vec3 diffuseColor;
    float perceptrualRoughness;
    vec3 f0;
    float f90;
    float specular;
    vec3 specularColor;
}


/**
* 标准的Surface Lit BRDF
* 一个diffuse lobe + 一个specular lobe，支持渲染金属和非金属
*/
vec3 surfaceShading(const PixelParams pixel, const Light light, float occusion, 
    vec3 N, vec3 V, vec3 L, )
{
    occusion = 1.0; //这个是留给阴影和AO来实现的，先不考虑

    vec3 h = normalize()
}


