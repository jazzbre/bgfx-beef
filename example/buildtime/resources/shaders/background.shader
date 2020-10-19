[VS]
$input a_position, a_texcoord0
$output v_texcoord0

#include "bgfx_shader.sh"

void main()
{
	gl_Position = vec4(a_position.xy, 0.0, 1.0);
	v_texcoord0 = a_texcoord0.xy * 2.0 - 1.0;
   v_texcoord0.y = -v_texcoord0.y;
}

[VAR]
vec2 v_texcoord0    : TEXCOORD0 = vec2(0.0, 0.0);

vec3 a_position  : POSITION;
vec3 a_texcoord0 : TEXCOORD0;

[FS]
$input v_texcoord0

#include "bgfx_shader.sh"

SAMPLER2D(s_texture, 0);

uniform vec4 time;

// https://www.shadertoy.com/view/MsGfD3

float hash(vec2 uv)
{
    vec2 res = fract(uv * vec2(821.143, 173.321));
    res += dot(res, res+23.13);
    return fract(res.x*res.y);
}

float noise(vec2 uv)
{
    vec2 ipos = floor(uv);
    vec2 fpos = fract(uv);
    
    float a = hash(ipos + vec2(0, 0));
    float b = hash(ipos + vec2(1, 0));
    float c = hash(ipos + vec2(0, 1));
    float d = hash(ipos + vec2(1, 1));
    
    vec2 t = smoothstep(0.0, 1.0, fpos);
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

float fbm(in vec2 p)
{
    float res = 0.0;
    float amp = 0.5;
    float freq = 2.0;
    for (int i = 0; i < 4; ++i)
    {
        res += amp*noise(freq*p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return res;
}

vec4 mainImage(vec2 uv, float iTime)
{
    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    
    vec3 ro = vec3(0, 0.8, iTime.x);
    vec3 at = ro + vec3(0, 0.2, 1);
    
    vec3 cam_z = normalize(at - ro);
    vec3 cam_x = normalize(cross(vec3(0,1,0), cam_z));
    vec3 cam_y = cross(cam_z, cam_x);
    vec3 rd = normalize(uv.x * cam_x + uv.y * cam_y + 2.0 * cam_z);
    
    vec3 sky_col = vec3(0.6, 0.7, 0.8);
    vec3 col = sky_col;
    col -= 0.7*rd.y;
    
    for (float i = 170.0; i > 0.0; --i)
    {
        vec3 p = ro + 0.05*i*rd;
        float f = p.y - 1.2*fbm(0.6*p.xz);
        float density = -f;
        if (density > 0.0)
        {
            col = mix(col, 1.0 - density*sky_col.bgr, min(1.0, density*0.4));
        }
    }
    
    fragColor = vec4(col, 1.0);
    return fragColor;
}

void main()
{
	gl_FragColor = mainImage(v_texcoord0.xy, time.x);
}
