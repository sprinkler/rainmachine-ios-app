//
//  GraphsManager.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphsManager.h"
#import "GraphDescriptor.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"
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
#import "Program.h"
#import "Program4.h"
#import "Utils.h"
#import "Additions.h"
#import "Constants.h"
#import "APIVersion.h"

NSString *kDailyWaterNeedGraphIdentifier            = @"DailyWaterNeedGraphIdentifier";
NSString *kTemperatureGraphIdentifier               = @"TemperatureGraphIdentifier";
NSString *kProgramRuntimeGraphIdentifier            = @"kProgramRuntimeGraphIdentifier";

NSString *kEmptyGraphIdentifier                     = @"EmptyGraphIdentifier";

NSInteger kShowAllGraphsMinAPI3Subversion           = 63;
NSInteger kMaxRequestAPIVersionRetries              = 10;

#pragma mark -

@interface GraphsManager ()

@property (nonatomic, strong) NSDictionary *availableGraphsDictionary;
@property (nonatomic, strong) NSArray *availableGraphs;
@property (nonatomic, strong) NSMutableArray *selectedGraphs;
@property (nonatomic, strong) NSMutableArray *disabledGraphIdentifiers;

- (void)registerAvailableGraphs;
- (BOOL)shouldDisplayAllGraphs;

@property (nonatomic, strong) ServerProxy *requestMixerDataServerProxy;
@property (nonatomic, strong) ServerProxy *requestWateringLogDetailsServerProxy;
@property (nonatomic, strong) ServerProxy *requestWateringLogSimulatedDetailsServerProxy;
@property (nonatomic, strong) ServerProxy *requestWeatherDataServerProxy;
@property (nonatomic, strong) ServerProxy *requestProgramsServerProxy;
@property (nonatomic, strong) ServerProxy *requestZonesServerProxy;
@property (nonatomic, strong) ServerProxy *requestAPIVersionServerProxy;
@property (nonatomic, assign) NSInteger requestAPIVersionRetries;

- (void)requestMixerData;
- (void)requestWateringLogDetailsData;
- (void)requestWateringLogSimulatedDetailsData;
- (void)requestWeatherData;
- (void)requestPrograms;
- (void)requestZones;

@property (nonatomic, strong) APIVersion *APIVersion;

- (void)registerProgramGraphsForPrograms:(NSArray*)programs;

@end

#pragma mark -

@implementation GraphsManager

static GraphsManager *sharedGraphsManager = nil;

+ (GraphsManager*)sharedGraphsManager {
    if (!sharedGraphsManager) sharedGraphsManager = [GraphsManager new];
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
    dailyWaterNeedGraph.titleAreaDescriptor.title = @"Water Demand";
    dailyWaterNeedGraph.titleAreaDescriptor.units = @"%";
    iconsBarDescriptor = [GraphIconsBarDescriptor defaultDescriptor];
    dailyWaterNeedGraph.iconsBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : iconsBarDescriptor};
    valuesBarDescriptor = [GraphValuesBarDescriptor defaultDescriptor];
    valuesBarDescriptor.units = [NSString stringWithFormat:@"°%@",[Utils sprinklerTemperatureUnits]];
    valuesBarDescriptor.valuesRoundingMode = GraphValuesRoundingMode_Round;
    dailyWaterNeedGraph.valuesBarDescriptorsDictionary = @{@(GraphTimeIntervalType_Weekly) : valuesBarDescriptor};
    dailyWaterNeedGraph.displayAreaDescriptor.graphStyle = [GraphStyleBars new];
    dailyWaterNeedGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_PresetMinMaxValues;
    dailyWaterNeedGraph.displayAreaDescriptor.minValue = 0.0;
    dailyWaterNeedGraph.displayAreaDescriptor.midValue = 50.0;
    dailyWaterNeedGraph.displayAreaDescriptor.maxValue = 100.0;
    dailyWaterNeedGraph.displayAreaDescriptor.displayAreaHeight = 106.0;
    dailyWaterNeedGraph.dateBarDescriptor.hasWeekdaysBar = @[@(GraphTimeIntervalType_Weekly)];
    dailyWaterNeedGraph.dataSource = [GraphDataSourceWaterConsume defaultDataSource];
    dailyWaterNeedGraph.canDisable = NO;
    [availableGraphs addObject:dailyWaterNeedGraph];
    availableGraphsDictionary[dailyWaterNeedGraph.graphIdentifier] = dailyWaterNeedGraph;
    
    if (self.shouldDisplayAllGraphs) {
        GraphDescriptor *temperatureGraph = [GraphDescriptor defaultDescriptor];
        temperatureGraph.graphIdentifier = kTemperatureGraphIdentifier;
        temperatureGraph.titleAreaDescriptor.title = @"Temperature";
        temperatureGraph.titleAreaDescriptor.units = [NSString stringWithFormat:@"°%@",[Utils sprinklerTemperatureUnits]];
        temperatureGraph.displayAreaDescriptor.graphStyle = [GraphStyleLines new];
        temperatureGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_Scale;
        temperatureGraph.dataSource = [GraphDataSourceTemperature defaultDataSource];
        [availableGraphs addObject:temperatureGraph];
        availableGraphsDictionary[temperatureGraph.graphIdentifier] = temperatureGraph;
    }
    
    self.availableGraphsDictionary = availableGraphsDictionary;
    self.availableGraphs = availableGraphs;
}

- (BOOL)shouldDisplayAllGraphs {
    if ([ServerProxy usesAPI4]) return YES;
    
    NSArray *versionComponents = [Utils parseApiVersion:self.APIVersion];
    if (versionComponents && [versionComponents[1] integerValue] >= kShowAllGraphsMinAPI3Subversion) return YES;
    return NO;
}

- (void)selectGraph:(GraphDescriptor*)graph {
    graph = [self.availableGraphsDictionary valueForKey:graph.graphIdentifier];
    if ([self.selectedGraphs containsObject:graph]) return;
    
    graph.isDisabled = NO;
    
    self.selectedGraphs = [self.selectedGraphs arrayByAddingObject:graph];
    
    [self.disabledGraphIdentifiers removeObject:graph.graphIdentifier];
    [[NSUserDefaults standardUserDefaults] setObject:self.disabledGraphIdentifiers forKey:kDashboardDisabledGraphIdentifiers];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)deselectGraph:(GraphDescriptor*)graph {
    graph = [self.availableGraphsDictionary valueForKey:graph.graphIdentifier];
    if (![self.selectedGraphs containsObject:graph]) return;
    
    graph.isDisabled = YES;
    
    NSMutableArray *selectedGraphs = [NSMutableArray arrayWithArray:self.selectedGraphs];
    [selectedGraphs removeObject:graph];
    self.selectedGraphs = selectedGraphs;
    
    [self.disabledGraphIdentifiers addObject:graph.graphIdentifier];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.disabledGraphIdentifiers forKey:kDashboardDisabledGraphIdentifiers];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isGraphSelected:(GraphDescriptor*)graph {
    return ![self.disabledGraphIdentifiers containsObject:graph.graphIdentifier];
}

- (void)initializeAllSelectedGraphs {
    self.disabledGraphIdentifiers = [[[NSUserDefaults standardUserDefaults] objectForKey:kDashboardDisabledGraphIdentifiers] mutableCopy];
    if (!self.disabledGraphIdentifiers) {
        self.disabledGraphIdentifiers = [NSMutableArray new];
        [[NSUserDefaults standardUserDefaults] setObject:self.disabledGraphIdentifiers forKey:kDashboardDisabledGraphIdentifiers];
    }
    
    NSMutableArray *selectedGraphs = [NSMutableArray new];
    
    for (GraphDescriptor *graph in self.availableGraphs) {
        if ([self.disabledGraphIdentifiers containsObject:graph.graphIdentifier]) {
            graph.isDisabled = YES;
            continue;
        }
        graph.isDisabled = NO;
        [selectedGraphs addObject:graph];
    }
    
    self.selectedGraphs = selectedGraphs;
}

- (void)reloadAllSelectedGraphs {
    if (self.reloadingGraphs) return;
    
    self.reloadingGraphs = YES;
    
    [self requestPrograms];
    [self requestZones];
    
    if ([ServerProxy usesAPI4]) {
        [self requestMixerData];
        [self requestWateringLogDetailsData];
        [self requestWateringLogSimulatedDetailsData];
    }
    else if ([ServerProxy usesAPI3]) {
        [self requestWeatherData];
    }
}

- (void)reregisterAllGraphs {
    [self cancel];
    
    self.disabledGraphIdentifiers = nil;
    self.selectedGraphs = nil;
    self.availableGraphs = nil;
    self.availableGraphsDictionary = nil;
    self.firstGraphsReloadFinished = NO;
    
    if ([ServerProxy usesAPI3]) {
        self.requestAPIVersionRetries = 0;
        self.requestAPIVersionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
        [self.requestAPIVersionServerProxy requestAPIVersion];
    } else {
        [self registerAvailableGraphs];
        [self initializeAllSelectedGraphs];
        [self reloadAllSelectedGraphs];
    }
}

- (void)cancel {
    [self.requestMixerDataServerProxy cancelAllOperations];
    [self.requestWateringLogDetailsServerProxy cancelAllOperations];
    [self.requestWateringLogSimulatedDetailsServerProxy cancelAllOperations];
    [self.requestWeatherDataServerProxy cancelAllOperations];
    [self.requestProgramsServerProxy cancelAllOperations];
    [self.requestZonesServerProxy cancelAllOperations];
    [self.requestAPIVersionServerProxy cancelAllOperations];
    
    self.requestMixerDataServerProxy = nil;
    self.requestWateringLogDetailsServerProxy = nil;
    self.requestWateringLogSimulatedDetailsServerProxy = nil;
    self.requestWeatherDataServerProxy = nil;
    self.requestProgramsServerProxy = nil;
    self.requestZonesServerProxy = nil;
    self.requestAPIVersionServerProxy = nil;
    
    self.reloadingGraphs = NO;
}

- (void)moveGraphFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    GraphDescriptor *graph = [self.availableGraphs objectAtIndex:sourceIndex];
    
    NSMutableArray *availableGraphs = [NSMutableArray arrayWithArray:self.availableGraphs];
    [availableGraphs removeObjectAtIndex:sourceIndex];
    [availableGraphs insertObject:graph atIndex:destinationIndex];
    
    _availableGraphs = availableGraphs;
}

- (void)replaceGraphAtIndex:(NSInteger)index withGraph:(GraphDescriptor*)graph {
    NSMutableArray *availableGraphs = [NSMutableArray arrayWithArray:self.availableGraphs];
    [availableGraphs replaceObjectAtIndex:index withObject:graph];
    
    _availableGraphs = availableGraphs;
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
    [self.requestWateringLogDetailsServerProxy requestWateringLogDetailsFromDate:self.startDateString daysCount:self.totalDays];
}

- (void)requestWateringLogSimulatedDetailsData {
    if (self.requestWateringLogSimulatedDetailsServerProxy) return;
    self.requestWateringLogSimulatedDetailsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestWateringLogSimulatedDetailsServerProxy requestWateringLogSimulatedDetailsFromDate:self.startDateString daysCount:self.totalDays];
}

- (void)requestWeatherData {
    if (self.requestWeatherDataServerProxy) return;
    self.requestWeatherDataServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestWeatherDataServerProxy requestWeatherData];
}

- (void)requestPrograms {
    if (self.requestProgramsServerProxy) return;
    self.requestProgramsServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestProgramsServerProxy requestPrograms];
}

- (void)requestZones {
    if (self.requestZonesServerProxy) return;
    self.requestZonesServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self.requestZonesServerProxy requestZones];
}

- (void)registerProgramGraphsForPrograms:(NSArray*)programs {
    if (!self.shouldDisplayAllGraphs) return;
    
    NSMutableArray *newGraphs = [NSMutableArray new];
    NSMutableDictionary *newGraphsDictionary = [NSMutableDictionary new];
    NSMutableSet *allProgramRuntimeGraphIdentifiers = [NSMutableSet new];
    
    for (Program *program in programs) {
        if (!program.active) continue;
        if (program.programId == -1) continue;
        
        NSString *graphIdentifier = [NSString stringWithFormat:@"%@%d",kProgramRuntimeGraphIdentifier,program.programId];
        [allProgramRuntimeGraphIdentifiers addObject:graphIdentifier];
        if ([self.availableGraphsDictionary valueForKey:graphIdentifier]) continue;
        
        GraphDescriptor *programRuntimeGraph = [GraphDescriptor defaultDescriptor];
        programRuntimeGraph.graphIdentifier = graphIdentifier;
        programRuntimeGraph.titleAreaDescriptor.title = program.name;
        programRuntimeGraph.titleAreaDescriptor.units = @"%";
        programRuntimeGraph.displayAreaDescriptor.graphStyle = [GraphStyleBars new];
        programRuntimeGraph.displayAreaDescriptor.scalingMode = GraphScalingMode_PresetMinMaxValues;
        programRuntimeGraph.displayAreaDescriptor.minValue = 0.0;
        programRuntimeGraph.displayAreaDescriptor.midValue = 50.0;
        programRuntimeGraph.displayAreaDescriptor.maxValue = 100.0;
        GraphDataSourceProgramRunTime *dataSource = (GraphDataSourceProgramRunTime*)[GraphDataSourceProgramRunTime defaultDataSource];
        dataSource.program = program;
        programRuntimeGraph.dataSource = dataSource;
        
        [newGraphs addObject:programRuntimeGraph];
        newGraphsDictionary[programRuntimeGraph.graphIdentifier] = programRuntimeGraph;
    }
    
    NSMutableArray *programRuntimeGraphsToRemove = [NSMutableArray new];
    NSMutableArray *programRuntimeGraphIdentifiersToRemove = [NSMutableArray new];
    
    for (GraphDescriptor *graphDescriptor in self.availableGraphs) {
        if (![graphDescriptor.graphIdentifier hasPrefix:kProgramRuntimeGraphIdentifier]) continue;
        if ([allProgramRuntimeGraphIdentifiers containsObject:graphDescriptor.graphIdentifier]) continue;
        [programRuntimeGraphsToRemove addObject:graphDescriptor];
        [programRuntimeGraphIdentifiersToRemove addObject:graphDescriptor.graphIdentifier];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"graphIdentifier" ascending:YES];
    [newGraphs sortUsingDescriptors:@[sortDescriptor]];
    
    NSMutableDictionary *availableGraphsDictionary = [self.availableGraphsDictionary mutableCopy];
    [availableGraphsDictionary addEntriesFromDictionary:newGraphsDictionary];
    [availableGraphsDictionary removeObjectsForKeys:programRuntimeGraphIdentifiersToRemove];
    self.availableGraphsDictionary = availableGraphsDictionary;
    
    NSMutableArray *availableGraphs = [self.availableGraphs mutableCopy];
    [availableGraphs addObjectsFromArray:newGraphs];
    [availableGraphs removeObjectsInArray:programRuntimeGraphsToRemove];
    self.availableGraphs = availableGraphs;
    
    [self initializeAllSelectedGraphs];
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    if (serverProxy == self.requestProgramsServerProxy) {
        self.programs = (NSArray*)data;
        self.requestProgramsServerProxy = nil;
        [self registerProgramGraphsForPrograms:self.programs];
    }
    else if (serverProxy == self.requestZonesServerProxy) {
        self.zones = (NSArray*)data;
        self.requestZonesServerProxy = nil;
    }
    else if (serverProxy == self.requestMixerDataServerProxy) {
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
    else if (serverProxy == self.requestWeatherDataServerProxy) {
        self.weatherData = data;
        self.requestWeatherDataServerProxy = nil;
    }
    else if (serverProxy == self.requestAPIVersionServerProxy) {
        self.APIVersion = (APIVersion*)data;
        self.requestAPIVersionServerProxy = nil;
        
        [self registerAvailableGraphs];
        [self initializeAllSelectedGraphs];
        [self reloadAllSelectedGraphs];
    }
    
    if (!self.requestZonesServerProxy && !self.requestProgramsServerProxy && !self.requestMixerDataServerProxy && !self.requestWateringLogDetailsServerProxy && !self.requestWateringLogSimulatedDetailsServerProxy && !self.requestWeatherDataServerProxy && !self.requestAPIVersionServerProxy) {
        if (!self.firstGraphsReloadFinished) self.firstGraphsReloadFinished = YES;
        self.reloadingGraphs = NO;
    }
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if (serverProxy == self.requestZonesServerProxy) self.requestZonesServerProxy = nil;
    else if (serverProxy == self.requestProgramsServerProxy) self.requestProgramsServerProxy = nil;
    else if (serverProxy == self.requestMixerDataServerProxy) self.requestMixerDataServerProxy = nil;
    else if (serverProxy == self.requestWateringLogDetailsServerProxy) self.requestWateringLogDetailsServerProxy = nil;
    else if (serverProxy == self.requestWateringLogSimulatedDetailsServerProxy) self.requestWateringLogSimulatedDetailsServerProxy = nil;
    else if (serverProxy == self.requestWeatherDataServerProxy) self.requestWeatherDataServerProxy = nil;
    else if (serverProxy == self.requestAPIVersionServerProxy) {
        if (self.requestAPIVersionRetries < kMaxRequestAPIVersionRetries) {
            self.requestAPIVersionRetries++;
            self.requestAPIVersionServerProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
            [self.requestAPIVersionServerProxy performSelector:@selector(requestAPIVersion) withObject:nil afterDelay:1.0];
            return;
        } else {
            self.requestAPIVersionServerProxy = nil;
            [self registerAvailableGraphs];
            [self initializeAllSelectedGraphs];
            [self reloadAllSelectedGraphs];
        }
    }
    
    if (!self.requestZonesServerProxy && !self.requestProgramsServerProxy && !self.requestMixerDataServerProxy && !self.requestWateringLogDetailsServerProxy && !self.requestWateringLogSimulatedDetailsServerProxy && !self.requestWeatherDataServerProxy && !self.requestAPIVersionServerProxy) {
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