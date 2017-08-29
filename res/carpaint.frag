uniform vec3 paintColor1;
uniform vec3 paintColor2;
uniform vec3 paintColor3;

uniform float normalPerturbation;
uniform float microflakePerturbationA;
uniform float microflakePerturbation;
uniform float time;


uniform float glossLevel;
uniform float brightnessFactor;
uniform samplerCube envMap;

uniform sampler2D normalMap;
uniform sampler2D microflakeNMap;
uniform vec3 flakeColor;
uniform float normalScale;
varying vec2 vUv;
varying vec2 flakeUv;
varying vec3 worldNormal;
varying vec4 mvPosition;
varying vec3 cameraToVertex;

// This function taken directly from the three.js phong fragment shader.
// http://hacksoflife.blogspot.ch/2009/11/per-pixel-tangent-space-normal-mapping.html
vec3 perturbNormal2Arb( vec3 eye_pos, vec3 surf_norm ) {

    vec3 q0 = dFdx( eye_pos.xyz );
    vec3 q1 = dFdy( eye_pos.xyz );
    vec2 st0 = dFdx( vUv.st );
    vec2 st1 = dFdy( vUv.st );

    vec3 S = normalize( q0 * st1.t - q1 * st0.t );
    vec3 T = normalize( -q0 * st1.s + q1 * st0.s );
    vec3 N = normalize( surf_norm );

    vec3 mapN = texture2D( normalMap, vUv ).xyz * 2.0 - 1.0;
    mapN.xy = normalScale * mapN.xy;
    mat3 tsn = mat3( S, T, N );
    return normalize( tsn * mapN );

 }

vec3 perturbSparkleNormal2Arb( vec3 eye_pos, vec3 surf_norm ) {

    vec3 q0  = dFdx( eye_pos.xyz );
    vec3 q1  = dFdy( eye_pos.xyz );
    vec2 st0 = dFdx( vUv.st );
    vec2 st1 = dFdy( vUv.st );

    vec3 S = normalize( q0 * st1.t - q1 * st0.t );
    vec3 T = normalize( -q0 * st1.s + q1 * st0.s );
    vec3 N = normalize( surf_norm );

    vec3 mapN = texture2D( microflakeNMap, flakeUv ).xyz * 2.0 - 1.0;
    mapN.xy = 1.0 * mapN.xy;
    mat3 tsn = mat3( S, T, N );
    return normalize( tsn * mapN );

 }

void main() {

  // Refelection
  vec3 normal     = perturbNormal2Arb( mvPosition.xyz, worldNormal );
  float fFresnel  = dot( normalize( -cameraToVertex ), normal );
  vec3 reflection = 2.0 * worldNormal * fFresnel - normalize(-cameraToVertex);
  vec4 envColor   = textureCube( envMap, vec3( -reflection.x, reflection.yz ), glossLevel );
  envColor.rgb   *= brightnessFactor;
  float fEnvContribution = 1.0 - 0.5 * fFresnel;

  // Flakes
  vec3 vFlakesNormal = perturbSparkleNormal2Arb(mvPosition.xyz, worldNormal);
  vec3 vNp1 = microflakePerturbationA * vFlakesNormal + normalPerturbation * worldNormal;
  vec3 vNp2 = microflakePerturbation * ( vFlakesNormal + worldNormal ) ;

  float  fFresnel1 = clamp(dot( -cameraToVertex, vNp1 ), 0.0, 1.0);
  float  fFresnel2 = clamp(dot( -cameraToVertex, vNp2 ), 0.0, 1.0);

  float fFresnel1Sq = fFresnel1 * fFresnel1;
  vec3 paintColor = fFresnel1   * paintColor1 +
                    fFresnel1Sq * paintColor2 +
                    fFresnel1Sq * fFresnel1Sq * paintColor3 +
                    pow( fFresnel2, 16.0 ) * flakeColor;

  gl_FragColor = envColor * fEnvContribution + vec4(paintColor, 1.0);
}