#version 330 core

in vec2 texCoords;

uniform sampler2D texture_diffuse1;
uniform sampler2D texture_diffuse2;
uniform sampler2D texture_diffuse3;
uniform sampler2D texture_specular1;
uniform sampler2D texture_specular2;
//uniform sampler2D sampler;

out vec4 FragColor;

void main()
{
	vec4 diffuse1 = texture2D(texture_diffuse1, texCoords);
	vec4 diffuse2 = texture2D(texture_diffuse2, texCoords);
	vec4 diffuse3 = texture2D(texture_diffuse3, texCoords);
	vec4 specular1 = texture2D(texture_specular1, texCoords);
	vec4 specular2 = texture2D(texture_specular2, texCoords);
	FragColor = diffuse1 + diffuse2 + diffuse3 + specular1 + specular2;
}