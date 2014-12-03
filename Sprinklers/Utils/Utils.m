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
#import "WaterNowZone4.h"
#import "Sprinkler.h"
#import "StorageManager.h"
#import "UpdateManager.h"
#import "AppDelegate.h"
#import "NetworkUtilities.h"
#import "SettingsDate.h"
#import "+NSDate.h"
#import "APIVersion.h"
#import "APIVersion4.h"
#import "ServerProxy.h"
#import "WiFi.h"

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

+ (BOOL)isDeviceInactive:(Sprinkler*)sprinkler
{
    return ([sprinkler.nrOfFailedConsecutiveDiscoveries intValue] >= [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugDeviceGreyOutRetryCount] intValue]);
}

+ (BOOL)isManuallyAddedDevice:(Sprinkler*)sprinkler
{
    return (![sprinkler.isLocalDevice boolValue]) && (!(sprinkler.email));
}

+ (BOOL)isLocallyDiscoveredDevice:(Sprinkler*)sprinkler
{
    return [sprinkler.isLocalDevice boolValue];
}

+ (BOOL)isCloudDevice:(Sprinkler*)sprinkler
{
    return (![sprinkler.isLocalDevice boolValue]) && (sprinkler.email);
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

+ (NSString*)getPort:(NSString*)address
{
    address = [address stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    address = [address stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    NSArray *vals = [address componentsSeparatedByString:@":"];
    if (vals.count == 2) {
        return vals[1];
    }
    
    return nil;
}

+ (NSString*)activeDevicesPredicate
{
    return [NSString stringWithFormat:@"nrOfFailedConsecutiveDiscoveries < %d", [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugDeviceGreyOutRetryCount] intValue]];
}

+ (NSString*)inactiveDevicesPredicate
{
    return [NSString stringWithFormat:@"nrOfFailedConsecutiveDiscoveries >= %d", [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugDeviceGreyOutRetryCount] intValue]];
}

+ (NSString*)sprinklerURL:(Sprinkler*)sprinkler
{
    return [NSString stringWithFormat:@"%@:%@", sprinkler.address, sprinkler.port ? sprinkler.port : @"443"];
}

+(NSString*)currentSprinklerURL
{
    return [Utils sprinklerURL:[StorageManager current].currentSprinkler];
}

+ (Sprinkler *)currentSprinkler
{
    return [StorageManager current].currentSprinkler;
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
    if ([ServerProxy usesAPI3]) {
        return [zone.state isEqualToString:@"Watering"];
    }
    
    WaterNowZone4* zone4 = (WaterNowZone4*)zone;
    return [zone4.state intValue] == kAPI4ZoneState_Watering;
}

+ (BOOL)isZoneIdle:(WaterNowZone*)zone
{
    if ([ServerProxy usesAPI3]) {
        return  ([zone.state length] == 0) || ([zone.state isEqualToString:@"Idle"]);
    }
    
    WaterNowZone4* zone4 = (WaterNowZone4*)zone;
    return [zone4.state intValue] == kAPI4ZoneState_Idle;
}

+ (BOOL)isZonePending:(WaterNowZone*)zone
{
    if ([ServerProxy usesAPI3]) {
        return [zone.state isEqualToString:@"Pending"];
    }
    
    WaterNowZone4* zone4 = (WaterNowZone4*)zone;
    return [zone4.state intValue] == kAPI4ZoneState_Pending;
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

+ (NSString*)monthsStringFromMonthsFrequency:(NSString *)selectedMonths
{
    NSArray *vals = [selectedMonths componentsSeparatedByString:@","];
    if (vals && vals.count == 12) {
        NSMutableArray *months = [NSMutableArray array];
        for (int i = 0; i < 12; i++) {
            [months addObject:[monthsOfYear[i] substringToIndex:3]];
        }
        
        NSString *monthsString = @"";
        if ([vals[0] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[0]];
        }
        if ([vals[1] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[1]];
        }
        if ([vals[2] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[2]];
        }
        if ([vals[3] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[3]];
        }
        if ([vals[4] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[4]];
        }
        if ([vals[5] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[5]];
        }
        if ([vals[6] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[6]];
        }
        if ([vals[7] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[7]];
        }
        if ([vals[8] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[8]];
        }
        if ([vals[9] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[9]];
        }
        if ([vals[10] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[10]];
        }
        if ([vals[11] isEqualToString:@"1"]) {
            monthsString = [NSString stringWithFormat:@"%@%@, ", monthsString, months[11]];
        }
        if (([monthsString hasSuffix:@", "]) || ([monthsString hasSuffix:@","])) {
            monthsString = [monthsString substringToIndex:monthsString.length - 2];
        }
        
        return monthsString;
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

+ (void)showNotSupportedDeviceAlertView:(id /*<UIAlertViewDelegate>*/)delegate
{
    NSString *message = [NSString stringWithFormat:@"This device requires a new version of the app. Please update your application from the AppStore."];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Device not supported"
                                                    message:message delegate:delegate cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Go to AppSore", nil];
    alert.tag = kAlertView_DeviceNotSupported;
    [alert show];
}

+ (NSArray*)parseApiVersion:(id)data
{
    NSArray *versionComponents = nil;
    
    if ([data isKindOfClass:[APIVersion class]]) {
        APIVersion *apiVersion = (APIVersion*)data;
        versionComponents = [apiVersion.apiVer componentsSeparatedByString:@"."];
    } else {
        APIVersion4 *apiVersion = (APIVersion4*)data;
        versionComponents = [apiVersion.ver componentsSeparatedByString:@"."];
    }
    
    return versionComponents;
}

+ (NSString*)sprinklerTemperatureUnits
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *units = [userDefaults objectForKey:@"sprinklerUnits"];
    if (!units) {
        units = @"C";
    }
    
    return units;
}

+ (void)setSprinklerTemperatureUnits:(NSString*)units
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:units forKey:@"sprinklerUnits"];
}

+ (NSString*)securityOptionFromSprinklerWiFi:(WiFi*)wifi needsPassword:(BOOL*)needsPassword
{
    *needsPassword = NO;

    if ([wifi.isWPA2 boolValue]) {
        *needsPassword = YES;
        return @"psk2";
    }
    if ([wifi.isWPA boolValue]) {
        *needsPassword = YES;
        return @"psk";
    }
    if ([wifi.isWEP boolValue]) {
        *needsPassword = YES;
        return @"none";
    }

    return @"none";
}

#pragma mark - Cells

+ (DevicesCellType1*)configureSprinklerCellForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath sprinkler:(Sprinkler*)sprinkler canEditRow:(BOOL)canEditRow forceHiddenDisclosure:(BOOL)forceHiddenDisclosure
{
    DevicesCellType1 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType1" forIndexPath:indexPath];
    cell.selectionStyle = (tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
    
    cell.labelMainTitle.text = sprinkler.name;
    
    // remove https from address
    NSString *adressWithoutPrefix = [sprinkler.address substringWithRange:NSMakeRange(8, [sprinkler.address length] - 8)];
    
    // we don't have to print the default port
    if([sprinkler.port isEqual: @"443"])
        cell.labelMainSubtitle.text = sprinkler.port ? [NSString stringWithFormat:@"%@", adressWithoutPrefix] : sprinkler.address;
    else
        cell.labelMainSubtitle.text = sprinkler.port ? [NSString stringWithFormat:@"%@:%@", adressWithoutPrefix, sprinkler.port] : sprinkler.address;
    
    // TODO: decide upon local/remote type on runtime
    cell.labelInfo.text = @"";
    
    BOOL isDeviceInactive = [Utils isDeviceInactive:sprinkler];
    
    cell.disclosureImageView.hidden = tableView.isEditing || (isDeviceInactive) || (forceHiddenDisclosure);
    //    cell.labelMainSubtitle.enabled = [sprinkler.isDiscovered boolValue];
    cell.labelInfo.hidden = tableView.isEditing;
    cell.labelMainTitle.textColor = isDeviceInactive ? [UIColor lightGrayColor] : [UIColor blackColor];
    cell.labelMainSubtitle.textColor = cell.labelMainTitle.textColor;
    
    if (tableView.isEditing && canEditRow) {
        cell.disclosureImageView.hidden = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    return cell;
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

+ (UIImage*)weatherImageFromCode:(NSNumber*)code
{
    static NSString *codesTable[] = {/*0,*/ @"bkn", // MostlyCloudy
                                   /*1,*/ @"skc", // Fair
                                   /*2,*/ @"few", // A Few Clouds
                                   /*3,*/ @"sct", // Partly Cloudy
                                   /*4,*/ @"ovc", // Overcast
                                   /*5,*/ @"fg",  // Fog
                                   /*6,*/ @"smoke", // Smoke
                                   /*7,*/ @"fzrara",  // Freezing Rain
                                   /*8,*/ @"ip",  // Ice Pellets
                                   /*9,*/ @"raip", // Rain Ice Pellets
                                   /*10,*/ @"rasn", // Rain Snow
                                   /*11,*/ @"shra", // Rain Showers
                                   /*12,*/ @"tsra", // Thunderstorms
                                   /*13,*/ @"sn",   // Snow
                                   /*14,*/ @"wind", // Windy
                                   /*15,*/ @"hi_shwrs", // Showers in vicinity
                                   /*16,*/ @"fzrara",   // Heavy Freezing Rain
                                   /*17,*/ @"hi_tsra",  // Thunderstorms in Vicinity
                                   /*18,*/ @"ra1",   // Light Rain
                                   /*19,*/ @"ra",    // Heavy Rain
                                   /*20,*/ @"nsvrtsra",   // Funnel Cloud in Vicinity
                                   /*21,*/ @"du", // Dust
                                   /*22,*/ @"mist", // Mist
                                   /*23,*/ @"hot",  // Hot
                                   /*24,*/ @"cold", // Cold
                                   /*25,*/ @"na"
    };
    
    int codesTableSize = sizeof(codesTable) / sizeof(codesTable[0]);
    if ([code isKindOfClass:[NSNull class]]) {
        return [UIImage imageNamed:@"na"];
    } else {
        if ([code intValue] < codesTableSize) {
            NSString *imageName = codesTable[[code intValue]];
            return [UIImage imageNamed:imageName];
        }
    }
    
    return nil;
}

+ (NSString*)vegetationTypeToString:(int)vegetation
{
    switch (vegetation) {
        case kAPI4ZoneVegetationType_Lawn:
            return @"Lawn";
            break;
        case kAPI4ZoneVegetationType_Fruit_Trees:
            return @"Fruit Trees";
            break;
        case kAPI4ZoneVegetationType_Flowers:
            return @"Flowers";
            break;
        case kAPI4ZoneVegetationType_Vegetables:
            return @"Vegetables";
            break;
        case kAPI4ZoneVegetationType_Citrus:
            return @"Citrus";
            break;
        case kAPI4ZoneVegetationType_Trees_And_Bushes:
            return @"Trees And Bushes";
            break;
        case kAPI4ZoneVegetationType_Other:
            return @"Other";
            break;
            
        default:
            return @"Other";
    }
    
    return @"Other";
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