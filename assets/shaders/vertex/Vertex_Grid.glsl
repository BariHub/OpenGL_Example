#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

uniform vec3 cameraWorldPos;
uniform float gridSize = 100.0f;

//uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

out vec3 world_position;
out vec3 camera_position;
out vec3 vertex_color;

void main()
{
  vec3 vPos = aPos * gridSize;

  vPos.x += cameraWorldPos.x; // follows the camera at all times
  vPos.z += cameraWorldPos.z;

  mat4 viewproj = projectionMatrix * viewMatrix;

  gl_Position = viewproj * vec4(vPos, 1.0f);
  world_position = vPos;
  camera_position = cameraWorldPos;
  vertex_color = aColor;
}