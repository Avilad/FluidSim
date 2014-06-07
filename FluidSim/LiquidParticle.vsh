// Vertex Shader

static const char* LiquidParticleVS = STRINGIFY
(
 
 // Attributes
 attribute vec2 aPosition;
 attribute vec2 aVelocity;
 
 // Uniforms
 uniform mat4 uProjectionMatrix;
 uniform float uRetinaScale;
 
 // Varyings
 varying vec2 vVelocity;
 
 void main(void)
{
    gl_Position = uProjectionMatrix * vec4(aPosition.xy, 0.0, 1.0);
//    gl_Position = uProjectionMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    vVelocity = aVelocity;
    gl_PointSize = 56.0 * uRetinaScale;
//    gl_PointSize = 2.0 * uRetinaScale;
}
 
 );