//
//  FLSLookSettingsViewController.m
//  FluidSim
//
//  Created by SlEePlEs5 on 12/29/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSLookSettingsViewController.h"
#import "FLSGlobalSettings.h"

@interface FLSLookSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *look_clarityPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *look_shimmerPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *look_foamPercentLabel;

@property (weak, nonatomic) IBOutlet UISlider *look_claritySlider;
@property (weak, nonatomic) IBOutlet UISlider *look_shimmerSlider;
@property (weak, nonatomic) IBOutlet UISlider *look_foamSlider;

@end

@implementation FLSLookSettingsViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.look_clarityPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(look_clarity * 100.0f)]];
    [self.look_claritySlider setValue:look_clarity];
    
    float unscaledShimmer = (look_shimmer < 10.0f) ? 0.0f : ((look_shimmer - 10.0f) / 5.0f);
    [self.look_shimmerPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(unscaledShimmer * 100.0f)]];
    [self.look_shimmerSlider setValue:unscaledShimmer];
    
    [self.look_foamPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(look_foam * 100.0f)]];
    [self.look_foamSlider setValue:look_foam];
}
- (IBAction)look_claritySliderChanged
{
    float sliderValue = [self.look_claritySlider value];
    [self.look_clarityPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(sliderValue * 100.0f)]];
    look_clarity = sliderValue;
}
- (IBAction)look_shimmerSliderChanged
{
    float sliderValue = [self.look_shimmerSlider value];
    [self.look_shimmerPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(sliderValue * 100.0f)]];
    if (sliderValue == 0.0f)
        look_shimmer = 0.0f;
    else
        look_shimmer = 5.0f * sliderValue + 10.0f;
}
- (IBAction)look_foamSliderChanged
{
    float sliderValue = [self.look_foamSlider value];
    [self.look_foamPercentLabel setText:[NSString stringWithFormat:@"%i%%", (int)(sliderValue * 100.0f)]];
    look_foam = sliderValue;
}

@end
