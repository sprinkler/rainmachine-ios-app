//
//  SPUtils.m
//  Sprinklers
//
//  Created by Fabian Matyas on 15/12/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "Utils.h"
#import "+UIImage.h"
#import "Constants.h"
#import "WaterNowZone.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "UpdateManager.h"
#import "AppDelegate.h"
#import "NetworkUtilities.h"
#import "SettingsDate.h"
#import "+NSDate.h"

@implementation Utils

#pragma mark - General Sprinkler utils

+ (NSArray*)remoteSprinklersFilter:(NSArray*)sprinklers
{
    NSMutableArray *rs = [NSMutableArray array];
    for (Sprinkler *sprinkler in sprinklers) {
        if (![sprinkler.isLocalDevice boolValue]) {
            [rs addObject:sprinkler];
        }
    }
    
    return rs;
}

+ (NSString*)fixedZoneName:(NSString *)zoneName withId:(NSNumber*)theId
{
    if ([zoneName length] == 0) {
        return [NSString stringWithFormat:@"Zone %@", theId];
    }
    
    return zoneName;
}

+ (NSString*)fixedSprinklerAddress:(NSString*)address
{
    if (![address hasPrefix:@"http://"] && ![address hasPrefix:@"https://"]) {
        address = [NSString stringWithFormat:@"https://%@", address ];
    }
    
    if ([address hasPrefix:@"http://"]) {
        address = [address stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    }
    
    return address;
}

+ (NSString*)sprinklerURL:(Sprinkler*)sprinkler
{
    return [NSString stringWithFormat:@"%@:%@", sprinkler.address, sprinkler.port ? sprinkler.port : @"443"];
}

+(NSString*)currentSprinklerURL
{
    return [Utils sprinklerURL:[StorageManager current].currentSprinkler];
}

+ (void)clearRememberMeFlagForSprinkler:(Sprinkler*)sprinkler
{
    sprinkler.loginRememberMe = [NSNumber numberWithBool:NO];
    [[StorageManager current] saveData];
}

+ (void)invalidateLoginForCurrentSprinkler
{
    [NetworkUtilities invalidateLoginForBaseUrl:[[StorageManager current] currentSprinkler].address port:[[StorageManager current] currentSprinkler].port];

    [[StorageManager current] currentSprinkler].loginRememberMe = NO;
    [StorageManager current].currentSprinkler = nil;
    [[StorageManager current] saveData];
}

+ (BOOL)isConnectionFailToServerError:(NSError*)error
{
    return ( ((error.code == NSURLErrorCannotConnectToHost) ||
              (error.code == NSURLErrorCannotFindHost))
        && ([[error domain] isEqualToString:NSURLErrorDomain]));
}

+ (BOOL)hasOperationInternalServerErrorStatusCode:(AFHTTPRequestOperation *)operation
{
    if (!operation) {
        return NO;
    }
    
    return (([[operation response] statusCode] >= 500) && ([[operation response] statusCode] <= 599));
}

+ (int)fixedRoundedToMinutesZoneCounter:(NSNumber*)counter isIdle:(BOOL)isIdle
{
    int counterValue = [[Utils fixedZoneCounter:counter isIdle:YES] intValue];
    return (counterValue + 30) / 60;
}

+ (NSNumber*)fixedZoneCounter:(NSNumber*)counter isIdle:(BOOL)isIdle
{
    if (isIdle) {
      if ([counter intValue] == 0) {
        return [NSNumber numberWithInteger:5 * 60]; // 5 minutes
      }
    }
  
    return counter;
}

+ (BOOL)isZoneWatering:(WaterNowZone*)zone
{
    return [zone.state isEqualToString:@"Watering"];
}

+ (BOOL)isZoneIdle:(WaterNowZone*)zone
{
    return  ([zone.state length] == 0) || ([zone.state isEqualToString:@"Idle"]);
}

+ (BOOL)isZonePending:(WaterNowZone*)zone
{
    return [zone.state isEqualToString:@"Pending"];
}

+ (BOOL)isDevice357Plus
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.updateManager.serverAPIMainVersion == 3) {
        return (appDelegate.updateManager.serverAPISubVersion >= 57);
    }
    
    return YES;
}

+ (BOOL)isDevice359Plus
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.updateManager.serverAPIMainVersion == 3) {
        return (appDelegate.updateManager.serverAPISubVersion >= 59);
    }
    
    return YES;
}

+ (BOOL)isDevice360Plus
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.updateManager.serverAPIMainVersion == 3) {
        return (appDelegate.updateManager.serverAPISubVersion >= 60);
    }
    
    return YES;
}

+ (NSString*)daysStringFromWeekdaysFrequency:(NSString *)selectedWeekdays
{
    NSArray *vals = [selectedWeekdays componentsSeparatedByString:@","];
    if (vals && vals.count == 7) {
        NSMutableArray *weekdays = [NSMutableArray array];
        for (int i = 0; i < 7; i++) {
            [weekdays addObject:[daysOfTheWeek[i] substringToIndex:3]];
        }
        
        NSString *daysString = @"";
        if ([vals[0] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[0]];
        }
        if ([vals[1] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[1]];
        }
        if ([vals[2] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[2]];
        }
        if ([vals[3] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[3]];
        }
        if ([vals[4] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[4]];
        }
        if ([vals[5] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[5]];
        }
        if ([vals[6] isEqualToString:@"1"]) {
            daysString = [NSString stringWithFormat:@"%@%@, ", daysString, weekdays[6]];
        }
        if (([daysString hasSuffix:@", "]) || ([daysString hasSuffix:@","])) {
            daysString = [daysString substringToIndex:daysString.length - 2];
        }
        
        return daysString;
    }
    
    return nil;
}

+ (NSString*)formattedTime:(NSDate*)date forTimeFormat:(int)timeFormat
{
    NSDateFormatter *formatter = [NSDate getDateFormaterFixedFormatParsing];
    if (timeFormat == 0) {
        [formatter setDateFormat:@"H:mm"];
    } else {
        [formatter setDateFormat:@"h:mm a"];
    }
    
    NSString *hourAndMinute = [formatter stringFromDate:date];
    
    return hourAndMinute;
}

+ (SettingsDate*)fixedSettingsDate:(SettingsDate*)settingsDate
{
    // The sprinkler returns inconsistently the fields am_pm and time_format.
    // This fix manually checks the date format and sets the correct value in time_format.
    
    if (([settingsDate.appDate hasSuffix:@"am"]) ||
        ([settingsDate.appDate hasSuffix:@"AM"]) ||
        ([settingsDate.appDate hasSuffix:@"pm"]) ||
        ([settingsDate.appDate hasSuffix:@"PM"]))
    {
        settingsDate.time_format = [NSNumber numberWithInt:12];
    } else {
        settingsDate.time_format = [NSNumber numberWithInt:24];
    }
    
    return settingsDate;
}

+ (void)showNotSupportedDeviceAlertView
{
    NSString *message = [NSString stringWithFormat:@"This device requires a new version of the app. Please update your application from the AppStore."];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Device not supported"
                                                    message:message delegate:self cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Go to AppSore", nil];
    alert.tag = kAlertView_DeviceNotSupported;
    [alert show];
}

# pragma mark - Sprinkler related views

+ (UIView*)customSprinklerTitleWithOutDeviceView:(UILabel**)lblDeviceName outDeviceAddressView:(UILabel**)lblDeviceAddress
{
    UIView *customTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    *lblDeviceName = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 200, 24)];
    (*lblDeviceName).backgroundColor = [UIColor clearColor];
    (*lblDeviceName).textColor = [UIColor whiteColor];
    (*lblDeviceName).font = [UIFont boldSystemFontOfSize:18.0f];
    [customTitle addSubview:*lblDeviceName];
    
    *lblDeviceAddress = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 200, 20)];
    (*lblDeviceAddress).backgroundColor = [UIColor clearColor];
    (*lblDeviceAddress).textColor = [UIColor whiteColor];
    (*lblDeviceAddress).font = [UIFont systemFontOfSize:10.0];
    [customTitle addSubview:*lblDeviceAddress];
    
    return customTitle;
}

#pragma mark - Sprinkler water image generation

+ (UIImage*)waterWavesImage:(float)height
{
    float kLineWidth = 1 * [[UIScreen mainScreen] scale];
    float kWaveAmplitude = 1 * [[UIScreen mainScreen] scale];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.strokeColor = [UIColor colorWithRed:kWaterImageStrokeColor[0] green:kWaterImageStrokeColor[1] blue:kWaterImageStrokeColor[2] alpha:1].CGColor;
    layer.fillColor = [UIColor colorWithRed:kWaterImageFillColor[0] green:kWaterImageFillColor[1] blue:kWaterImageFillColor[2] alpha:1].CGColor;
    layer.lineWidth = kLineWidth;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    
    layer.frame = CGRectMake(0, 0, 2 * kWaveAmplitude + 2 * kLineWidth, height * [[UIScreen mainScreen] scale]);
    
    float x = layer.frame.size.width / 2;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, -kLineWidth, kLineWidth);
    CGPathAddLineToPoint(path, NULL, x, kLineWidth);
    
    float verticalWavesNumber = 9;
    float maxY = layer.frame.size.height - kLineWidth;
    for (int y = kLineWidth; y <= maxY; y++) {
        float angle = -M_PI + (M_PI * verticalWavesNumber * (y - kLineWidth)) / (maxY - kLineWidth);
        float dx = kWaveAmplitude * sinf(angle);
        CGPathAddLineToPoint(path, NULL, x + dx, y);
    }
    CGPathAddLineToPoint(path, NULL, -kLineWidth, maxY);
    
    CGPathCloseSubpath(path);
    
    layer.path = path;
    
    CGPathRelease(path);
    
    return [UIImage imageFromLayer:layer];
}

+ (UIImage*)waterImage:(float)height
{
    float kLineWidth = 1 * [[UIScreen mainScreen] scale];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.strokeColor = [UIColor colorWithRed:kWaterImageStrokeColor[0] green:kWaterImageStrokeColor[1] blue:kWaterImageStrokeColor[2] alpha:1].CGColor;
    layer.fillColor = [UIColor colorWithRed:kWaterImageFillColor[0] green:kWaterImageFillColor[1] blue:kWaterImageFillColor[2] alpha:1].CGColor;
    layer.lineWidth = kLineWidth;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    
    layer.frame = CGRectMake(0, 0, 1, height * [[UIScreen mainScreen] scale]);
    
    float maxY = layer.frame.size.height - kLineWidth;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, -2 * kLineWidth, kLineWidth);
    CGPathAddLineToPoint(path, NULL, 2 * kLineWidth, kLineWidth);
    CGPathAddLineToPoint(path, NULL, 2 * kLineWidth, maxY);
    CGPathAddLineToPoint(path, NULL, -2 * kLineWidth, maxY);
    
    CGPathCloseSubpath(path);
    
    layer.path = path;
    
    CGPathRelease(path);
    
    return [UIImage imageFromLayer:layer];
}

#pragma mark - General

+ (int)checkOSVersion {
    
    NSArray *ver = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    int osVerson = [[ver objectAtIndex:0] intValue];
    return osVerson;
}

@end

float evenValue(float value)
{
    int intValue = roundf(value);
    if (intValue % 2 == 1) {
        intValue++;
    }
    
    return (float)intValue;
}