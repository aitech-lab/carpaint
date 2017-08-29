uniform float flakeScale;
varying vec4 mvPosition;
varying vec3 worldNormal;
varying vec3 cameraToVertex;
varying vec2 vUv;
varying vec2 flakeUv;

void main() {
  mvPosition = modelViewMatrix * vec4( position, 1.0 );
  worldNormal = mat3( modelMatrix[ 0 ].xyz, modelMatrix[ 1 ].xyz, modelMatrix[ 2 ].xyz ) * normal;
  vec4 worldPosition = modelMatrix * vec4( position, 1.0 );
  cameraToVertex = normalize(worldPosition.xyz - cameraPosition);
  vUv = uv;
  flakeUv = uv * flakeScale;
  gl_Position = projectionMatrix * mvPosition;
}