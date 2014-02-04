//
//  FLSLiquid.h
//  FluidSim
//
//  Created by SlEePlEs5 on 2/4/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

const float scale = 64.0f;

@interface FLSLiquid : NSObject

-(id)initWithParticleTexture:(NSString *)fileName effect:(GLKBaseEffect *)effect;

-(void)update;
-(void)render;
-(void)createParticleWithPosX:(float)posX posY:(float)posY;

@end
