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
@class Provision;
@class Parser;
@class CloudSettings;

@interface ServerProxy : NSObject

@property (nonatomic, weak) id<SprinklerResponseProtocol> delegate;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@property (nonatomic, strong) NSString* serverURL;

- (id)initWithSprinkler:(Sprinkler *)sprinkler delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (id)initWithServerURL:(NSString *)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest;
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe;

+ (void)setSprinklerVersionMajor:(int)major minor:(int)minor subMinor:(int)subMinor;
+ (void)pushSprinklerVersion;
+ (void)popSprinklerVersion;
+ (int)serverAPIMainVersion;
+ (int)usesAPI3;
+ (int)usesAPI4;
+ (NSArray*)fromJSONArray:(NSArray*)jsonArray toClass:(NSString*)className;
+ (id)fromJSON:(NSDictionary*)jsonDic toClass:(NSString*)className;

- (void)requestWeatherData;
- (void)requestDailyStatsDetails;

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
- (void)stopAllPrograms4;

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
- (void)requestAPIVersionWithTimeoutInterval:(NSTimeInterval)timeoutInterval;
- (void)requestUpdateCheckForVersion:(int)version;
- (void)requestUpdateStartForVersion:(int)version;
- (void)reboot;

- (void)cancelAllOperations;
- (int)operationCount;

- (void)requestWateringRestrictions;
- (void)postWateringRestrictions:(WateringRestrictions*)restrictions;
- (void)requestHourlyRestrictions;
- (void)createHourlyRestriction:(HourlyRestriction*)restriction includeUID:(BOOL)includeUID;
- (void)deleteHourlyRestriction:(HourlyRestriction*)restriction;

- (void)requestDiag;
- (void)requestDiagWithTimeoutInterval:(NSTimeInterval)timeoutInterval;
- (void)requestCurrentWiFi;
- (void)requestAvailableWiFis;
- (void)setWiFiWithSSID:(NSString*)ssid encryption:(NSString*)encryption key:(NSString*)password;
- (void)setProvisionName:(NSString*)name;

- (void)requestProvision;
- (void)saveRainSensitivityFromProvision:(Provision*)provision;

- (void)setLocation:(double)latitude longitude:(double)longitude timezone:(NSString*)timezone;
- (void)setTimezone:(NSString*)timezone;

- (void)requestMixerDataFromDate:(NSString*)dateString daysCount:(NSInteger)daysCount;
- (void)requestWateringLogDetailsFromDate:(NSString*)dateString daysCount:(NSInteger)daysCount;
- (void)requestWateringLogSimulatedDetailsFromDate:(NSString*)dateString daysCount:(NSInteger)daysCount;

- (void)validateEmail:(NSString*)email deviceName:(NSString*)deviceName mac:(NSString*)mac;
- (void)requestCloudSprinklers:(NSDictionary*)accounts;
- (void)requestCloudSettings;
- (void)saveCloudSettings:(CloudSettings*)cloudSettings;
- (void)enableRemoteAccess:(BOOL)enable;
- (void)saveCloudEmail:(NSString*)email;

- (void)provisionReset;

- (void)requestParsers;
- (void)activateParser:(Parser*)parser activate:(BOOL)activate;
- (void)saveParserParams:(Parser*)parser;

- (void)sendDiagnostics;

@end
