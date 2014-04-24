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
@class Program;
@class SettingsDate;

@interface ServerProxy : NSObject

@property (nonatomic, weak) id<SprinklerResponseProtocol> delegate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString* serverURL;

- (id)initWithServerURL:(NSString*)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe;

- (void)requestWeatherData;

- (void)requestWaterNowZoneList;
- (void)requestWaterActionsForZone:(NSNumber*)zoneId;
- (BOOL)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;
- (void)setRainDelay:(NSNumber*)value;
- (void)getRainDelay;

- (void)requestPrograms;
- (void)deleteProgram:(int)programId;
- (void)programCycleAndSoak:(int)programId cycles:(int)cycles soak:(int)soak_minutes cs_on:(int)cs_on;
- (void)programStationDelay:(int)programId delay:(int)delay_minutes delay_on:(int)delay_on;
- (void)saveProgram:(Program*)program;
- (void)runNowProgram:(Program*)program;

- (void)setSettingsUnits:(NSString*)unit;
- (void)requestSettingsUnits;
- (void)setSettingsDate:(SettingsDate*)unit;
- (void)requestSettingsDate;
- (void)setNewPassword:(NSString*)newPassword confirmPassword:(NSString*)confirmPassword oldPassword:(NSString*)oldPassword;

- (void)requestZones;
- (void)saveZone:(Zone *)zone;

- (void)requestAPIVersion;
- (void)requestUpdateCheckForVersion:(int)version;
- (void)requestUpdateStartForVersion:(int)version;

- (void)cancelAllOperations;
- (int)operationCount;

- (void)requestWateringRestrictions;

- (void) invalidateLogin;

@end
