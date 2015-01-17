//
//  GraphsManager.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphsManager.h"
#import "GraphDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphStyle.h"
#import "GraphStyleBars.h"
#import "GraphStyleLines.h"
#import "GraphTimeInterval.h"
#import "GraphDataSource.h"
#import "GraphDataSourceTemperature.h"
#import "GraphDataSourceWaterConsume.h"
#import "Utils.h"
#import "Additions.h"
#import "AFNetworking.h"

NSString *kDailyWaterNeedGraphIdentifier            = @"DailyWaterNeedGraphIdentifier";
NSString *kTemperatureGraphIdentifier               = @"TemperatureGraphIdentifier";
NSString *kTotalProgramRuntimesGraphIdentifier      = @"TotalProgramRuntimesGraphIdentifier";

NSString *kEmptyGraphIdentifier                     = @"EmptyGraphIdentifier";

#pragma mark -

@interface GraphsManager ()

@property (nonatomic, strong) NSDictionary *availableGraphsDictionary;
@property (nonatomic, strong) NSArray *availableGraphs;
@property (nonatomic, strong) NSMutableArray *selectedGraphs;

- (void)registerAvailableGraphs;

@property (nonatomic, strong) ServerProxy *requestMixerDataServerProxy;
@property (nonatomic, strong) ServerProxy *requestWateringLogDetailsServerProxy;
@property (nonatomic, strong) ServerProxy *requestWateringLogSimulatedDetailsServerProxy;

- (void)requestMixerData;
- (void)requestWateringLogDetailsData;
- (void)requestWateringLogSimulatedDetailsData;

@end

#pragma mark -

@implementation GraphsManager

static GraphsManager *sharedGraphsManager = nil;

+ (GraphsManager*)sharedGraphsManager {
    if (!sharedGraphsManager) {
        sharedGraphsManager = [GraphsManager new];
        [sharedGraphsManager registerAvailableGraphs];
    }
    return sharedGraphsManager;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    return self;
}

- (void)registerAvailableGraphs {
    NSMutableArray *availableGraphs = [NSMutableArray new];
    NSMutableDictionary *availableGraphsDictionary = [NSMutableDictionary new];
    
    GraphIconsBarDescriptor *iconsBarDescriptor = nil;
    GraphValuesBarDescriptor *valuesBarDescriptor = nil;
    
    GraphDescriptor *dailyWaterNeedGraph = [GraphDescriptor defaultDescriptor];
    dailyWaterNeedGraph.graphIdentifier = kDailyWaterNeedGraphIdentifier;
    dailyWaterNeedGraph.titleAreaDescriptor.title = @"Daily Water Need";
    dailyWaterNeedGraph.titleAreaDescriptor.units = @"%";
    iconsBarDescriptor = [GraphIconsBarDescriptor defaultDescriptor];
    dailyWaterNeedGraph.iconsBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : iconsBarDescriptor};
    valuesBarDescriptor = [GraphValuesBarDescriptor defaultDescriptor];
    valuesBarDescriptor.units = [NSString stringWithFormat:@"°%@",[Utils sprinklerTemperatureUnits]];
    dailyWaterNeedGraph.valuesBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : valuesBarDescriptor};
    dailyWaterNeedGraph.displayAreaDescriptor.graphStyle = [GraphStyleBars new];
    dailyWaterNeedGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_PresetMinMaxValues;
    dailyWaterNeedGraph.displayAreaDescriptor.minValue = 0.0;
    dailyWaterNeedGraph.displayAreaDescriptor.midValue = 50.0;
    dailyWaterNeedGraph.displayAreaDescriptor.maxValue = 100.0;
    dailyWaterNeedGraph.dataSource = [GraphDataSourceWaterConsume defaultDataSource];
    [availableGraphs addObject:dailyWaterNeedGraph];
    availableGraphsDictionary[dailyWaterNeedGraph.graphIdentifier] = dailyWaterNeedGraph;
    
    GraphDescriptor *temperatureGraph = [GraphDescriptor defaultDescriptor];
    temperatureGraph.graphIdentifier = kTemperatureGraphIdentifier;
    temperatureGraph.titleAreaDescriptor.title = @"Temperature";
    temperatureGraph.titleAreaDescriptor.units = [NSString stringWithFormat:@"°%@",[Utils sprinklerTemperatureUnits]];
    temperatureGraph.displayAreaDescriptor.graphStyle = [GraphStyleLines new];
    temperatureGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_Scale;
    temperatureGraph.dataSource = [GraphDataSourceTemperature defaultDataSource];
    [availableGraphs addObject:temperatureGraph];
    availableGraphsDictionary[temperatureGraph.graphIdentifier] = temperatureGraph;
    
    GraphDescriptor *totalProgramRuntimesGraph = [GraphDescriptor defaultDescriptor];
    totalProgramRuntimesGraph.graphIdentifier = kTotalProgramRuntimesGraphIdentifier;
    totalProgramRuntimesGraph.titleAreaDescriptor.title = @"Total Program Runtimes";
    totalProgramRuntimesGraph.titleAreaDescriptor.units = @"%";
    iconsBarDescriptor = [GraphIconsBarDescriptor defaultDescriptor];
    totalProgramRuntimesGraph.iconsBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : iconsBarDescriptor};
    valuesBarDescriptor = [GraphValuesBarDescriptor defaultDescriptor];
    valuesBarDescriptor.units = [NSString stringWithFormat:@"°%@",[Utils sprinklerTemperatureUnits]];
    totalProgramRuntimesGraph.valuesBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : valuesBarDescriptor};
    totalProgramRuntimesGraph.displayAreaDescriptor.graphStyle = [GraphStyleBars new];
    totalProgramRuntimesGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_PresetMinMaxValues;
    totalProgramRuntimesGraph.displayAreaDescriptor.minValue = 0.0;
    totalProgramRuntimesGraph.displayAreaDescriptor.midValue = 50.0;
    totalProgramRuntimesGraph.displayAreaDescriptor.maxValue = 100.0;
    [availableGraphs addObject:totalProgramRuntimesGraph];
    availableGraphsDictionary[totalProgramRuntimesGraph.graphIdentifier] = totalProgramRuntimesGraph;
    
    self.availableGraphsDictionary = availableGraphsDictionary;
    self.availableGraphs = availableGraphs;
}

- (void)selectGraph:(GraphDescriptor*)graph {
    if ([self.selectedGraphs containsObject:graph]) return;
    self.selectedGraphs = [self.selectedGraphs arrayByAddingObject:graph];
}

- (void)deselectGraph:(GraphDescriptor*)graph {
    if (![self.selectedGraphs containsObject:graph]) return;
    NSMutableArray *selectedGraphs = [NSMutableArray arrayWithArray:self.selectedGraphs];
    [selectedGraphs removeObject:graph];
    self.selectedGraphs = selectedGraphs;
}

- (void)selectAllGraphs {
    if (!self.selectedGraphs.count) self.selectedGraphs = [NSArray arrayWithArray:self.availableGraphs];
}

- (void)reloadAllSelectedGraphs {
    [self requestMixerData];
    [self requestWateringLogDetailsData];
    [self requestWateringLogSimulatedDetailsData];
}

- (void)moveGraphFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    GraphDescriptor *graph = [self.selectedGraphs objectAtIndex:sourceIndex];
    
    NSMutableArray *selectedGraphs = [NSMutableArray arrayWithArray:self.selectedGraphs];
    [selectedGraphs removeObjectAtIndex:sourceIndex];
    [selectedGraphs insertObject:graph atIndex:destinationIndex];
    
    _selectedGraphs = selectedGraphs;
}

- (void)replaceGraphAtIndex:(NSInteger)index withGraph:(GraphDescriptor*)graph {
    NSMutableArray *selectedGraphs = [NSMutableArray arrayWithArray:self.selectedGraphs];
    [selectedGraphs replaceObjectAtIndex:index withObject:graph];
    
    _selectedGraphs = selectedGraphs;
}

#pragma mark - Customization

- (NSInteger)futureDays {
    return 7;
}

- (NSInteger)totalDays {
    return 365;
}

#pragma mark - Server communication

- (void)requestMixerData {
    if (self.requestMixerDataServerProxy) return;
    
    NSDate *startDate = [NSDate dateWithDaysBeforeNow:self.totalDays - self.futureDays];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:startDate];
    
    NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year,(int)dateComponents.month,(int)dateComponents.day];
    
    self.requestMixerDataServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    
    [self.requestMixerDataServerProxy requestMixerDataFromDate:dateString daysCount:self.totalDays];
}

- (void)requestWateringLogDetailsData {
    if (self.requestWateringLogDetailsServerProxy) return;
    
    NSDate *startDate = [NSDate dateWithDaysBeforeNow:self.totalDays - self.futureDays];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:startDate];
    
    NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year,(int)dateComponents.month,(int)dateComponents.day];
    
    self.requestWateringLogDetailsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    
    [self.requestWateringLogDetailsServerProxy requestWateringLogDetalsFromDate:dateString daysCount:self.totalDays];
}

- (void)requestWateringLogSimulatedDetailsData {
    if (self.requestWateringLogSimulatedDetailsServerProxy) return;
    
    NSDate *startDate = [NSDate dateWithDaysBeforeNow:self.totalDays - self.futureDays];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:startDate];
    
    NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year,(int)dateComponents.month,(int)dateComponents.day];
    
    self.requestWateringLogSimulatedDetailsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    
    [self.requestWateringLogSimulatedDetailsServerProxy requestWateringLogSimulatedDetalsFromDate:dateString daysCount:self.totalDays];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestMixerDataServerProxy) {
        self.mixerData = data;
        self.requestMixerDataServerProxy = nil;
    }
    else if (serverProxy == self.requestWateringLogDetailsServerProxy) {
        self.wateringLogDetailsData = data;
        self.requestWateringLogDetailsServerProxy = nil;
    }
    else if (serverProxy == self.requestWateringLogSimulatedDetailsServerProxy) {
        self.wateringLogSimulatedDetailsData = data;
        self.requestWateringLogSimulatedDetailsServerProxy = nil;
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestMixerDataServerProxy) self.requestMixerDataServerProxy = nil;
    else if (serverProxy == self.requestWateringLogDetailsServerProxy) self.requestWateringLogDetailsServerProxy = nil;
    else if (serverProxy == self.requestWateringLogSimulatedDetailsServerProxy) self.requestWateringLogSimulatedDetailsServerProxy = nil;
    
    [self.presentationViewController handleSprinklerNetworkError:error operation:operation showErrorMessage:YES];
}

- (void)loggedOut {
    [self.presentationViewController handleLoggedOutSprinklerError];
}

@end

#pragma mark - Empty graph descriptor

@implementation EmptyGraphDescriptor {
    CGFloat _totalGraphHeight;
}

+ (EmptyGraphDescriptor*)emptyGraphDescriptorWithTotalGraphHeight:(CGFloat)totalGraphHeight {
    return [[self alloc] initWithTotalGraphHeight:totalGraphHeight];
}

- (id)initWithTotalGraphHeight:(CGFloat)totalGraphHeight {
    self = [super init];
    if (!self) return nil;
    
    _totalGraphHeight = totalGraphHeight;
    self.graphIdentifier = kEmptyGraphIdentifier;
    
    return self;
}

- (CGFloat)totalGraphHeight {
    return _totalGraphHeight;
}

@end