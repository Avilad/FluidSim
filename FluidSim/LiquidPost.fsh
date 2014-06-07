// Fragment Shader

static const char* LiquidPostFS = STRINGIFY
(
 
 uniform sampler2D fbo_texture;
 varying highp vec2 f_texcoord;
 
 uniform highp vec2 uScreenSize;
 uniform highp vec2 uGravity;
 
 void main(void)
{
    
    highp vec2 pxSize = 1.0 / uScreenSize;
    
    highp vec4 texture = texture2D(fbo_texture, f_texcoord);
    
    highp float speed = sqrt(texture.y * texture.y + texture.z * texture.z);
    
    highp float scattering = 0.0;
    
    // Scattering. Contrived as fuck, but it works so who cares.
    
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((2.0 * uGravity.y - 16.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((2.0 * uGravity.x - 16.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-4.0 * uGravity.y - 32.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-4.0 * uGravity.x - 32.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((6.0 * uGravity.y - 48.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((6.0 * uGravity.x - 48.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-8.0 * uGravity.y - 64.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-8.0 * uGravity.x - 64.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((10.0 * uGravity.y - 80.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((10.0 * uGravity.x - 80.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-12.0 * uGravity.y - 96.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-12.0 * uGravity.x - 96.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((14.0 * uGravity.y - 112.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((14.0 * uGravity.x - 112.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-16.0 * uGravity.y - 128.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-16.0 * uGravity.x - 128.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((18.0 * uGravity.y - 144.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((18.0 * uGravity.x - 144.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-20.0 * uGravity.y - 160.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-20.0 * uGravity.x - 160.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((22.0 * uGravity.y - 176.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((22.0 * uGravity.x - 176.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-24.0 * uGravity.y - 192.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-24.0 * uGravity.x - 192.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((26.0 * uGravity.y - 208.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((26.0 * uGravity.x - 208.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-28.0 * uGravity.y - 224.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-28.0 * uGravity.x - 224.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((30.0 * uGravity.y - 240.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((30.0 * uGravity.x - 240.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-32.0 * uGravity.y - 256.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-32.0 * uGravity.x - 256.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((34.0 * uGravity.y - 272.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((34.0 * uGravity.x - 272.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-36.0 * uGravity.y - 288.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-36.0 * uGravity.x - 288.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((38.0 * uGravity.y - 304.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((38.0 * uGravity.x - 304.0 * uGravity.y) * pxSize.y))).x / 20.0;
    scattering += texture2D(fbo_texture, vec2(f_texcoord.x + ((-40.0 * uGravity.y - 320.0 * uGravity.x) * pxSize.x), f_texcoord.y + ((-40.0 * uGravity.x - 320.0 * uGravity.y) * pxSize.y))).x / 20.0;
    
    scattering *= min(sqrt(uGravity.x * uGravity.x + uGravity.y * uGravity.y), 1.0);
    scattering = 1.0 - scattering;
    
    scattering *= 0.65;
    scattering += 0.35;
    
    highp vec2 scaledGravity = uGravity * 0.5;
    scaledGravity = vec2(scaledGravity.x + (0.5 * sign(scaledGravity.x)), scaledGravity.y + (0.5 * sign(scaledGravity.y)));
    
    highp float top = texture.x;
    top -= texture2D(fbo_texture, vec2(f_texcoord.x - (10.0 * scaledGravity.x * pxSize.x), f_texcoord.y - (10.0 * scaledGravity.y * pxSize.y))).x;
    top = step(0.7, top) * top;
    
    highp vec4 color = vec4((0.15 + speed + top) * scattering, (0.25 + speed + top) * scattering, (0.7 + speed + top) * scattering, step(0.7,texture.x));
    gl_FragColor = color;
//    gl_FragColor = vec4(f_texcoord*10.0, 0.0, 0.0);
//    gl_FragColor = texture;
}
 
 );