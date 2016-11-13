#version 120

float maxBrighten = 10.0;   //Maximum brightening of the screen (should be greater than 1)
float HDRRatio = 1.0;       //Ajust for stronger or subtler HDR (between 0 and 1)
float idealLum = .5;       //The prefered average luminosity of the screen (between 0 and 1)

uniform sampler2D DiffuseSampler;
uniform sampler2D MBSampler;
uniform vec2 OutSize;
varying vec2 texCoord;

float toLum (vec4 color){
    return dot(color.rgb, vec3(.2125, .7154, .0721) );
}

vec4 toLinear (vec4 color){
    return pow(color,vec4(2.2));
}

float toLinear (float value){
    return pow(value,2.2);
}

vec4 toGamma (vec4 color){
    return pow(color,vec4(1.0/2.2));
}

float toGamma (float value){
    return pow(value,1.0/2.2);
}

vec4 toReinhard (vec4 color){
    float lum = toLum(color);
    float reinhardLum = lum/(1.0+lum);
    return color*(reinhardLum/lum);
}

vec4 lightAjust (vec4 color,float amount){
    float newLum = 1.0-pow(1.0-toLum(color),amount);
    float oldLum = toLum(color);
    vec4 color1 = color*(newLum/oldLum);

    vec4 color2 = 1.0-pow(1.0-color,vec4(amount));

    return mix(color1,color2,0.5);
}


//samples color from 16 places on the screen and averages them

vec4 averageTopLeft=(
    toLinear(texture2D(MBSampler, vec2(.2,.2)))+
    toLinear(texture2D(MBSampler, vec2(.2,.4)))+
    toLinear(texture2D(MBSampler, vec2(.4,.2)))+
    toLinear(texture2D(MBSampler, vec2(.4,.4)))
)/4.0;

vec4 averageTopRight=(
    toLinear(texture2D(MBSampler, vec2(.6,.2)))+
    toLinear(texture2D(MBSampler, vec2(.6,.4)))+
    toLinear(texture2D(MBSampler, vec2(.8,.2)))+
    toLinear(texture2D(MBSampler, vec2(.8,.4)))
)/4.0;

vec4 averageBottomLeft=(
    toLinear(texture2D(MBSampler, vec2(.2,.6)))+
    toLinear(texture2D(MBSampler, vec2(.2,.8)))+
    toLinear(texture2D(MBSampler, vec2(.4,.6)))+
    toLinear(texture2D(MBSampler, vec2(.4,.8)))
)/4.0;

vec4 averageBottomRight=(
    toLinear(texture2D(MBSampler, vec2(.6,.6)))+
    toLinear(texture2D(MBSampler, vec2(.6,.8)))+
    toLinear(texture2D(MBSampler, vec2(.8,.6)))+
    toLinear(texture2D(MBSampler, vec2(.8,.8)))
)/4.0;

float topLeftLum = toLum(averageTopLeft);
float topRightLum = toLum(averageTopRight);
float bottomLeftLum = toLum(averageBottomLeft);
float bottomRightLum = toLum(averageBottomRight);

float averageLum = mix(
     mix(topLeftLum, bottomLeftLum, texCoord.y)
    ,mix(topRightLum, bottomRightLum, texCoord.y)
    ,texCoord.x
);

void main() {
    vec4 color = toLinear( texture2D(DiffuseSampler, texCoord) );

    float maxAveragedBrighten  = ( maxBrighten - ( 1.0 - HDRRatio ) ) / HDRRatio;
    float brightenRatio        = idealLum / averageLum;
    float clampedBrightenRatio = clamp( brightenRatio, 0.5, maxAveragedBrighten );
    float finalRatio = mix(1.0,clampedBrightenRatio,HDRRatio);

    vec4 averagedColor = lightAjust(color,finalRatio);

    vec4 bloom1 = max((color*finalRatio)-1.0,0.0);

    vec4 bloom2 = averagedColor*(toLum(bloom1)/toLum(averagedColor));

    gl_FragColor = toGamma(bloom2);
}
