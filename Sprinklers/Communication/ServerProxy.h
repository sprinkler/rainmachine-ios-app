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

// public static final int SC_SUCCESS = 0;
// public static final int SC_EXCEPTION_OCCURRED = 1;
// public static final int SC_NOT_AUTHENTICATED = 2;
// public static final int SC_INVALID_REQUEST = 3;
// public static final int SC_NOT_IMPLEMENTED = 4;
// public static final int SC_NOT_FOUND = 5;
// public static final int SC_DB_ERROR = 6;
// public static final int SC_PROVISION_FAILED = 7;
// public static final int SC_PASSWORD_NOT_CHANGED = 8;
typedef enum {
    API4StatusCode_Success = 0,
    API4StatusCode_ExceptionOccured = 1,
    API4StatusCode_LoggedOut = 2,
    API4StatusCode_InvalidRequest = 3,
    API4StatusCode_NotImplemented = 4,
    API4StatusCode_NotFound = 5,
    API4StatusCode_DBError = 6,
    API4StatusCode_ProvisionFailed = 7,
    API4StatusCode_PasswordNotChanged = 8
} API4StatusCode;

typedef enum {
    kAPI4ZoneVegetationType_Other = 1,
    kAPI4ZoneVegetationType_Lawn,
    kAPI4ZoneVegetationType_Fruit_Trees,
    kAPI4ZoneVegetationType_Flowers,
    kAPI4ZoneVegetationType_Vegetables,
    kAPI4ZoneVegetationType_Citrus,
    kAPI4ZoneVegetationType_Trees_And_Bushes
}kAPI4ZoneVegetationType;

typedef enum {
    kAPI4ZoneState_Idle = 0,
    kAPI4ZoneState_Watering = 1,
    kAPI4ZoneState_Pending = 2
}kAPI4ZoneState;

#import <Foundation/Foundation.h>
#import "Protocols.h"
#import "Zone.h"

@class AFHTTPRequestOperationManager;
@class StartStopWatering;
@class WaterNowZone;
@class Program;
@class Program4;
@class SettingsDate;
@class Login4Response;
@class Sprinkler;
@class WateringRestrictions;
@class HourlyRestriction;

@interface ServerProxy : NSObject

@property (nonatomic, weak) id<SprinklerResponseProtocol> delegate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString* serverURL;

- (id)initWithSprinkler:(Sprinkler *)sprinkler delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (id)initWithServerURL:(NSString *)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe;

+ (void)setSprinklerVersionMajor:(int)major minor:(int)minor subMinor:(int)subMinor;
+ (int)serverAPIMainVersion;
+ (int)usesAPI3;
+ (int)usesAPI4;
+ (NSArray*)fromJSONArray:(NSArray*)jsonArray toClass:(NSString*)className;

- (void)requestWeatherData;

- (void)requestWaterNowZoneList;
- (void)requestWaterActionsForZone:(NSNumber*)zoneId;
- (BOOL)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter;
- (BOOL)setWateringOnZone:(WaterNowZone*)zone toState:(int)state withCounter:(NSNumber*)counter;
- (void)stopAllWateringZones;
- (void)setRainDelay:(NSNumber*)value;
- (void)getRainDelay;

- (void)requestPrograms;
- (void)createProgram:(Program4*)program;
- (void)requestProgramWithId:(int)programId;
- (void)deleteProgram:(int)programId;
- (void)programCycleAndSoak:(int)programId cycles:(int)cycles soak:(int)soak_minutes cs_on:(int)cs_on;
- (void)programStationDelay:(int)programId delay:(int)delay_minutes delay_on:(int)delay_on;
- (void)saveProgram:(Program*)program;
- (void)runNowProgram:(Program*)program;
- (void)startProgram4:(Program4*)program;
- (void)stopProgram4:(Program4*)program;
    
- (void)setSettingsUnits:(NSString*)unit;
- (void)requestSettingsUnits;
- (void)setSettingsDate:(SettingsDate*)unit;
- (void)requestSettingsDate;
- (void)setNewPassword:(NSString*)newPassword confirmPassword:(NSString*)confirmPassword oldPassword:(NSString*)oldPassword;

- (void)requestZonePropertiesWithId:(int)zoneId;
- (void)requestZonesProperties;
- (void)requestZones;
- (void)saveZone:(Zone *)zone;

- (void)requestAPIVersion;
- (void)requestUpdateCheckForVersion:(int)version;
- (void)requestUpdateStartForVersion:(int)version;

- (void)cancelAllOperations;
- (int)operationCount;

- (void)requestWateringRestrictions;
- (void)postWateringRestrictions:(WateringRestrictions*)restrictions;
- (void)requestHourlyRestrictions;
- (void)createHourlyRestriction:(HourlyRestriction*)restriction;
- (void)deleteHourlyRestriction:(HourlyRestriction*)restriction;

- (void)requestCloudSprinklers:(NSDictionary*)accounts;

@end
