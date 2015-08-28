//
//  FLSLiquidPostShader.h
//  FluidSim
//
//  Created by Avilad on 2/9/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface FLSLiquidPostShader : NSObject

// Program Handle
@property (readwrite) GLint program;

// Attribute Handles
@property (readwrite) GLint v_coord;

// Uniform Handles
@property (readwrite) GLint fbo_texture;
@property (readwrite) GLint uScreenSize;
@property (readwrite) GLint uGravity;
@property (readwrite) GLint uShimmer;

@property (readwrite) GLint uLook_BaseColor;
@property (readwrite) GLint uLook_Clarity;
@property (readwrite) GLint uLook_Shimmer;
@property (readwrite) GLint uLook_Foam;

// Methods
- (void)loadShader;

@end