//
//  SPServerProxy.h
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

/*
 "GET /wateringRestrictions
 {
 
 ""WateringRestrictions"" : {
 
 ""hotDays"" : int , //flag not AVAIL in v3.
 ""freezeProtect"" : int //in Fahrenheit or Celsius units,
 ""months"" : ""001110010101"" //12 bit binary string. First bit is January.
 
 }
 }"
*/
 
#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "Zone.h"

@class AFHTTPRequestOperationManager;
@class StartStopWatering;
@class WaterNowZone;

@interface ServerProxy : NSObject

@property (nonatomic, weak) id<SprinklerResponseProtocol> delegate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString* serverURL;

- (id)initWithServerURL:(NSString*)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe;

- (void)requestWeatherData;

- (void)requestWaterNowZoneList;
- (void)requestWaterActionsForZone:(NSNumber*)zoneId;
- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;

- (void)requestPrograms;
- (void)deleteProgram:(int)programId;

- (void)requestZones;
- (void)saveZone:(Zone *)zone;

- (void)cancelAllOperations;

- (void)requestWateringRestrictions;

@end
