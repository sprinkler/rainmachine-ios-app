//
//  SPUtils.h
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"
#import "DevicesCellType1.h"

@class WaterNowZone;
@class Sprinkler;
@class SettingsDate;
@class WiFi;
@class CloudSettings;

@interface Utils : NSObject

+ (NSString*)sprinklerURL:(Sprinkler*)sprinkler;
+ (NSString*)currentSprinklerURL;
+ (Sprinkler *)currentSprinkler;

+ (BOOL)isSprinklerInAPMode:(Sprinkler*)sprinkler;
+ (BOOL)isDeviceInactive:(Sprinkler*)sprinkler;
+ (BOOL)isManuallyAddedDevice:(Sprinkler*)sprinkler;
+ (BOOL)isCloudDevice:(Sprinkler*)sprinkler;
+ (BOOL)isLocallyDiscoveredDevice:(Sprinkler*)sprinkler;
+ (NSString*)fixedZoneName:(NSString *)zoneName withId:(NSNumber*)theId;
+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter isIdle:(BOOL)isIdle;
+ (int)fixedRoundedToMinutesZoneCounter:(NSNumber*)counter isIdle:(BOOL)isIdle;
+ (BOOL)isZoneWatering:(WaterNowZone*)zone;
+ (BOOL)isZonePending:(WaterNowZone*)zone;
+ (BOOL)isZoneIdle:(WaterNowZone*)zone;
+ (NSString*)getPort:(NSString*)address;
+ (NSString*)getBaseUrl:(NSString*)address;
+ (NSString*)addressWithoutPrefix:(NSString*)address;
+ (NSString*)activeDevicesPredicate;
+ (NSString*)inactiveDevicesPredicate;
+ (NSString*)fixedSprinklerAddress:(NSString*)address;
+ (NSArray*)remoteSprinklersFilter:(NSArray*)sprinklers;
+ (NSString*)daysStringFromWeekdaysFrequency:(NSString *)weekdays;
+ (NSString*)monthsStringFromMonthsFrequency:(NSString *)months;
+ (NSString*)formattedTime:(NSDate*)date forTimeFormat:(int)timeFormat;
+ (NSString*)formattedTimeFromSeconds:(int)seconds;
+ (NSDateFormatter*)sprinklerDateFormatterForTimeFormat:(NSNumber*)time_format;
+ (NSDateFormatter*)sprinklerDateFormatterForTimeFormat:(NSNumber*)time_format seconds:(BOOL)seconds;
+ (NSDateFormatter*)sprinklerDateFormatterForTimeFormat:(NSNumber*)time_format seconds:(BOOL)seconds forceOnlyTimePart:(BOOL)forceOnlyTimePart forceOnlyDatePart:(BOOL)forceOnlyDatePart;
+ (SettingsDate*)fixedSettingsDate:(SettingsDate*)settingsDate;
+ (void)showNotSupportedDeviceAlertView:(id /*<UIAlertViewDelegate>*/)delegate;
+ (NSArray*)parseApiVersion:(id)data;
+ (int)deviceGreyOutRetryCount;

+ (DevicesCellType1*)configureSprinklerCellForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath sprinkler:(Sprinkler*)sprinkler canEditRow:(BOOL)canEditRow forceHiddenDisclosure:(BOOL)forceHiddenDisclosure;

+ (NSString*)sprinklerUnits;
+ (NSString*)sprinklerTemperatureUnits;
+ (NSString*)sprinklerLengthUnits;
+ (void)setSprinklerTemperatureUnits:(NSString*)units;

+ (UIView*)customSprinklerTitleWithOutDeviceView:(UILabel**)lblDeviceName outDeviceAddressView:(UILabel**)lblDeviceAddress;

+ (UIImage*)waterWavesImage:(float)height;
+ (UIImage*)waterImage:(float)height;

+ (int)checkOSVersion;
+ (BOOL)isDevice357Plus;
+ (BOOL)isDevice359Plus;
+ (BOOL)isDevice360Plus;

+ (void)invalidateLoginForCurrentSprinkler;
+ (void)clearRememberMeFlagForSprinkler:(Sprinkler*)sprinkler;
+ (BOOL)isConnectionFailToServerError:(NSError*)error;
+ (BOOL)hasOperationInternalServerErrorStatusCode:(AFHTTPRequestOperation *)operation;

+ (UIImage*)weatherImageFromCode:(NSNumber*)cod;
+ (UIImage*)smallWhiteWeatherImageFromCode:(NSNumber*)code;
+ (NSInteger)codeFromWeatherImageName:(NSString*)imageName;

+ (NSString*)vegetationTypeToString:(int)vegetation;
+ (NSString*)securityOptionFromSprinklerWiFi:(WiFi*)wifi needsPassword:(BOOL*)needsPassword;

+ (BOOL)isTime24HourFormat;
+ (void)setIsTime24HourFormat:(BOOL)isTime24HourFormat;

+ (NSString*)cloudEmailStatusForCloudSettings:(CloudSettings*)cloudSettings;
+ (NSString*)formattedUptimeForUptimeString:(NSString*)uptimeString;

+ (BOOL)localDiscoveryDisabled;
+ (void)setLocalDiscoveryDisabled:(BOOL)localDiscoveryDisabled;

+ (NSString*)generateGUID;
+ (NSString*)phoneID;

@end

float evenValue(float value);