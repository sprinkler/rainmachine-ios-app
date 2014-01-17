//
//  SPUtils.h
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WaterNowZone;

@interface Utils : NSObject

+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter isIdle:(BOOL)isIdle;
+ (BOOL)isZoneWatering:(WaterNowZone*)zone;
+ (BOOL)isZonePending:(WaterNowZone*)zone;
+ (BOOL)isZoneIdle:(WaterNowZone*)zone;

+ (UIImage*)waterWavesImage:(float)height;
+ (UIImage*)waterImage:(float)height;

+ (int)checkOSVersion;

@end

float evenValue(float value);