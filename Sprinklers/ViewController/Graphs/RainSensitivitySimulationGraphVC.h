//
//  RainSensitivitySimulationGraphVC.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Protocols.h"
#import "BaseLevel2ViewController.h"

@class RainSensitivityVC;
@class Provision;

@interface RainSensitivitySimulationGraphVC : BaseLevel2ViewController <SprinklerResponseProtocol>

@property (nonatomic, weak) RainSensitivityVC *parent;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) Provision *provison;
@property (nonatomic, strong) NSArray *mixerDataByDate;

@property (nonatomic, assign) double et0Average;
@property (nonatomic, assign) double rainSensistivity;
@property (nonatomic, assign) NSInteger wsDays;
@property (nonatomic, assign) double waterSurplus;
@property (nonatomic, assign) double maxValue;
@property (nonatomic, strong) NSArray *et0Array;
@property (nonatomic, strong) NSArray *waterNeedArray;

@property (nonatomic, strong) UIColor *savedIndicatorColor;
@property (nonatomic, strong) UIColor *wateredIndicatorColor;

@property (nonatomic, weak) IBOutlet UIScrollView *graphScrollView;
@property (nonatomic, weak) IBOutlet UIView *savedIndicatorView;
@property (nonatomic, weak) IBOutlet UIView *wateredIndicatorView;

- (void)reloadGraph;

@end

