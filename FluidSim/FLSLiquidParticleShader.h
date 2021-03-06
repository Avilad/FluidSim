//
//  FLSLiquidParticleShader.h
//  FluidSim
//
//  Created by Avilad on 2/4/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface FLSLiquidParticleShader : NSObject

// Program Handle
@property (readwrite) GLint program;

// Attribute Handles
@property (readwrite) GLint aPosition;
@property (readwrite) GLint aVelocity;

// Uniform Handles
@property (readwrite) GLint uProjectionMatrix;
@property (readwrite) GLint uRetinaScale;
@property (readwrite) GLint uTexture;

// Methods
- (void)loadShader;

@end