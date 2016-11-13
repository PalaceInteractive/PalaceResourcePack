#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DarkBlurSampler;
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

vec4 toneMap (vec4 color){
    float maxColor=max(color.r,max(color.g,color.b));
    vec4 foo=lightAjust(color/maxColor,maxColor);

    return min(foo,color);
}



void main() {
    vec4 color = toLinear(texture2D(DiffuseSampler, texCoord));
    vec4 bloom = toLinear(texture2D(DarkBlurSampler, texCoord));

    vec4 bloomed = color + bloom;

    vec4 toneMapped = toneMap(bloomed);

    vec4 detailed = mix(toneMapped,color,0.2);

    gl_FragColor = toGamma(detailed);

}
