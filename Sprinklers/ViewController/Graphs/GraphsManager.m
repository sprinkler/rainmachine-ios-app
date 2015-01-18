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
#import "GraphDataSourceProgramRunTime.h"
#import "WaterLogDay.h"
#import "WaterLogProgram.h"
#import "Utils.h"
#import "Additions.h"
#import "AFNetworking.h"

NSString *kDailyWaterNeedGraphIdentifier            = @"DailyWaterNeedGraphIdentifier";
NSString *kTemperatureGraphIdentifier               = @"TemperatureGraphIdentifier";
NSString *kProgramRuntimeGraphIdentifier            = @"kProgramRuntimeGraphIdentifier";

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

- (void)registerProgramGraphsForProgramIDs:(NSArray*)programIDs;
- (void)registerProgramGraphsForWaterLogDays:(NSArray*)waterLogDays;

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
    self.selectedGraphs = [NSArray arrayWithArray:self.availableGraphs];
}

- (void)reloadAllSelectedGraphs {
    if (self.reloadingGraphs) return;
    
    self.reloadingGraphs = YES;
    
    [self requestMixerData];
    [self requestWateringLogDetailsData];
    [self requestWateringLogSimulatedDetailsData];
}

- (void)reregisterAllGraphs {
    self.availableGraphs = nil;
    self.availableGraphsDictionary = nil;
    self.firstGraphsReloadFinished = NO;
    [self registerAvailableGraphs];
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

- (NSDate*)startDate {
    return [NSDate dateWithDaysBeforeNow:self.totalDays - self.futureDays];
}

- (NSString*)startDateString {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.startDate];
    return [NSString stringWithFormat:@"%d-%02d-%02d", (int)dateComponents.year,(int)dateComponents.month,(int)dateComponents.day];
}


#pragma mark - Server communication

- (void)requestMixerData {
    if (self.requestMixerDataServerProxy) return;
    self.requestMixerDataServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestMixerDataServerProxy requestMixerDataFromDate:self.startDateString daysCount:self.totalDays];
}

- (void)requestWateringLogDetailsData {
    if (self.requestWateringLogDetailsServerProxy) return;
    self.requestWateringLogDetailsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestWateringLogDetailsServerProxy requestWateringLogDetalsFromDate:self.startDateString daysCount:self.totalDays];
}

- (void)requestWateringLogSimulatedDetailsData {
    if (self.requestWateringLogSimulatedDetailsServerProxy) return;
    self.requestWateringLogSimulatedDetailsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestWateringLogSimulatedDetailsServerProxy requestWateringLogSimulatedDetalsFromDate:self.startDateString daysCount:self.totalDays];
}

- (void)registerProgramGraphsForProgramIDs:(NSArray*)programIDs {
    NSMutableArray *newGraphs = [NSMutableArray new];
    NSMutableDictionary *newGraphsDictionary = [NSMutableDictionary new];
    
    for (NSNumber *programID in programIDs) {
        NSString *graphIdentifier = [NSString stringWithFormat:@"%@%@",kProgramRuntimeGraphIdentifier,programID];
        if ([self.availableGraphsDictionary valueForKey:graphIdentifier]) continue;
        
        GraphDescriptor *programRuntimeGraph = [GraphDescriptor defaultDescriptor];
        programRuntimeGraph.graphIdentifier = graphIdentifier;
        programRuntimeGraph.titleAreaDescriptor.title = [NSString stringWithFormat:@"Program %@",programID];
        programRuntimeGraph.titleAreaDescriptor.units = @"%";
        GraphIconsBarDescriptor *iconsBarDescriptor = [GraphIconsBarDescriptor defaultDescriptor];
        programRuntimeGraph.iconsBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : iconsBarDescriptor};
        GraphValuesBarDescriptor *valuesBarDescriptor = [GraphValuesBarDescriptor defaultDescriptor];
        valuesBarDescriptor.units = [NSString stringWithFormat:@"°%@",[Utils sprinklerTemperatureUnits]];
        programRuntimeGraph.valuesBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : valuesBarDescriptor};
        programRuntimeGraph.displayAreaDescriptor.graphStyle = [GraphStyleBars new];
        programRuntimeGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_PresetMinMaxValues;
        programRuntimeGraph.displayAreaDescriptor.minValue = 0.0;
        programRuntimeGraph.displayAreaDescriptor.midValue = 50.0;
        programRuntimeGraph.displayAreaDescriptor.maxValue = 100.0;
        GraphDataSourceProgramRunTime *dataSource = (GraphDataSourceProgramRunTime*)[GraphDataSourceProgramRunTime defaultDataSource];
        dataSource.programID = programID.intValue;
        programRuntimeGraph.dataSource = dataSource;
        
        [newGraphs addObject:programRuntimeGraph];
        newGraphsDictionary[programRuntimeGraph.graphIdentifier] = programRuntimeGraph;
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"graphIdentifier" ascending:YES];
    [newGraphs sortUsingDescriptors:@[sortDescriptor]];
    
    NSMutableDictionary *availableGraphsDictionary = [self.availableGraphsDictionary mutableCopy];
    [availableGraphsDictionary addEntriesFromDictionary:newGraphsDictionary];
    self.availableGraphsDictionary = availableGraphsDictionary;
    
    NSMutableArray *availableGraphs = [self.availableGraphs mutableCopy];
    [availableGraphs addObjectsFromArray:newGraphs];
    self.availableGraphs = availableGraphs;
    
    [self selectAllGraphs];
}

- (void)registerProgramGraphsForWaterLogDays:(NSArray*)waterLogDays {
    NSMutableDictionary *programIDs = [NSMutableDictionary dictionary];
    
    for (WaterLogDay *waterLogDay in waterLogDays) {
        [programIDs addEntriesFromDictionary:waterLogDay.programIDs];
    }
    
    NSMutableArray *programIDsArray = [NSMutableArray arrayWithArray:programIDs.allKeys];
    [programIDsArray sortedArrayUsingSelector:@selector(compare:)];
    
    [self registerProgramGraphsForProgramIDs:programIDsArray];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestMixerDataServerProxy) {
        self.mixerData = data;
        self.requestMixerDataServerProxy = nil;
    }
    else if (serverProxy == self.requestWateringLogDetailsServerProxy) {
        [self registerProgramGraphsForWaterLogDays:(NSArray*)data];
        self.wateringLogDetailsData = data;
        self.requestWateringLogDetailsServerProxy = nil;
    }
    else if (serverProxy == self.requestWateringLogSimulatedDetailsServerProxy) {
        self.wateringLogSimulatedDetailsData = data;
        self.requestWateringLogSimulatedDetailsServerProxy = nil;
    }
    
    if (!self.requestMixerDataServerProxy && !self.requestWateringLogDetailsServerProxy && !self.requestWateringLogSimulatedDetailsServerProxy) {
        if (!self.firstGraphsReloadFinished) self.firstGraphsReloadFinished = YES;
        self.reloadingGraphs = NO;
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestMixerDataServerProxy) self.requestMixerDataServerProxy = nil;
    else if (serverProxy == self.requestWateringLogDetailsServerProxy) self.requestWateringLogDetailsServerProxy = nil;
    else if (serverProxy == self.requestWateringLogSimulatedDetailsServerProxy) self.requestWateringLogSimulatedDetailsServerProxy = nil;
    
    if (!self.requestMixerDataServerProxy && !self.requestWateringLogDetailsServerProxy && !self.requestWateringLogSimulatedDetailsServerProxy) {
        if (!self.firstGraphsReloadFinished) self.firstGraphsReloadFinished = YES;
        self.reloadingGraphs = NO;
    }
    
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