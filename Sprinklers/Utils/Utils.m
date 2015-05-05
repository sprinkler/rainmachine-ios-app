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
#import "CloudSettings.h"

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

+ (BOOL)isSprinklerInAPMode:(Sprinkler*)sprinkler
{
    return sprinkler.apFlag && (![sprinkler.apFlag boolValue]);
}

+ (BOOL)isDeviceInactive:(Sprinkler*)sprinkler
{
    return ([sprinkler.nrOfFailedConsecutiveDiscoveries intValue] >= [Utils deviceGreyOutRetryCount]);
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

+ (NSString*)getStrippedDownHelperAddress:(NSString*)address
{
    if ([address hasSuffix:@"/"]) {
        address = [address substringToIndex:address.length - 1];
    }
    
    address = [address stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    address = [address stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    
    return address;
}

+ (NSString*)getPort:(NSString*)address
{
    address = [Utils getStrippedDownHelperAddress:address];
    
    NSArray *vals = [address componentsSeparatedByString:@":"];
    
    if (vals.count == 2) {
        return vals[1];
    }
    
    return nil;
}

+ (NSString*)getBaseUrl:(NSString*)address
{
    NSString *port = [self getPort:address];

    address = [Utils getStrippedDownHelperAddress:address];
    
    NSRange rangeHttp = [address rangeOfString:@"http://"];
    NSRange rangeHttps = [address rangeOfString:@"https://"];
    
    if ([port length] > 0) {
        if ([port length] + 1 < [address length]) {
            address = [address substringToIndex:[address length] - ([port length] + 1)];
        }
    }

    if (rangeHttp.location != NSNotFound) {
        return [@"http://" stringByAppendingString:address];
    }
    if (rangeHttps.location != NSNotFound) {
        return [@"https://" stringByAppendingString:address];
    }
    return address;
}

+ (NSString*)addressWithoutPrefix:(NSString*)address
{
    address = [address stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    address = [address stringByReplacingOccurrencesOfString:@"https://" withString:@""];

    return address;
}

+ (int)deviceGreyOutRetryCount
{
    return 1 + [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugDeviceGreyOutRetryCount] intValue];
}

+ (NSString*)activeDevicesPredicate
{
    return [NSString stringWithFormat:@"nrOfFailedConsecutiveDiscoveries < %d", [Utils deviceGreyOutRetryCount]];
}

+ (NSString*)inactiveDevicesPredicate
{
    return [NSString stringWithFormat:@"nrOfFailedConsecutiveDiscoveries >= %d", [Utils deviceGreyOutRetryCount]];
}

+ (NSString*)sprinklerURL:(Sprinkler*)sprinkler
{
    NSString *address = [NSString stringWithFormat:@"%@:%@", sprinkler.address, sprinkler.port ? sprinkler.port : @"443"];
    return [Utils fixedSprinklerAddress:address];
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

+ (NSDateFormatter*)sprinklerDateFormatterForTimeFormat:(NSNumber*)time_format seconds:(BOOL)seconds
{
    return [self sprinklerDateFormatterForTimeFormat:time_format seconds:seconds forceOnlyTimePart:NO forceOnlyDatePart:NO];
}

+ (NSDateFormatter*)sprinklerDateFormatterForTimeFormat:(NSNumber*)time_format
{
    return [self sprinklerDateFormatterForTimeFormat:time_format seconds:YES];
}

+ (NSDateFormatter*)sprinklerDateFormatterForTimeFormat:(NSNumber*)time_format seconds:(BOOL)seconds forceOnlyTimePart:(BOOL)forceOnlyTimePart forceOnlyDatePart:(BOOL)forceOnlyDatePart
{
    NSDateFormatter *df = [NSDate getDateFormaterFixedFormatParsing];
    BOOL normalFormat = (!forceOnlyTimePart) && (!forceOnlyDatePart);
    
    // Date formatting standard. If you follow the links to the "Data Formatting Guide", you will see this information for iOS 6: http://www.unicode.org/reports/tr35/tr35-25.html#Date_Format_Patterns
    if ([time_format intValue] == 24) {
        if ([ServerProxy usesAPI4]) {
            df.dateFormat = normalFormat ? (seconds ? @"yyyy-M-d H:mm:ss" : @"yyyy-M-d H:mm") : (forceOnlyDatePart ? @"yyyy/MM/dd" : @"HH:mm");
        } else {
            df.dateFormat = normalFormat ? @"yyyy/M/d H:mm" : (forceOnlyDatePart ? @"yyyy/M/d" : @"H:mm"); // H means hours between [0-23]
        }
    }
    else if ([time_format intValue] == 12) {
        if ([ServerProxy usesAPI4]) {
            df.dateFormat = normalFormat ? (seconds ? @"yyyy-M-d h:mm:ss a" : @"yyyy-M-d h:mm a") : (forceOnlyDatePart ? @"yyyy/MM/dd" : @"h:mm a");
        } else {
            df.dateFormat = normalFormat ? @"yyyy/M/d h:mm a" : (forceOnlyDatePart ? @"yyyy/M/d" : @"h:mm a"); // K means hours between [0-11], Istvan: use h instead of K, h means hours between [1-12]
        }
    }
    
    return df;
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

+ (NSString*)formattedTimeFromSeconds:(int)seconds {
    int mins = seconds / 60;
    int secs = seconds % 60;
    NSString *minsString = [NSString stringWithFormat:@"%d",(int)mins];
    if (minsString.length < 2) minsString = [@"0" stringByAppendingString:minsString];
    NSString *secsString = [NSString stringWithFormat:@"%d",(int)secs];
    if (secsString.length < 2) secsString = [@"0" stringByAppendingString:secsString];
    return [NSString stringWithFormat:@"%@:%@",minsString,secsString];
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

+ (NSString*)sprinklerUnits
{
    NSString *temperatureUnits = [self sprinklerTemperatureUnits];
    if ([temperatureUnits isEqualToString:@"C"]) return @"Metric";
    else return @"US";
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

+ (NSString*)sprinklerLengthUnits
{
    NSString *temperatureUnits = [self sprinklerTemperatureUnits];
    if ([temperatureUnits isEqualToString:@"C"]) return @"mm";
    else return @"inch";
}

+ (NSString*)securityOptionFromSprinklerWiFi:(WiFi*)wifi needsPassword:(BOOL*)needsPassword
{
    *needsPassword = NO;

    if ([wifi.isWPA2 boolValue]) {
        *needsPassword = YES;
        return @"PSK2";
    }
    if ([wifi.isWPA boolValue]) {
        *needsPassword = YES;
        return @"PSK";
    }
    if ([wifi.isWEP boolValue]) {
        *needsPassword = YES;
        return @"WEP";
    }

    return @"None";
}

#pragma mark - Cells

+ (DevicesCellType1*)configureSprinklerCellForTableView:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath sprinkler:(Sprinkler*)sprinkler canEditRow:(BOOL)canEditRow forceHiddenDisclosure:(BOOL)forceHiddenDisclosure
{
    DevicesCellType1 *cell = [tableView dequeueReusableCellWithIdentifier:@"DevicesCellType1" forIndexPath:indexPath];
    cell.selectionStyle = (tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleGray);
    
    cell.labelMainTitle.text = sprinkler.name;
    
#if DEBUG
    // remove https from address
    NSString *adressWithoutPrefix = [Utils addressWithoutPrefix:sprinkler.address];
    
    // we don't have to print the default port
    if([sprinkler.port isEqual: @"443"])
        cell.labelMainSubtitle.text = sprinkler.port ? [NSString stringWithFormat:@"%@", adressWithoutPrefix] : sprinkler.address;
    else
        cell.labelMainSubtitle.text = sprinkler.port ? [NSString stringWithFormat:@"%@:%@", adressWithoutPrefix, sprinkler.port] : sprinkler.address;
#else
    [cell.labelMainSubtitle removeFromSuperview];
    cell.labelMainSubtitle = nil;
#endif
    
    BOOL isDeviceInactive = [Utils isDeviceInactive:sprinkler];
    
    // TODO: decide upon local/remote type on runtime
    if ([Utils isSprinklerInAPMode:sprinkler]) {
//        cell.labelInfo.textColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        cell.labelInfo.text = isDeviceInactive ? nil : @"setup";
    } else {
        cell.labelInfo.text = nil;
    }
    
    cell.disclosureImageView.hidden = tableView.isEditing || (isDeviceInactive) || (forceHiddenDisclosure);
    cell.labelMainTitle.textColor = isDeviceInactive ? [UIColor lightGrayColor] : [UIColor blackColor];
    
#if DEBUG
    cell.labelMainSubtitle.textColor = cell.labelMainTitle.textColor;
#endif
    
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

+ (UIImage*)smallWhiteWeatherImageFromCode:(NSNumber*)code {
    static NSString *codesTable[] = {/*0,*/ @"bkn_small_white", // MostlyCloudy
                                    /*1,*/ @"skc_small_white", // Fair
                                    /*2,*/ @"few_small_white", // A Few Clouds
                                    /*3,*/ @"sct_small_white", // Partly Cloudy
                                    /*4,*/ @"ovc_small_white", // Overcast
                                    /*5,*/ @"fg_small_white",  // Fog
                                    /*6,*/ @"smoke_small_white", // Smoke
                                    /*7,*/ @"fzrara_small_white",  // Freezing Rain
                                    /*8,*/ @"ip_small_white",  // Ice Pellets
                                    /*9,*/ @"raip_small_white", // Rain Ice Pellets
                                    /*10,*/ @"rasn_small_white", // Rain Snow
                                    /*11,*/ @"shra_small_white", // Rain Showers
                                    /*12,*/ @"tsra_small_white", // Thunderstorms
                                    /*13,*/ @"sn_small_white",   // Snow
                                    /*14,*/ @"wind_small_white", // Windy
                                    /*15,*/ @"hi_shwrs_small_white", // Showers in vicinity
                                    /*16,*/ @"fzrara_small_white",   // Heavy Freezing Rain
                                    /*17,*/ @"hi_tsra_small_white",  // Thunderstorms in Vicinity
                                    /*18,*/ @"ra1_small_white",   // Light Rain
                                    /*19,*/ @"ra_small_white",    // Heavy Rain
                                    /*20,*/ @"nsvrtsra_small_white",   // Funnel Cloud in Vicinity
                                    /*21,*/ @"du_small_white", // Dust
                                    /*22,*/ @"mist_small_white", // Mist
                                    /*23,*/ @"hot_small_white",  // Hot
                                    /*24,*/ @"cold_small_white", // Cold
                                    /*25,*/ @"na_small_white"
    };
    
    int codesTableSize = sizeof(codesTable) / sizeof(codesTable[0]);
    if ([code isKindOfClass:[NSNull class]]) {
        return [UIImage imageNamed:@"na_small_white"];
    } else {
        if ([code intValue] < codesTableSize) {
            NSString *imageName = codesTable[[code intValue]];
            return [UIImage imageNamed:imageName];
        }
    }
    
    return nil;
}

+ (NSInteger)codeFromWeatherImageName:(NSString*)imageName {
    if ([imageName isEqualToString:@"bkn"]) return 0;
    if ([imageName isEqualToString:@"skc"]) return 1;
    if ([imageName isEqualToString:@"few"]) return 2;
    if ([imageName isEqualToString:@"sct"]) return 3;
    if ([imageName isEqualToString:@"ovc"]) return 4;
    if ([imageName isEqualToString:@"fg"]) return 5;
    if ([imageName isEqualToString:@"smoke"]) return 6;
    if ([imageName isEqualToString:@"fzrara"]) return 7;
    if ([imageName isEqualToString:@"ip"]) return 8;
    if ([imageName isEqualToString:@"raip"]) return 9;
    if ([imageName isEqualToString:@"rasn"]) return 10;
    if ([imageName isEqualToString:@"shra"]) return 11;
    if ([imageName isEqualToString:@"tsra"]) return 12;
    if ([imageName isEqualToString:@"sn"]) return 13;
    if ([imageName isEqualToString:@"wind"]) return 14;
    if ([imageName isEqualToString:@"hi_shwrs"]) return 15;
    if ([imageName isEqualToString:@"fzrara"]) return 16;
    if ([imageName isEqualToString:@"hi_tsra"]) return 17;
    if ([imageName isEqualToString:@"ra1"]) return 18;
    if ([imageName isEqualToString:@"ra"]) return 19;
    if ([imageName isEqualToString:@"nsvrtsra"]) return 20;
    if ([imageName isEqualToString:@"du"]) return 21;
    if ([imageName isEqualToString:@"mist"]) return 22;
    if ([imageName isEqualToString:@"hot"]) return 23;
    if ([imageName isEqualToString:@"cold"]) return 24;
    if ([imageName isEqualToString:@"na"]) return 25;
    return 25;
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

+ (BOOL)checkIsTime24HourFormat {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24Hour = amRange.location == NSNotFound && pmRange.location == NSNotFound;
    return is24Hour;
}

+ (BOOL)isTime24HourFormat
{
    if ([ServerProxy usesAPI3]) return [self checkIsTime24HourFormat];
    NSNumber *flag = [[NSUserDefaults standardUserDefaults] objectForKey:@"isTime24HourFormat"];
    if (flag) return flag.boolValue;
    return [self checkIsTime24HourFormat];
}

+ (void)setIsTime24HourFormat:(BOOL)isTime24HourFormat {
    [[NSUserDefaults standardUserDefaults] setObject:@(isTime24HourFormat) forKey:@"isTime24HourFormat"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)cloudEmailStatusForCloudSettings:(CloudSettings*)cloudSettings {
    if (cloudSettings.pendingEmail.length) return [NSString stringWithFormat:@"%@ (Pending)",cloudSettings.pendingEmail];
    if (cloudSettings.email.length) return cloudSettings.email;
    return @"Not set";
}

+ (NSString*)formattedUptimeForUptimeString:(NSString*)uptimeString {
    NSArray *uptimeComponents = [uptimeString componentsSeparatedByString:@":"];
    if (uptimeComponents.count == 4) {
        return [NSString stringWithFormat:@"%@ Days, %@h:%@m:%@s",uptimeComponents[0],uptimeComponents[1],uptimeComponents[2],uptimeComponents[3]];
    }
    else if (uptimeComponents.count == 3) {
        NSInteger hours = [uptimeComponents[0] integerValue];
        NSInteger days = hours / 24;
        hours = hours % 24;
        return [NSString stringWithFormat:@"%d Days, %dh:%@m:%@s",(int)days,(int)hours,uptimeComponents[1],uptimeComponents[2]];
    }
    return uptimeString;
}

+ (BOOL)localDiscoveryDisabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDisableLocalDiscoveryKey];
}

+ (void)setLocalDiscoveryDisabled:(BOOL)localDiscoveryDisabled {
    [[NSUserDefaults standardUserDefaults] setBool:localDiscoveryDisabled forKey:kDisableLocalDiscoveryKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
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