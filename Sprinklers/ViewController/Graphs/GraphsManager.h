//
//  GraphsManager.h
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseLevel2ViewController.h"
#import "GraphDescriptor.h"
#import "ServerProxy.h"

@interface GraphsManager : NSObject <SprinklerResponseProtocol>

@property (nonatomic, weak) BaseLevel2ViewController *presentationViewController;

@property (nonatomic, readonly) NSArray *availableGraphs;
@property (nonatomic, readonly) NSArray *selectedGraphs;
@property (nonatomic, assign) BOOL reloadingGraphs;
@property (nonatomic, assign) BOOL firstGraphsReloadFinished;

+ (GraphsManager*)sharedGraphsManager;
- (void)selectGraph:(GraphDescriptor*)graph;
- (void)deselectGraph:(GraphDescriptor*)graph;
- (BOOL)isGraphSelected:(GraphDescriptor*)graph;
- (void)initializeAllSelectedGraphs;
- (void)reloadAllSelectedGraphs;
- (void)reregisterAllGraphs;
- (void)cancel;

- (void)moveGraphFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;
- (void)replaceGraphAtIndex:(NSInteger)index withGraph:(GraphDescriptor*)graph;

@property (nonatomic, readonly) NSInteger futureDays;
@property (nonatomic, readonly) NSInteger totalDays;
@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, readonly) NSString *startDateString;

@property (nonatomic, strong) NSArray *programs;
@property (nonatomic, strong) NSArray *zones;
@property (nonatomic, strong) id mixerData;
@property (nonatomic, strong) id wateringLogDetailsData;
@property (nonatomic, strong) id wateringLogSimulatedDetailsData;
@property (nonatomic, strong) id weatherData;

@end

#pragma mark

@interface EmptyGraphDescriptor : GraphDescriptor

+ (EmptyGraphDescriptor*)emptyGraphDescriptorWithTotalGraphHeight:(CGFloat)totalGraphHeight;

@end

