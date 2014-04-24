//
//  SPUtils.h
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WaterNowZone;
@class Sprinkler;

@interface Utils : NSObject

+ (NSString*)sprinklerURL:(Sprinkler*)sprinkler;
+ (NSString*)currentSprinklerURL;

+ (NSString*)fixedZoneName:(NSString *)zoneName withId:(NSNumber*)theId;
+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter isIdle:(BOOL)isIdle;
+ (BOOL)isZoneWatering:(WaterNowZone*)zone;
+ (BOOL)isZonePending:(WaterNowZone*)zone;
+ (BOOL)isZoneIdle:(WaterNowZone*)zone;
+ (NSString*)fixedSprinklerAddress:(NSString*)address;
+ (NSArray*)remoteSprinklersFilter:(NSArray*)sprinklers;
+ (NSString*)daysStringFromWeekdaysFrequency:(NSString *)weekdays;
+ (NSString*)formattedTime:(NSDate*)date forTimeFormat:(int)timeFormat;

+ (UIView*)customSprinklerTitleWithOutDeviceView:(UILabel**)lblDeviceName outDeviceAddressView:(UILabel**)lblDeviceAddress;

+ (UIImage*)waterWavesImage:(float)height;
+ (UIImage*)waterImage:(float)height;

+ (int)checkOSVersion;
+ (BOOL)isDevice357Plus;
+ (BOOL)isDevice360Plus;

@end

float evenValue(float value);