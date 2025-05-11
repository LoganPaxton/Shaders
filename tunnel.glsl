// Date of creation: May 11th, 2025
// Time to make: 3 hours
// Note: It's supposed to look like a tunnel, I'm not too proud of this shader though.

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec2 centered = uv * 2.0 - 1.0;
    centered.x *= u_resolution.x / u_resolution.y;
    float radius = 1.0 - clamp(length(centered), 0., 1.);
    float angle = atan(centered.y, centered.x);
    float thickness = 0.05;
    
    vec3 pink = vec3(0.985,0.212,0.462);
    vec3 green = vec3(0.169,1.000,0.000);
    vec3 col = mix(pink, green, radius);
    
    float tunnel = abs(sin(radius * 0.2 + angle * 0. - u_time * 0.01)); // radius * frequency + angle * twistAmount - time * speed
    tunnel *= 0.7 + 0.3 * sin(u_time * 0.5);

    vec3 final_color = col * (tunnel * tunnel) * radius;
    gl_FragColor = vec4(final_color, 1.0);
}
