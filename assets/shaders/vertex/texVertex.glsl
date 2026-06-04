#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aUV;

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec2 texCoords;

void main()
{
  mat4 viewPort = projectionMatrix * viewMatrix * modelMatrix;
  texCoords = aUV;
  gl_Position = viewPort * vec4(aPos, 1.0);
}