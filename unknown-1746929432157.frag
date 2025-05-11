#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time; // Seconds
uniform vec2 u_resolution;
uniform vec2 u_mouse;


float circle(float radius, vec2 pos, float borderThickness, float speed, float interval) {
    float dist = length((gl_FragCoord.xy / u_resolution) - pos);
    float raid = 0.5 + 0.5 * sin(dist - u_time * speed);
    float wave = mod(dist - u_time, interval);
    
    return smoothstep(raid - borderThickness, raid + borderThickness, wave);
}

void main() {
    vec2 uv = fract(gl_FragCoord.xy / u_resolution);
    vec2 pos = u_mouse / u_resolution;
    float cir = circle(0.2, pos, 0.1, 0.5, 1.);
    float dist_ = length(uv - pos);
    float fade = exp(-dist_ * 4.0);
    vec3 blue = vec3(0.000,0.286,0.985);
    vec3 color = vec3(blue * cir * fade);
    
    gl_FragColor = vec4(color, 1.);
    
}