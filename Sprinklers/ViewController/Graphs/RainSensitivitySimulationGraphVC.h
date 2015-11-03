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

@protocol RainSensitivitySimulationGraphDelegate;
@class RainSensitivityVC;
@class Provision;

@interface RainSensitivitySimulationGraphVC : BaseLevel2ViewController

@property (nonatomic, weak) RainSensitivityVC *parent;
@property (nonatomic, weak) id<RainSensitivitySimulationGraphDelegate> delegate;

@property (nonatomic, assign) NSInteger year;
@property (nonatomic, strong) Provision *provision;
@property (nonatomic, strong) NSArray *mixerDataByDate;

@property (nonatomic, readonly) double waterSurplus;
@property (nonatomic, readonly) double maxValue;
@property (nonatomic, readonly) NSArray *et0Array;
@property (nonatomic, readonly) NSArray *qpfArray;
@property (nonatomic, readonly) NSArray *waterNeedArray;
@property (nonatomic, readonly) NSArray *savedWaterArray;

@property (nonatomic, readonly) UIColor *savedIndicatorColor;
@property (nonatomic, readonly) UIColor *wateredIndicatorColor;
@property (nonatomic, readonly) UIColor *cloudsDarkBlueColor;

@property (nonatomic, weak) IBOutlet UIScrollView *graphScrollView;
@property (nonatomic, weak) IBOutlet UIView *graphScrollContentView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphScrollContentViewWidthLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *graphScrollContentViewHeightLayoutConstraint;
@property (nonatomic, weak) IBOutlet UIView *savedIndicatorView;
@property (nonatomic, weak) IBOutlet UIView *wateredIndicatorView;

- (void)initializeGraph;
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

