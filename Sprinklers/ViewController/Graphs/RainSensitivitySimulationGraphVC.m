//
//  RainSensitivitySimulationGraphVC.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "RainSensitivitySimulationGraphVC.h"
#import "RainSensitivityVC.h"
#import "SettingsVC.h"
#import "RainSensitivityGraphMonthCell.h"
#import "Constants.h"
#import "Additions.h"
#import "MixerDailyValue.h"
#import "Provision.h"
#import "ProvisionLocation.h"

#pragma mark -

@interface RainSensitivitySimulationGraphVC ()

@property (nonatomic, strong) NSDictionary *mixerValuesByDate;
@property (nonatomic, strong) NSArray *graphMonthCells;

- (NSDictionary*)generateTestData:(double*)et0Average;

@property (nonatomic, assign) BOOL didLayoutSubviews;
@property (nonatomic, assign) BOOL shouldCenterGraphAfterLayoutSubviews;
@property (nonatomic, assign) BOOL delayedUpdateGraphInProgress;

@property (nonatomic, assign) double waterSurplus;
@property (nonatomic, assign) double maxValue;
@property (nonatomic, assign) double et0Average;
@property (nonatomic, strong) NSArray *et0Array;
@property (nonatomic, strong) NSArray *qpfArray;
@property (nonatomic, strong) NSArray *waterNeedArray;
@property (nonatomic, strong) NSArray *savedWaterArray;
@property (nonatomic, strong) NSArray *monthDays;

- (void)calculateMixerValuesByDate;
- (void)createGraphMonthCells;
- (void)calculateGraphVariables;
- (void)updateGraphVariables;

@property (nonatomic, strong) UIColor *savedIndicatorColor;
@property (nonatomic, strong) UIColor *wateredIndicatorColor;
@property (nonatomic, strong) UIColor *cloudsDarkBlueColor;

@end

#pragma mark -

@implementation RainSensitivitySimulationGraphVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.savedIndicatorColor = [UIColor colorWithRed:11.0 / 255.0 green:100.0 / 255.0 blue:126.0 / 255.0 alpha:1.0];
    self.wateredIndicatorColor = [UIColor colorWithRed:24.0 / 255.0 green:155.0 / 255.0 blue:202.0 / 255.0 alpha:1.0];
    self.cloudsDarkBlueColor = [UIColor colorWithRed:11.0 / 255.0 green:100.0 / 255.0 blue:126.0 / 255.0 alpha:1.0];
    
    self.savedIndicatorView.backgroundColor = self.savedIndicatorColor;
    self.wateredIndicatorView.backgroundColor = self.wateredIndicatorColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.didLayoutSubviews = YES;
    if (self.shouldCenterGraphAfterLayoutSubviews) {
        [self centerCurrentMonthAnimated:NO];
        self.shouldCenterGraphAfterLayoutSubviews = NO;
    }
}

#pragma mark - Methods

- (void)initializeGraph {
    [self calculateMixerValuesByDate];
    [self createGraphMonthCells];
    [self calculateGraphVariables];
    
    for (RainSensitivityGraphMonthCell *graphMonthCell in self.graphMonthCells) {
        [graphMonthCell calculateValues];
        [graphMonthCell draw];
    }
}

- (void)updateGraph {
    [self updateGraphVariables];
    
    for (RainSensitivityGraphMonthCell *graphMonthCell in self.graphMonthCells) {
        [graphMonthCell calculateValues];
        [graphMonthCell draw];
        
    }
    self.delayedUpdateGraphInProgress = NO;
}

- (void)delayedUpdateGraph:(NSTimeInterval)updateDelay {
    if (self.delayedUpdateGraphInProgress) return;
    [self performSelector:@selector(updateGraph) withObject:nil afterDelay:updateDelay inModes:@[NSRunLoopCommonModes]];
    self.delayedUpdateGraphInProgress = YES;
}

- (void)centerCurrentMonthAnimated:(BOOL)animate {
    if (!self.didLayoutSubviews) {
        self.shouldCenterGraphAfterLayoutSubviews = YES;
        return;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMonth fromDate:[NSDate date]];
    
    if (dateComponents.month > self.graphMonthCells.count) return;
    
    RainSensitivityGraphMonthCell *graphMonthCellToCenter = self.graphMonthCells[dateComponents.month - 1];
    CGFloat centerX = graphMonthCellToCenter.frame.origin.x + round(graphMonthCellToCenter.frame.size.width / 2.0);
    CGFloat startX = centerX - round(self.graphScrollView.frame.size.width / 2.0);
    if (startX < 0.0) startX = 0.0;
    if (startX + self.graphScrollView.frame.size.width >= self.graphScrollContentViewWidthLayoutConstraint.constant) {
        startX = self.graphScrollContentViewWidthLayoutConstraint.constant - self.graphScrollView.frame.size.width;
    }
    if (startX < 0.0) startX = 0.0;
    
    [self.graphScrollView setContentOffset:CGPointMake(startX, 0.0) animated:animate];
}

#pragma mark - Helper methods

- (void)calculateMixerValuesByDate {
    if ([self.delegate respondsToSelector:@selector(generateTestDataForRainSensitivitySimulationGraphVC:)] && [self.delegate generateTestDataForRainSensitivitySimulationGraphVC:self]) {
        double et0Average = 0.0;
        self.mixerValuesByDate = [self generateTestData:&et0Average];
        self.et0Average = et0Average;
        return;
    }
    
    NSMutableDictionary *mixerValuesByDate = [NSMutableDictionary new];
    
    for (MixerDailyValue *mixerDailyValue in self.mixerDataByDate) {
        NSString *dayString = [[NSDate sharedDateFormatterAPI4] stringFromDate:mixerDailyValue.day];
        if (!dayString.length) continue;
        [mixerValuesByDate setValue:mixerDailyValue forKey:dayString];
    }
    
    self.mixerValuesByDate = mixerValuesByDate;
    self.et0Average = self.provision.location.et0Average;
}

- (void)createGraphMonthCells {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [NSDateComponents new];
    
    CGFloat graphMonthCellWidth = [self.delegate widthForGraphInRainSensitivitySimulationGraphVC:self];
    CGFloat graphMonthCellHeight = self.graphScrollContentView.frame.size.height;
    
    NSMutableArray *graphMonthCells = [NSMutableArray new];
    
    NSInteger firstDayIndex = 0;
    
    for (NSInteger month = 0; month < 12; month++) {
        dateComponents.month = month + 1;
        
        NSRange monthRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[calendar dateFromComponents:dateComponents]];
        
        RainSensitivityGraphMonthCell *graphMonthCell = [RainSensitivityGraphMonthCell newGraphMonthCell];
        graphMonthCell.rainSensitivitySimulationGraph = self;
        graphMonthCell.month = month;
        graphMonthCell.firstDayIndex = firstDayIndex;
        graphMonthCell.numberOfDays = monthRange.length;
        graphMonthCell.monthLabel.text = monthsOfYear[month].uppercaseString;
        graphMonthCell.translatesAutoresizingMaskIntoConstraints = NO;
        
        graphMonthCell.trailingSeparatorView.hidden = (month > 0);
        
        CGFloat graphMonthCellX = month * graphMonthCellWidth;
        graphMonthCell.frame = CGRectMake(graphMonthCellX, 0.0, graphMonthCellWidth, graphMonthCellHeight);
        
        [self.graphScrollContentView addSubview:graphMonthCell];
        [graphMonthCells addObject:graphMonthCell];
        
        firstDayIndex += monthRange.length;
        
        if ([[UIDevice currentDevice] iOSGreaterThan:8.0]) {
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[graphMonthCell]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphMonthCell)]];
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[graphMonthCell]",graphMonthCellX] options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphMonthCell)]];
            [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[graphMonthCell(==%lf)]",graphMonthCellWidth] options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphMonthCell)]];
        } else {
            [self.graphScrollContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[graphMonthCell]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphMonthCell)]];
            [self.graphScrollContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%lf-[graphMonthCell]",graphMonthCellX] options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphMonthCell)]];
            [self.graphScrollContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[graphMonthCell(==%lf)]",graphMonthCellWidth] options:0 metrics:nil views:NSDictionaryOfVariableBindings(graphMonthCell)]];
        }
    }
    
    self.graphScrollContentViewWidthLayoutConstraint.constant = 12.0 * graphMonthCellWidth;
    self.graphScrollContentViewHeightLayoutConstraint.constant = [self.delegate heightForGraphInRainSensitivitySimulationGraphVC:self] - 30.0;
    
    self.graphMonthCells = graphMonthCells;
}

- (void)calculateGraphVariables {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [NSDateComponents new];
    
    double et0Average = self.et0Average;
    if (et0Average == 0.0) et0Average = 1.0;
    
    double rainSensitivity = self.provision.location.rainSensitivity;
    NSInteger wsDays = self.provision.location.wsDays;
    double waterSurplus = 0.0;
    
    NSMutableArray *et0Array = [NSMutableArray new];
    NSMutableArray *qpfArray = [NSMutableArray new];
    NSMutableArray *waterNeedArray = [NSMutableArray new];
    NSMutableArray *savedWaterArray = [NSMutableArray new];
    NSMutableArray *monthDays = [NSMutableArray new];
    
    double maxValue = 0.0;
    
    for (NSInteger month = 0; month < 12; month++) {
        dateComponents.month = month + 1;
        
        NSRange monthRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[calendar dateFromComponents:dateComponents]];
        double savedWater = 0.0;
        
        for (NSInteger day = 0; day < monthRange.length; day++) {
            NSString *dayString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)self.year, (int)month + 1, (int)day + 1];
            MixerDailyValue *mixerDailyValue = [self.mixerValuesByDate valueForKey:dayString];
            
            if (!mixerDailyValue) {
                [et0Array addObject:[NSNull null]];
                [qpfArray addObject:[NSNull null]];
                [waterNeedArray addObject:[NSNull null]];
                continue;
            }
            
            double waterNeed = mixerDailyValue.et0.doubleValue - rainSensitivity * mixerDailyValue.qpf.doubleValue - waterSurplus;
            if (waterNeed < 0) {
                waterSurplus = MIN(-waterNeed, wsDays * et0Average);
                waterNeed = 0.0;
            }
            
            double et0Value = mixerDailyValue.et0.doubleValue / et0Average;
            double qpfValue = mixerDailyValue.qpf.doubleValue;
            double waterNeedValue = waterNeed / et0Average;
            
            maxValue = MAX(maxValue, MAX(et0Value, waterNeedValue));
            
            [et0Array addObject:@(et0Value)];
            [qpfArray addObject:@(qpfValue)];
            [waterNeedArray addObject:@(waterNeedValue)];
            
            savedWater += (mixerDailyValue.et0.doubleValue - waterNeed);
        }
        
        [monthDays addObject:@(monthRange.length)];
        [savedWaterArray addObject:@(savedWater)];
    }
    
    self.monthDays = monthDays;
    
    self.waterSurplus = waterSurplus;
    self.et0Array = et0Array;
    self.qpfArray = qpfArray;
    self.waterNeedArray = waterNeedArray;
    self.savedWaterArray = savedWaterArray;
    
    self.maxValue = maxValue;
}

- (void)updateGraphVariables {
    NSMutableArray *waterNeedArray = [NSMutableArray new];
    NSMutableArray *savedWaterArray = [NSMutableArray new];
    
    double et0Average = self.et0Average;
    if (et0Average == 0.0) et0Average = 1.0;
    
    double rainSensitivity = self.provision.location.rainSensitivity;
    NSInteger wsDays = self.provision.location.wsDays;
    double waterSurplus = 0.0;
    
    NSEnumerator *et0Enumerator = self.et0Array.objectEnumerator;
    NSEnumerator *qpfEnumerator = self.qpfArray.objectEnumerator;
    
    for (NSInteger month = 0; month < 12; month++) {
        double savedWater = 0.0;
        
        for (NSInteger day = 0; day < [self.monthDays[month] integerValue]; day++) {
            id et0 = [et0Enumerator nextObject];
            id qpf = [qpfEnumerator nextObject];
            
            if (et0 == [NSNull null] || qpf == [NSNull null]) {
                [waterNeedArray addObject:[NSNull null]];
                continue;
            }
            
            if (!et0 || !qpf) return;
            
            double et0Value = ((NSNumber*)et0).doubleValue * et0Average;
            double qpfValue = ((NSNumber*)qpf).doubleValue;
            
            double waterNeed = et0Value - rainSensitivity * qpfValue - waterSurplus;
            if (waterNeed < 0) {
                waterSurplus = MIN(-waterNeed, wsDays * et0Average);
                waterNeed = 0.0;
            }
            
            [waterNeedArray addObject:@(waterNeed / et0Average)];
            
            savedWater += et0Value - waterNeed;
        }
        
        [savedWaterArray addObject:@(savedWater)];
    }
    
    self.waterSurplus = waterSurplus;
    self.waterNeedArray = waterNeedArray;
    self.savedWaterArray = savedWaterArray;
}

- (NSDictionary*)generateTestData:(double*)et0Average {
    double et0AverageValue = 0.0;
    NSInteger et0Count = 0;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [NSDateComponents new];
    
    NSMutableDictionary *mixerDataByDateTestData = [NSMutableDictionary new];
    
    for (NSInteger month = 0; month < 12; month++) {
        double TestDataMinEt0 = 1.0;
        double TestDataEt0Interval = 2.0 + (double)rand() / RAND_MAX * 2.0;
        double TestDataMinQpf = 1.0;
        double TestDataQpfInterval = 1.0 + (double)rand() / RAND_MAX * 3.0;
        
        dateComponents.month = month + 1;
        
        NSRange monthRange = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[calendar dateFromComponents:dateComponents]];
        
        for (NSInteger day = 0; day < monthRange.length; day++) {
            NSString *dayString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)self.year, (int)month + 1, (int)day + 1];
            
            MixerDailyValue *mixerDailyValue = [MixerDailyValue new];
            mixerDailyValue.et0 = @((double)rand() / (double)RAND_MAX * TestDataEt0Interval + TestDataMinEt0);
            mixerDailyValue.qpf = @((double)rand() / (double)RAND_MAX * TestDataQpfInterval + TestDataMinQpf);
            
            mixerDataByDateTestData[dayString] = mixerDailyValue;
            
            et0AverageValue += mixerDailyValue.et0.doubleValue;
            et0Count++;
        }
    }
    
    et0AverageValue /= et0Count;
    
    if (et0Average) *et0Average = et0AverageValue;
    
    return mixerDataByDateTestData;
}

@end
