//
//  FLSBackgroundLayer.m
//  FluidSim
//
//  Created by SlEePlEs5 on 12/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSBackgroundLayer.h"

@implementation FLSBackgroundLayer

+ (CAGradientLayer*) blueGradient {
    
//    UIColor *colorOne = [UIColor colorWithRed:(120/255.0) green:(135/255.0) blue:(150/255.0) alpha:1.0];
//    UIColor *colorTwo = [UIColor colorWithRed:(57/255.0)  green:(79/255.0)  blue:(96/255.0)  alpha:1.0];
    
    UIColor *colorOne = [UIColor colorWithHue:(210/360.0) saturation:0.9 brightness:0.4 alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithHue:(210/360.0) saturation:0.4 brightness:0.15 alpha:1.0];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
    
}

@end