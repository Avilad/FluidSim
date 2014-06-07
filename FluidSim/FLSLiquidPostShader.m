//
//  FLSLiquidPostShader.m
//  FluidSim
//
//  Created by SlEePlEs5 on 2/9/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSLiquidPostShader.h"
#import "FLSShaderProcessor.h"

// Shaders
#define STRINGIFY(A) #A
#include "LiquidPost.vsh"
#include "LiquidPost.fsh"

@implementation FLSLiquidPostShader

- (void)loadShader
{
    
    // Program
    FLSShaderProcessor* shaderProcessor = [[FLSShaderProcessor alloc] init];
    self.program = [shaderProcessor BuildProgram:LiquidPostVS with:LiquidPostFS];
    
    // Attributes
    self.v_coord = glGetAttribLocation(self.program, "v_coord");
    
    // Uniforms
    self.fbo_texture = glGetUniformLocation(self.program, "fbo_texture");
    self.uScreenSize = glGetUniformLocation(self.program, "uScreenSize");
    self.uGravity = glGetUniformLocation(self.program, "uGravity");
    
}

@end
