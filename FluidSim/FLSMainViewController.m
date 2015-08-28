//
//  FLSMainViewController.m
//  FluidSim
//
//  Created by Avilad on 1/28/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import "FLSMainViewController.h"
#import "FLSLiquid.h"

@implementation FLSMainViewController

BOOL touching = false;
FLSTouchOperation touchOperation;
int touchStationaryFrames;
GLKVector2 touchPos;
GLKVector2 newTouchPos;
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
    
    CGRect screenRect = [UIScreen mainScreen].bounds;
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
    
    if (touching) {
        GLKVector2 touchVel = GLKVector2Subtract(touchPos, newTouchPos);
        touchPos = GLKVector2MakeWithArray(newTouchPos.v);
        
        if (touchOperation == FLSTouchDoNothing) {
            if (GLKVector2Length(touchVel) > 10.0f)
                touchOperation = FLSTouchFlingFluid;
            touchStationaryFrames++;
            if (touchStationaryFrames == 5)
                touchOperation = [liquid operationForTouch:touchPos.x posY:touchPos.y];
        }
        else if (touchOperation == FLSTouchAddFluid)
            [liquid addFluidAtPosX:touchPos.x posY:touchPos.y];
        else if (touchOperation == FLSTouchRemoveFluid)
            [liquid removeFluidAtPosX:touchPos.x posY:touchPos.y];
        else if (touchOperation == FLSTouchFlingFluid)
            [liquid flingFluidAtPosX:touchPos.x posY:touchPos.y withVelX:touchVel.x velY:touchVel.y];
    }
    
    [liquid update];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if ([[event allTouches] count] > 1) {
        [self performSegueWithIdentifier:@"return_to_menu_from_fls" sender:NULL];
        touching = NO;
        return;
    }
    
    touching = YES;
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[UIApplication sharedApplication].keyWindow];
    
    touchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
    newTouchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
    
    touchOperation = FLSTouchDoNothing;
    touchStationaryFrames = 0;
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    touching = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[UIApplication sharedApplication].keyWindow];
    
    newTouchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
}

@end