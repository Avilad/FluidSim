// Fragment Shader

static const char* LiquidParticleFS = STRINGIFY
(
 
 uniform sampler2D uTexture;
 varying lowp vec2 vVelocity;
 
 void main(void)
{
    lowp vec4 texture = texture2D(uTexture, gl_PointCoord);
    
    gl_FragColor = vec4(1.0, vVelocity.x, vVelocity.y, texture.w);
//    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
 
 );