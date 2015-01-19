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
+ (NSString*)activeDevicesPredicate;
+ (NSString*)inactiveDevicesPredicate;
+ (NSString*)fixedSprinklerAddress:(NSString*)address;
+ (NSArray*)remoteSprinklersFilter:(NSArray*)sprinklers;
+ (NSString*)daysStringFromWeekdaysFrequency:(NSString *)weekdays;
+ (NSString*)monthsStringFromMonthsFrequency:(NSString *)months;
+ (NSString*)formattedTime:(NSDate*)date forTimeFormat:(int)timeFormat;
+ (SettingsDate*)fixedSettingsDate:(SettingsDate*)settingsDate;
+ (void)showNotSupportedDeviceAlertView:(id /*<UIAlertViewDelegate>*/)delegate;
+ (NSArray*)parseApiVersion:(id)data;

+ (DevicesCellType1*)configureSprinklerCellForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath sprinkler:(Sprinkler*)sprinkler canEditRow:(BOOL)canEditRow forceHiddenDisclosure:(BOOL)forceHiddenDisclosure;

+ (NSString*)sprinklerTemperatureUnits;
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

+ (NSString*)vegetationTypeToString:(int)vegetation;
+ (NSString*)securityOptionFromSprinklerWiFi:(WiFi*)wifi needsPassword:(BOOL*)needsPassword;

@end

float evenValue(float value);