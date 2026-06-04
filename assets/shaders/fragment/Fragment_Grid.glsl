#version 330 core

in vec3 world_position;
in vec3 camera_position;
in vec3 vertex_color;

uniform float gridSize = 100.0f;
uniform float gridCellSize = 0.025f;
uniform float gridMinPixelsBetweenCells = 2.0f;
uniform vec4 gridColorThin = vec4(0.5f, 0.5f, 0.5f, 1.0f);
uniform vec4 gridColorThick = vec4(0.0f, 0.0f, 0.0f, 1.0f);

out vec4 FragColor;

float max2(vec2 v)
{
  float f = max(v.x, v.y);
  return f;
}

vec2 satv(vec2 x)
{
  vec2 v = clamp(x, vec2(0.0), vec2(1.0));
  return v;
}

float log10(float x)
{
  float f = log(x) / log(10.0);
  return f;
}

float satf(float x)
{
  float f = clamp(x, 0.0, 1.0);
  return f;
}

void main()
{
	vec2 dvx = vec2(dFdx(world_position.x), dFdy(world_position.x));
	vec2 dvy = vec2(dFdx(world_position.z), dFdy(world_position.z));

	float lx = length(dvx);
	float ly = length(dvy);

	vec2 dudv = vec2(lx, ly);
	float l = length(dudv);

	float LOD = max(0.0f, log10((l * gridMinPixelsBetweenCells) / gridCellSize) + 1.0f);
	float gridCellSizeLOD0 = gridCellSize * pow(10.0f, floor(LOD));
	float gridCellSizeLOD1 = gridCellSizeLOD0 * 10.0f;
	float gridCellSizeLOD2 = gridCellSizeLOD1 * 10.0f;

	dudv *= 4.0f;

	vec2 mod_dudv = mod(world_position.xz, gridCellSizeLOD0) / dudv;
	float lod0 = max2(vec2(1.0) - abs(satv(mod_dudv) * 2.0f - vec2(1.0f)));

	mod_dudv = mod(world_position.xz, gridCellSizeLOD1) / dudv;
	float lod1 = max2(vec2(1.0) - abs(satv(mod_dudv) * 2.0f - vec2(1.0f)));

	mod_dudv = mod(world_position.xz, gridCellSizeLOD2) / dudv;
	float lod2 = max2(vec2(1.0) - abs(satv(mod_dudv) * 2.0f - vec2(1.0f)));

	float LOD_fade = fract(LOD);

	vec4 Color;

	if (lod2 > 0.0f)
	{
		Color = gridColorThick;
		Color.a *= lod2;
	}
	else
	{
		if (lod1 > 0.0f)
		{
			Color = mix(gridColorThick, gridColorThin, LOD_fade);
			Color.a *= lod1;
		}
		else
		{
			Color = gridColorThin;
			Color.a *= (lod0 * (1.0f - LOD_fade));
		}
	}

	float opacityFalloff = (1.0f - satf(length(world_position.xz - camera_position.xz) / gridSize));

	Color.a *= opacityFalloff;
	FragColor = Color;
}