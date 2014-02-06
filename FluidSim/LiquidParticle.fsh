// Fragment Shader

static const char* LiquidParticleFS = STRINGIFY
(
 
 varying highp vec4 vColor;
 
 void main(void)
{
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
}
 
 );