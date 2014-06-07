//
//  FLSViewController.m
//  FluidSim
//
//  Created by SlEePlEs5 on 1/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSViewController.h"
#import "FLSLiquid.h"

@implementation FLSViewController

BOOL touching = false;
GLKVector2 touchPos;
GLKVector2 screenSize;

FLSLiquid *liquid;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up context
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
    
    // Set up view
    GLKView* view = (GLKView*)self.view;
    view.context = context;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    screenSize = GLKVector2Make(screenRect.size.width, screenRect.size.height);
    
    liquid = [[FLSLiquid alloc] initWithScreenSize:screenSize];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Set the background color (black)
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    [liquid render];
    
}



#pragma mark - GLKViewControllerDelegate

- (void)update {
    
    //MouseState mouseState = Mouse.GetState();
    
    //_mouse = new Vector2(mouseState.X, mouseState.Y) / _scale;
    //if (mouseState.LeftButton == ButtonState.Pressed)
    
    if (touching)
        [liquid createParticleWithPosX:touchPos.x posY:touchPos.y];
//    
//    applyLiquidConstraints();
    [liquid update];
    
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