// A slightly failed implementation of a ray-tracer in GLSL.

struct Material {
    vec3 color;
    float fuzz;
    float ref_idx;
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct HitRecord {
    float t;
    vec3 p;
    vec3 normal;
    Material mat;
};

struct Sphere {
    vec3 center;
    float radius;
    Material mat;
};

struct ScatterResult {
    Ray scattered;
    vec3 attenuation;
    bool isBackground;
};

vec3 rayAt(Ray r, float t) {
    return r.origin + r.direction * t;
}

bool hitSphere(Sphere s, Ray r, float t_min, float t_max, out HitRecord rec) {
    vec3 oc = r.origin - s.center;
    float a = dot(r.direction, r.direction);
    float b = 2.0 * dot(oc, r.direction);
    float c = dot(oc, oc) - s.radius*s.radius;
    float discriminant = b*b - 4.0*a*c;
    
    if (discriminant < 0.0) {
        return false;
    }
    
    float t = (-b - sqrt(discriminant)) / (2.0*a);
    if (t < t_min || t > t_max) {
        t = (-b + sqrt(discriminant)) / (2.0*a);
        if (t < t_min || t > t_max) {
            return false;
        }
    }
    
    rec.t = t;
    rec.p = rayAt(r, t);
    rec.normal = (rec.p - s.center) / s.radius;
    rec.mat = s.mat;
    return true;
}

Sphere sphere1 = Sphere(vec3(0.0, 0.0, -1.0), 0.5, Material(vec3(0.1, 0.9, 0.1), 0.0, 1.5));
Sphere sphere2 = Sphere(vec3(0.0, -100.5, -1.0), 100.0, Material(vec3(0.4, 0.4, 0.4), 0.0, 0.0));

bool hitWorld(Ray r, float t_min, float t_max, out HitRecord rec) {
    HitRecord tempRec;
    bool hitAnything = false;
    float closestSoFar = t_max;

    if (hitSphere(sphere1, r, t_min, closestSoFar, tempRec)) {
        hitAnything = true;
        closestSoFar = tempRec.t;
        rec = tempRec;
    }

    if (hitSphere(sphere2, r, t_min, closestSoFar, tempRec)) {
        hitAnything = true;
        rec = tempRec; 
    }
    
    return hitAnything;
}

vec3 _reflect(vec3 v, vec3 n) {
    return v - 2.0 * dot(v, n) * n;
}

vec3 _refract(vec3 uv, vec3 n, float etai_over_etat) {
    float cos_theta = dot(-uv, n);
    vec3 r_out_perp = etai_over_etat * (uv + cos_theta * n);
    vec3 r_out_parallel = -sqrt(abs(1.0 - dot(r_out_perp, r_out_perp))) * n;
    return r_out_perp + r_out_parallel;
}

float schlick(float cosine, float ref_idx) {
    float r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * pow((1.0 - cosine), 5.0);
}

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

ScatterResult scatterRay(Ray r, HitRecord rec, vec2 rand_seed) {
    ScatterResult sr;
    sr.isBackground = false;
    sr.attenuation = rec.mat.color;

    vec3 unit_direction = normalize(r.direction);
    float etai_over_etat;
    vec3 outward_normal;
    float cosine;

    if (dot(unit_direction, rec.normal) > 0.0) {
        outward_normal = -rec.normal;
        etai_over_etat = rec.mat.ref_idx;
        cosine = rec.mat.ref_idx * dot(unit_direction, rec.normal) / length(unit_direction);
    } else {
        outward_normal = rec.normal;
        etai_over_etat = 1.0 / rec.mat.ref_idx;
        cosine = -dot(unit_direction, rec.normal) / length(unit_direction);
    }
    
    vec3 refracted = _refract(unit_direction, outward_normal, etai_over_etat);
    float reflect_prob = schlick(cosine, rec.mat.ref_idx);

    if (length(refracted) > 0.0 && reflect_prob < random(rand_seed)) {
        sr.scattered = Ray(rec.p, refracted);
    } else {
        vec3 reflected = _reflect(unit_direction, rec.normal);
        sr.scattered = Ray(rec.p, reflected);
        sr.attenuation = vec3(1.0);
    }
    
    return sr;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 camOrigin = vec3(0.0, 0.0, 1.0);
    vec3 screenLowerLeft = vec3(-2.0, -1.0, -1.0);
    vec3 screenHorizontal = vec3(4.0, 0.0, 0.0);
    vec3 screenVertical = vec3(0.0, 2.0, 0.0);
    
    vec2 uv = fragCoord.xy / iResolution.xy;

    Ray r;
    r.origin = camOrigin;
    r.direction = screenLowerLeft + uv.x * screenHorizontal + uv.y * screenVertical - camOrigin;
    
    vec2 rand_seed = fragCoord.xy;
    
    vec3 final_color = vec3(0.0);
    vec3 attenuation = vec3(1.0);
    const int MAX_DEPTH = 5;

    for (int i = 0; i < MAX_DEPTH; i++) {
        HitRecord rec;
        if (hitWorld(r, 0.001, 100.0, rec)) {
            
            if (i == MAX_DEPTH - 1) { 
                final_color += attenuation * vec3(0.1); 
                break;
            }

            ScatterResult scatter = scatterRay(r, rec, rand_seed);

            attenuation *= scatter.attenuation;
            r = scatter.scattered;
            
        } else {
            vec3 unitDir = normalize(r.direction);
            float t = 0.5 * (unitDir.y + 1.0); 
            vec3 sky_color = mix(vec3(1.0), vec3(0.5, 0.7, 1.0), t);
            
            final_color += attenuation * sky_color;
            break;
        }
    }

    fragColor = vec4(final_color, 1.0);
}
