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

@protocol  RainSensitivitySimulationGraphDelegate;
@class RainSensitivityVC;
@class Provision;

@interface RainSensitivitySimulationGraphVC : BaseLevel2ViewController <SprinklerResponseProtocol>

@property (nonatomic, weak) RainSensitivityVC *parent;
@property (nonatomic, weak) id<RainSensitivitySimulationGraphDelegate> delegate;

@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) Provision *provison;
@property (nonatomic, strong) NSArray *mixerDataByDate;

@property (nonatomic, assign) double et0Average;
@property (nonatomic, assign) double rainSensistivity;
@property (nonatomic, assign) NSInteger wsDays;
@property (nonatomic, assign) double waterSurplus;
@property (nonatomic, assign) double maxValue;
@property (nonatomic, strong) NSArray *et0Array;
@property (nonatomic, strong) NSArray *qpfArray;
@property (nonatomic, strong) NSArray *waterNeedArray;

@property (nonatomic, strong) UIColor *savedIndicatorColor;
@property (nonatomic, strong) UIColor *wateredIndicatorColor;

@property (nonatomic, weak) IBOutlet UIScrollView *graphScrollView;
@property (nonatomic, weak) IBOutlet UIView *graphScrollContentView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphScrollContentViewWidthLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphScrollContentViewHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet UIView *savedIndicatorView;
@property (nonatomic, weak) IBOutlet UIView *wateredIndicatorView;

- (void)initializeGraph;
- (void)reloadGraph;
- (void)updateGraph;
- (void)delayedUpdateGraph:(NSTimeInterval)updateDelay;
- (void)centerCurrentMonthAnimated:(BOOL)animate;

@end

#pragma mark -

@protocol RainSensitivitySimulationGraphDelegate  <NSObject>

- (CGFloat)widthForGraphInRainSensitivitySimulationGraphVC:(RainSensitivitySimulationGraphVC*)graphVC;
- (CGFloat)heightForGraphInRainSensitivitySimulationGraphVC:(RainSensitivitySimulationGraphVC*)raphVC;

@optional

- (BOOL)generateTestDataForRainSensitivitySimulationGraphVC:(RainSensitivitySimulationGraphVC*)graphVC;

@end

