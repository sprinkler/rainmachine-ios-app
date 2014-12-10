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

NSString *kTemperatureGraphIdentifier               = @"TemperatureGraphIdentifier";
NSString *kTotalProgramRuntimesGraphIdentifier      = @"TotalProgramRuntimesGraphIdentifier";

#pragma mark -

@interface GraphsManager ()

@property (nonatomic, strong) NSDictionary *availableGraphsDictionary;
@property (nonatomic, strong) NSArray *availableGraphs;
@property (nonatomic, strong) NSArray *selectedGraphs;

- (void)registerAvailableGraphs;

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
    
    [self registerAvailableGraphs];
    
    return self;
}

- (void)registerAvailableGraphs {
    NSMutableArray *availableGraphs = [NSMutableArray new];
    NSMutableDictionary *availableGraphsDictionary = [NSMutableDictionary new];
    
    GraphDescriptor *temperatureGraph = [GraphDescriptor defaultDescriptor];
    temperatureGraph.graphIdentifier = kTemperatureGraphIdentifier;
    temperatureGraph.titleAreaDescriptor.title = @"Temperature";
    temperatureGraph.titleAreaDescriptor.units = @"°F";
    temperatureGraph.displayAreaDescriptor.graphStyle = [GraphStyleLines new];
    [availableGraphs addObject:temperatureGraph];
    [availableGraphsDictionary setValue:temperatureGraph forKey:temperatureGraph.graphIdentifier];
    
    GraphDescriptor *totalProgramRuntimesGraph = [GraphDescriptor defaultDescriptor];
    totalProgramRuntimesGraph.graphIdentifier = kTotalProgramRuntimesGraphIdentifier;
    totalProgramRuntimesGraph.titleAreaDescriptor.title = @"Total Program Runtimes";
    totalProgramRuntimesGraph.titleAreaDescriptor.units = @"%";
    totalProgramRuntimesGraph.iconsBarDescriptor = [GraphIconsBarDescriptor defaultDescriptor];
    totalProgramRuntimesGraph.valuesBarDescriptor = [GraphValuesBarDescriptor defaultDescriptor];
    totalProgramRuntimesGraph.valuesBarDescriptor.units = @"°F";
    totalProgramRuntimesGraph.displayAreaDescriptor.graphStyle = [GraphStyleBars new];
    [availableGraphs addObject:totalProgramRuntimesGraph];
    [availableGraphsDictionary setValue:totalProgramRuntimesGraph forKey:totalProgramRuntimesGraph.graphIdentifier];
    
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

#pragma mark - Randomize test data

static BOOL GraphsManagerRandomizeTestData = NO;

+ (void)setRandomizeTestData:(BOOL)randomizeTestData {
    srand((unsigned)time(NULL));
    GraphsManagerRandomizeTestData = randomizeTestData;
    sharedGraphsManager = nil;
}

+ (BOOL)randomizeTestData {
    return GraphsManagerRandomizeTestData;
}

@end
