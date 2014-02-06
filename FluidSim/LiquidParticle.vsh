// Vertex Shader

static const char* LiquidParticleVS = STRINGIFY
(
 
 // Attributes
 attribute vec2 aPosition;
 
 // Uniforms
 uniform mat4 uProjectionMatrix;
 uniform float uRetinaScale;
 
 varying vec4 vColor;
 
 void main(void)
{
    gl_Position = uProjectionMatrix * vec4(aPosition.xy, 0.0, 1.0);
    //gl_Position = uProjectionMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    gl_PointSize = 2.0 * uRetinaScale;
}
 
 );