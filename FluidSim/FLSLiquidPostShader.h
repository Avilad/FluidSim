//
//  FLSLiquidPostShader.h
//  FluidSim
//
//  Created by SlEePlEs5 on 2/9/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
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

// Methods
- (void)loadShader;

@end