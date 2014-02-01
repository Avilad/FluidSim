//
//  FLSParticle.h
//  FluidSim
//
//  Created by SlEePlEs5 on 1/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "FLSGlobals.h"

@interface FLSParticle : NSObject {
    
@public float distances[MAX_PARTICLES];
@public int neighbors[MAX_PARTICLES];
    
}

@property (assign) GLKVector2 position;
@property (assign) GLKVector2 velocity;
@property (assign) BOOL alive;
@property (assign) int index;

@property int neighborCount;
@property int ci;
@property int cj;

@property (assign) CGSize contentSize;

- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect;
- (void)render;

@end
