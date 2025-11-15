float hash(vec2 p) {
    vec3 p3  = fract(p.xyx * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float perlin(vec2 p) {
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    
    vec2 u = fp * fp * (3.0 - 2.0 * fp);
    
    float h00 = hash(ip + vec2(0.0, 0.0)) * 6.283;
    float h10 = hash(ip + vec2(1.0, 0.0)) * 6.283;
    float h01 = hash(ip + vec2(0.0, 1.0)) * 6.283;
    float h11 = hash(ip + vec2(1.0, 1.0)) * 6.283;
    
    vec2 g00 = vec2(cos(h00), sin(h00));
    vec2 g10 = vec2(cos(h10), sin(h10));
    vec2 g01 = vec2(cos(h01), sin(h01));
    vec2 g11 = vec2(cos(h11), sin(h11));
    
    float d00 = dot(g00, fp - vec2(0.0, 0.0));
    float d10 = dot(g10, fp - vec2(1.0, 0.0));
    float d01 = dot(g01, fp - vec2(0.0, 1.0));
    float d11 = dot(g11, fp - vec2(1.0, 1.0));
    
    float x_interp0 = mix(d00, d10, u.x);
    float x_interp1 = mix(d01, d11, u.x);
    
    return mix(x_interp0, x_interp1, u.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    
    vec2 speed = vec2(0.2, 0.1);
    vec2 p = uv * 10.0 + iTime * speed;
    
    float noiseValue = perlin(p);
    noiseValue = noiseValue * 0.5 + 0.5;
    
    fragColor = vec4(vec3(noiseValue), 1.0);
}
