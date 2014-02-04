//
//  FLSViewController.m
//  FluidSim
//
//  Created by SlEePlEs5 on 1/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSViewController.h"
#import "FLSLiquid.h"

@interface FLSViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong) GLKBaseEffect *effect;

@property FLSLiquid *liquid;

@end

@implementation FLSViewController

@synthesize context = _context;
@synthesize liquid = _liquid;

BOOL touching = false;
GLKVector2 touchPos;
GLKVector2 screenSize;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    srand((unsigned int)time(0));
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, screenRect.size.width, 0, screenRect.size.height, -1024, 1024);
    
    screenSize = GLKVector2Make(screenRect.size.width, screenRect.size.height);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    self.liquid = [[FLSLiquid alloc] initWithParticleTexture:@"Particle.png" effect:self.effect];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    [self.liquid render];
    
//    for (size_t i : _activeParticles) {
//        
//        [_liquid[i] render];
//        
//    }
}



#pragma mark - GLKViewControllerDelegate

- (void)update {
    
    //MouseState mouseState = Mouse.GetState();
    
    //_mouse = new Vector2(mouseState.X, mouseState.Y) / _scale;
    //if (mouseState.LeftButton == ButtonState.Pressed)
    
    if (touching)
        [self.liquid createParticleWithPosX:touchPos.x/scale posY:(screenSize.y-touchPos.y)/scale];
//    
//    applyLiquidConstraints();
    [self.liquid update];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    touching = YES;
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[UIApplication sharedApplication].keyWindow];
    
    touchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    touching = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[UIApplication sharedApplication].keyWindow];
    
    touchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
}

@end