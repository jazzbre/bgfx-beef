[VS]
$input a_position, a_texcoord0
$output v_texcoord0

#include "bgfx_shader.sh"

uniform vec2 scale;

void main()
{
   float4 position = mul(u_modelView, vec4(a_position.xy * vec2(scale.x, scale.y), 0.0, 1.0) );
   position.xy = round(position.xy);
   gl_Position = mul(u_proj, position);
	v_texcoord0 = a_texcoord0.xy;
}

[VAR]
vec2 v_texcoord0    : TEXCOORD0 = vec2(0.0, 0.0);

vec3 a_position  : POSITION;
vec3 a_texcoord0 : TEXCOORD0;

[FS]
$input v_texcoord0

#include "bgfx_shader.sh"

SAMPLER2D(s_texture, 0);

void main()
{
	gl_FragColor = texture2D(s_texture, v_texcoord0);
}

