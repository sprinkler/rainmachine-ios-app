//
//  ProvisionSystem.h
//  Sprinklers
//
//  Created by Istvan Sipos on 21/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProvisionSystem : NSObject

@property (nonatomic, assign) BOOL httpEnabled;
@property (nonatomic, assign) BOOL useCommandLineArguments;
@property (nonatomic, assign) int hardwareVersion;
@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic, assign) BOOL programListShowInactive;
@property (nonatomic, assign) BOOL programZonesShowInactive;
@property (nonatomic, assign) BOOL useMasterValve;
@property (nonatomic, assign) int masterValveBefore;
@property (nonatomic, assign) BOOL wizardHasRun;
@property (nonatomic, strong) NSString *apiVersion;
@property (nonatomic, assign) double maxWateringCoef;
@property (nonatomic, assign) int masterValveAfter;
@property (nonatomic, assign) BOOL managedMode;
@property (nonatomic, assign) BOOL zoneListShowInactive;
@property (nonatomic, assign) BOOL selfTest;
@property (nonatomic, strong) NSString *netName;
@property (nonatomic, assign) int localValveCount;
@property (nonatomic, strong) NSArray *zoneDuration;
@property (nonatomic, assign) BOOL keepDataHistory;
@property (nonatomic, assign) BOOL useRainSensor;

+ (ProvisionSystem*)createFromJson:(NSDictionary*)jsonObj;

@end
