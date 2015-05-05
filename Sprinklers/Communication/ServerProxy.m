//
//  SPServerProxy.m
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import "ServerProxy.h"
#import <objc/runtime.h>
#import "AFHTTPRequestOperationManager.h"
#import "WeatherData.h"
#import "WeatherData4.h"
#import "WateringRestrictions.h"
#import "HourlyRestriction.h"
#import "WaterNowZone.h"
#import "WaterNowZone4.h"
#import "ZoneProperties4.h"
#import "ZoneAdvancedProperties.h"
#import "StartStopWatering.h"
#import "SetRainDelay.h"
#import "ServerResponse.h"
#import "Utils.h"
#import "Program.h"
#import "Program4.h"
#import "APIVersion.h"
#import "APIVersion4.h"
#import "UpdateInfo.h"
#import "UpdateInfo4.h"
#import "UpdateStartInfo.h"
#import "StorageManager.h"
#import "RainDelay.h"
#import "SettingsUnits.h"
#import "SettingsDate.h"
#import "SettingsPassword.h"
#import "StartStopProgramResponse.h"
#import "AppDelegate.h"
#import "UpdateManager.h"
#import "Login4Response.h"
#import "SetPassWord4Response.h"
#import "SettingsDate.h"
#import "NetworkUtilities.h"
#import "API4StatusResponse.h"
#import "Constants.h"
#import "Provision.h"
#import "ProvisionSystem.h"
#import "ProvisionLocation.h"
#import "MixerDailyValue.h"
#import "WaterLogDay.h"
#import "WiFi.h"
#import "Parser.h"
#import "CloudSettings.h"
#import "DailyStatsDetail.h"

static int savedServerAPIMainVersion = 0;
static int savedServerAPISubVersion = 0;
static int savedServerAPIMinorSubVersion = -1;
static BOOL isServerStateSaved = NO;

static int serverAPIMainVersion = 0;
static int serverAPISubVersion = 0;
static int serverAPIMinorSubVersion = -1;

@implementation ServerProxy

- (id)initWithSprinkler:(Sprinkler *)sprinkler delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSString *serverURL = [Utils sprinklerURL:sprinkler];
    
    self.delegate = del;
    self.serverURL = serverURL;

    NSURL *baseURL = [NSURL URLWithString:serverURL];
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL jsonRequest:jsonRequest];

    // TODO: remove invalid certificates policy in the future
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setAllowInvalidCertificates:YES];
    [self.manager setSecurityPolicy:policy];
    
    return self;
}

- (id)initWithServerURL:(NSString *)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    serverURL = [Utils fixedSprinklerAddress:serverURL];
    
    self.delegate = del;
    self.serverURL = serverURL;
    
    NSURL *baseURL = [NSURL URLWithString:serverURL];
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL jsonRequest:jsonRequest];
    
    // TODO: remove invalid certificates policy in the future
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setAllowInvalidCertificates:YES];
    [self.manager setSecurityPolicy:policy];
    
    return self;
}

- (void)cancelAllOperations
{
    [self.manager.operationQueue cancelAllOperations];
}

- (int)operationCount
{
    return (int)(self.manager.operationQueue.operationCount);
}

+ (void)pushSprinklerVersion
{
    isServerStateSaved = YES;
    savedServerAPIMainVersion = serverAPIMainVersion;
    savedServerAPISubVersion = serverAPISubVersion;
    savedServerAPIMinorSubVersion = serverAPIMinorSubVersion;
}

+ (void)popSprinklerVersion
{
    if (isServerStateSaved) {
        serverAPIMainVersion = savedServerAPIMainVersion;
        serverAPISubVersion = savedServerAPISubVersion;
        serverAPIMinorSubVersion = savedServerAPIMinorSubVersion;
        isServerStateSaved = NO;
    }
}

+ (void)setSprinklerVersionMajor:(int)major minor:(int)minor subMinor:(int)subMinor
{
    serverAPIMainVersion = major;
    serverAPISubVersion = minor;
    serverAPIMinorSubVersion = subMinor;
}

+ (int)serverAPIMainVersion
{
    return serverAPIMainVersion;
}

+ (int)usesAPI3
{
    return serverAPIMainVersion < 4;
}

+ (int)usesAPI4
{
    return serverAPIMainVersion >= 4;
}

- (NSString*)urlByAppendingAccessTokenToUrl:(NSString*)urlString {
    NSString *baseURL = [Utils getBaseUrl:self.serverURL];
    NSString *port = [Utils getPort:self.serverURL];
    NSString *accessToken = [NetworkUtilities accessTokenForBaseUrl:baseURL port:port];
    return (accessToken.length ? [NSString stringWithFormat:@"%@?access_token=%@",urlString,accessToken] : urlString);
}

#pragma mark - Login

- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe
{
    if ([ServerProxy usesAPI3]) {
        [self login3WithUserName:userName password:password rememberMe:rememberMe];
    } else {
        [self login4WithPassword:password rememberMe:rememberMe];
    }
}

- (void)login4WithPassword:(NSString*)password rememberMe:(BOOL)rememberMe
{
    NSDictionary *paramsDic = @{@"pwd": !password ? @"" : password,
                  @"remember": rememberMe ? @1 : @0
                  };
    
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? @"api/4/auth/login" : @"api/4/login";
    [self.manager POST:relUrl parameters:paramsDic
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       Login4Response *loginResponse = [Login4Response createFromJson:responseObject];
                       [NetworkUtilities removeCookiesForURL:self.manager.baseURL]; // Remove cookies as API 4 uses access token
                       [self.delegate loginSucceededAndRemembered:YES loginResponse:loginResponse unit:nil];
                   }
                   
               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)login3WithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe
{
    NSDictionary *paramsDic;
    if (rememberMe) {
        paramsDic = @{@"action": @"login",
                      @"user": !userName ? @"" : userName,
                      @"password": !password ? @"" : password,
                      @"remember": @"true"
                      };
    } else {
        paramsDic = @{@"action": @"login",
                      @"user": !userName ? @"" : userName,
                      @"password": !password ? @"" : password
                      };
    }
    
    [self.manager POST:@"/ui.cgi" parameters:paramsDic
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         //DLog(@"Success code: %d", [[operation response] statusCode]);
                                         [self step2LoginProcess];
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      BOOL success = NO;
                                      if ([[NetworkUtilities cookiesForURL:[self.manager baseURL]] count] > 0) {
                                        if ([[[operation response] MIMEType] isEqualToString:@"text/html"]) {
                                        success = YES;
                                        }
                                      }
                                      if (success) {
                                          [self step2LoginProcess];
                                      } else {
                                        NSHTTPURLResponse *response = operation.response;
                                        if ((NSUInteger)response.statusCode == 200) {
                                          [self.delegate loggedOut];
                                        } else {
                                            [self handleError:error fromOperation:operation userInfo:nil];
                                        }
                                      }
                                  }];
}

- (void)step2LoginProcess
{
    // This step is in fact a test for the case when the device logs the user out immediately after login
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings",
                                             @"what" : @"units"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 
                                                 if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                                                     NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([SettingsUnits class])];
                                                     SettingsUnits *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                     [self.delegate loginSucceededAndRemembered:[self isLoginRememberedForCurrentSprinkler] loginResponse:nil unit:response.units];
                                                 }
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation userInfo:nil];
                                             }];
}

- (BOOL)isLoginRememberedForCurrentSprinkler
{
    NSArray *cookies = [NetworkUtilities cookiesForURL:[self.manager baseURL]];
    for (NSHTTPCookie *cookie in cookies) {
        if (([[cookie name] isEqualToString:@"login"]) && (![cookie isSessionOnly])) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Settings

- (void)setNewPassword:(NSString*)newPassword confirmPassword:(NSString*)confirmPassword oldPassword:(NSString*)oldPassword
{
    if ([ServerProxy usesAPI3]) {
        [self setNewPassword3:newPassword confirmPassword:confirmPassword oldPassword:oldPassword];
    } else {
        [self setNewPassword4:newPassword oldPassword:oldPassword];
    }
}

- (void)setNewPassword4:(NSString*)newPassword oldPassword:(NSString*)oldPassword
{
    NSDictionary *paramsDic = @{@"newPass" : newPassword,
                                @"oldPass": oldPassword
                                };

    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/auth/change"] : [self urlByAppendingAccessTokenToUrl:@"api/4/password"];
    [self.manager POST:relUrl parameters:paramsDic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([SetPassword4Response class])] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)setNewPassword3:(NSString*)newPassword confirmPassword:(NSString*)confirmPassword oldPassword:(NSString*)oldPassword
{
    [self.manager POST:@"/ui.cgi?action=settings&what=password" parameters:@{@"newPass" : newPassword,
                                                                             @"confirmPass" : confirmPassword,
                                                                             @"oldPass" : oldPassword
                                                                             } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            ServerResponse *response = nil;
            if (responseObject) {
                NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            }
            [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestSettingsUnits
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings",
                                              @"what" : @"units"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([SettingsUnits class])];
            ServerResponse *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)setSettingsUnits:(NSString*)unit
{
    [self.manager POST:@"/ui.cgi?action=settings&what=units" parameters:@{@"units": unit} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                  
      if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
          ServerResponse *response = nil;
          if (responseObject) {
              NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
              response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
          }
          [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
      }
      
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestSettingsDate
{
    if ([ServerProxy usesAPI3]) {
        [self requestSettingsDate3];
    } else {
        [self requestSettingsDate4];
    }
}

- (void)requestSettingsDate4
{
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/machine/time"] : [self urlByAppendingAccessTokenToUrl:@"api/4/time"];
    [self.manager GET: relUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            SettingsDate *settingsDate = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([SettingsDate class])][0];
            settingsDate.time_format = @24;
            [self.delegate serverResponseReceived:settingsDate serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestSettingsDate3
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings",
                                             @"what" : @"timedate"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 
                                                 if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                                                     NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([SettingsDate class])];
                                                     SettingsDate *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                     response = [Utils fixedSettingsDate:response];
                                                     [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
                                                 }
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation userInfo:nil];
                                             }];
}

- (void)setSettingsDate:(SettingsDate*)settingsDate
{
    if ([ServerProxy usesAPI3]) {
        [self setSettingsDate3:settingsDate];
    } else {
        [self setSettingsDate4:settingsDate];
    }
}

- (void)setSettingsDate4:(SettingsDate*)settingsDate
{
    NSMutableDictionary *params = [[self toDictionaryFromObject:settingsDate] mutableCopy];
    [params removeObjectForKey:@"time_format"];

    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/machine/time"] : [self urlByAppendingAccessTokenToUrl:@"api/4/time"];
    [self.manager POST: relUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            API4StatusResponse *rez = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])][0];
            [self.delegate serverResponseReceived:rez serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)setSettingsDate3:(SettingsDate*)settingsDate
{
    NSDictionary *params = [self toDictionaryFromObject:settingsDate];
    
    [self.manager POST:@"/ui.cgi?action=settings&what=timedate" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            ServerResponse *response = nil;
            if (responseObject) {
                NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            }
            [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestSettingsPassword
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings",
                                             @"what" : @"password"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 
                                                 if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                                                     NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([SettingsPassword class])];
                                                     ServerResponse *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                     [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
                                                 }
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation userInfo:nil];
                                             }];
}

- (void)setSettingsPassword:(SettingsPassword*)settingsPassword
{
    NSDictionary *params = [self toDictionaryFromObject:settingsPassword];
    
    [self.manager POST:@"/ui.cgi?action=settings&what=password" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            ServerResponse *response = nil;
            if (responseObject) {
                NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            }
            [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

#pragma mark - Restrictions

- (void)requestWateringRestrictions
{
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/restrictions/global"] : [self urlByAppendingAccessTokenToUrl:@"api/4/wateringRestrictions"];
    [self.manager GET:relUrl parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      WateringRestrictions *wateringRestrictions = [WateringRestrictions createFromJson:responseObject];
                      [self.delegate serverResponseReceived:wateringRestrictions serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)postWateringRestrictions:(WateringRestrictions*)restrictions;
{
    NSDictionary *params = @{@"hotDaysExtraWatering" : [NSNumber numberWithBool:restrictions.hotDaysExtraWatering],
                             @"freezeProtectEnabled" : [NSNumber numberWithBool:restrictions.freezeProtectEnabled],
                             @"freezeProtectTemp"    : [NSNumber numberWithDouble:restrictions.freezeProtectTemperature],
                             @"noWaterInWeekDays"    : restrictions.noWaterInWeekDays,
                             @"noWaterInMonths"      : restrictions.noWaterInMonths,
                             @"rainDelayStartTime"   : [NSNumber numberWithInt:restrictions.rainDelayStartTime],
                             @"rainDelayDuration"    : [NSNumber numberWithInt:restrictions.rainDelayDuration]};
    
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/restrictions/global"] : [self urlByAppendingAccessTokenToUrl:@"api/4/wateringRestrictions"];
    [self.manager POST:relUrl parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)requestHourlyRestrictions {
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/restrictions/hourly"] : [self urlByAppendingAccessTokenToUrl:@"api/4/hourlyRestrictions"];
    [self.manager GET:relUrl parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"hourlyRestrictions"] toClass:NSStringFromClass([HourlyRestriction class])] serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)createHourlyRestriction:(HourlyRestriction*)restriction includeUID:(BOOL)includeUID
{
    NSMutableDictionary *params = [@{@"start"    : restriction.dayStartMinute,
                             @"duration" : restriction.minuteDuration,
                             @"weekDays" : restriction.weekDays} mutableCopy];
    if (includeUID) {
        params[@"uid"] = restriction.uid;
        params[@"interval"] = restriction.interval;
    }
    
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/restrictions/hourly"] : [self urlByAppendingAccessTokenToUrl:@"api/4/hourlyRestrictions/create"];
    [self.manager POST:relUrl parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)deleteHourlyRestriction:(HourlyRestriction*)restriction
{
    NSDictionary *params = @{@"uid" : restriction.uid};
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? @"api/4/restrictions/hourly/%@/delete" : @"api/4/hourlyRestrictions/%@/delete";
    [self.manager POST: [self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:relUrl, restriction.uid]] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

#pragma mark - Provision

- (void)requestCurrentWiFi
{
    [self.manager GET:[[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/provision/wifi"] : [self urlByAppendingAccessTokenToUrl:@"api/4/provision/wifi"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestAvailableWiFis
{
    [self.manager GET:[[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/provision/wifi/scan"] : [self urlByAppendingAccessTokenToUrl:@"api/4/provision/getScanResults"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *WiFis = [ServerProxy fromJSONArray:[responseObject objectForKey:@"scanResults"] toClass:NSStringFromClass([WiFi class])];
                      [self.delegate serverResponseReceived:WiFis serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestDiag
{
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/diag"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestDiagWithTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:@"GET"
                                                                           URLString:[[NSURL URLWithString:[self urlByAppendingAccessTokenToUrl:@"api/4/diag"] relativeToURL:self.manager.baseURL] absoluteString]
                                                                          parameters:nil];
    request.timeoutInterval = timeoutInterval;
    
    AFHTTPRequestOperation *operation =
        [self.manager HTTPRequestOperationWithRequest:request
                                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                                                      [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:nil];
                                                  }
                                              }
                                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                  [self handleError:error fromOperation:operation userInfo:nil];
                                              }];
    [self.manager.operationQueue addOperation:operation];
}

- (void)setWiFiWithSSID:(NSString*)ssid encryption:(NSString*)encryption key:(NSString*)password
{
    NSDictionary *params = @{@"ssid" : ssid,
                             @"encryption" : encryption,
                             @"key" : password};
    
    [self.manager POST:[[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/provision/wifi/settings"] : [self urlByAppendingAccessTokenToUrl:@"api/4/provision/setSSID"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)setProvisionName:(NSString*)name
{
    NSDictionary *params = @{@"netName" : name};
    
    [self.manager POST:[[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/provision/name"] : [self urlByAppendingAccessTokenToUrl:@"api/4/provision/setNetName"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)requestProvision
{
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/provision"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      Provision *provision = [Provision createFromJson:responseObject];
                      [self.delegate serverResponseReceived:provision serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)provisionReset
{
    NSDictionary *params = @{@"restart" : @YES};
    
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision/reset"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)enableLightLEDs:(BOOL)enabled {
    NSDictionary *params = @{@"enabled" : @(enabled)};
    
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/machine/lightleds"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)setLocation:(double)latitude longitude:(double)longitude name:(NSString*)name timezone:(NSString*)timezone
{
    NSMutableDictionary *locationParams = [NSMutableDictionary new];
    [locationParams setObject:@(latitude) forKey:@"latitude"];
    [locationParams setObject:@(longitude) forKey:@"longitude"];
    if (timezone) [locationParams setObject:timezone forKey:@"timezone"];
    if (name) [locationParams setObject:name forKey:@"name"];
        
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision"] parameters:@{@"location" : locationParams}
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)setTimezone:(NSString*)timezone
{
    NSDictionary *params = @{@"location" : @{@"timezone" : timezone}};
    
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)saveRainSensitivityFromProvision:(Provision*)provision
{
    NSDictionary *params = @{@"location" : @{@"rainSensitivity" : @(provision.location.rainSensitivity),
                                             @"wsDays" : @(provision.location.wsDays)}};
    
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)saveWindSensitivityFromProvision:(Provision*)provision
{
    NSDictionary *params = @{@"location" : @{@"windSensitivity" : @(provision.location.windSensitivity)}};
    
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)setUseRainSensor:(BOOL)useRainSensor {
    NSDictionary *params = @{@"system" : @{@"useRainSensor" : @(useRainSensor)}};
    
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision"] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

#pragma mark - Mixer data

- (void)requestMixerDataFromDate:(NSString*)dateString daysCount:(NSInteger)daysCount {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/mixer/%@/%d",dateString,(int)daysCount]] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *mixerDictsByDate = [responseObject objectForKey:@"mixerDataByDate"];
                      NSMutableArray *mixerDataByDate = [NSMutableArray new];
                      for (NSDictionary *mixerDictByDate in mixerDictsByDate) {
                          [mixerDataByDate addObject:[MixerDailyValue createFromJson:mixerDictByDate]];
                      }
                      [self.delegate serverResponseReceived:mixerDataByDate serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestWateringLogDetailsFromDate:(NSString*)dateString daysCount:(NSInteger)daysCount {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/watering/log/details/%@/%d",dateString,(int)daysCount]] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSDictionary *waterLog = [responseObject objectForKey:@"waterLog"];
                      NSArray *waterLogDaysDicts = [waterLog objectForKey:@"days"];
                      
                      NSMutableArray *waterLogDays = [NSMutableArray new];
                      for (NSDictionary *waterLogDict in waterLogDaysDicts) {
                          [waterLogDays addObject:[WaterLogDay createFromJson:waterLogDict]];
                      }
                      
                      [self.delegate serverResponseReceived:waterLogDays serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestWateringLogSimulatedDetailsFromDate:(NSString*)dateString daysCount:(NSInteger)daysCount {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/watering/log/simulated/details/%@/%d",dateString,(int)daysCount]] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSDictionary *waterLog = [responseObject objectForKey:@"waterLog"];
                      NSArray *waterLogDaysDicts = [waterLog objectForKey:@"days"];
                      
                      NSMutableArray *waterLogDays = [NSMutableArray new];
                      for (NSDictionary *waterLogDict in waterLogDaysDicts) {
                          [waterLogDays addObject:[WaterLogDay createFromJson:waterLogDict]];
                      }
                      
                      [self.delegate serverResponseReceived:waterLogDays serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

#pragma mark - Parsers

- (void)requestParsers {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/parser"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *parsersDicts = [responseObject objectForKey:@"parsers"];
                      NSMutableArray *parsers = [NSMutableArray new];
                      for (NSDictionary *parserDict in parsersDicts) {
                          [parsers addObject:[Parser createFromJson:parserDict]];
                      }
                      
                      [self.delegate serverResponseReceived:parsers serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)activateParser:(Parser*)parser activate:(BOOL)activate {
    NSDictionary *params = @{@"activate" : @(activate)};
    
    [self.manager POST: [self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/parser/%d/activate", parser.uid]] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       parser.enabled = activate;
                       [self.delegate serverResponseReceived:parser serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)saveParserParams:(Parser*)parser {
    [self.manager POST: [self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/parser/%d/params", parser.uid]] parameters:parser.paramsDictionary
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:parser serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)sendDiagnostics {
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/diag/upload"] parameters:@{}
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

#pragma mark - Various

- (void)requestWeatherData
{
    if ([ServerProxy usesAPI3]) {
        [self request3WeatherData];
    } else {
        [self request4WeatherData];
    }
}

- (void)request4WeatherData
{
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/dailystats"] : [self urlByAppendingAccessTokenToUrl:@"api/4/weatherData"];
    [self.manager GET:relUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"DailyStats"] toClass:NSStringFromClass([WeatherData4 class])] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)request3WeatherData
{
    [self.manager GET: @"ui.cgi" parameters:@{@"action": @"weatherdata"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey: @"HomeScreen"] toClass:NSStringFromClass([WeatherData class])] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestDailyStatsDetails {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/dailystats/details"] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            NSArray *dailyStatsDetailDicts = [responseObject objectForKey:@"DailyStatsDetails"];
            NSMutableArray *dailyStatsDetails = [NSMutableArray new];
            for (NSDictionary *dailyStatsDetailDict in dailyStatsDetailDicts) {
                [dailyStatsDetails addObject:[DailyStatsDetail createFromJson:dailyStatsDetailDict]];
            }            
            [self.delegate serverResponseReceived:dailyStatsDetails serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

// Get Zones list (Used in Water Now main screen)
- (void)requestWaterNowZoneList
{
    if ([ServerProxy usesAPI3]) {
        [self requestWaterNowZoneList3];
    } else {
        [self requestWaterNowZoneList4];
    }
}

- (void)requestWaterNowZoneList3
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zones"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([WaterNowZone class])] serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestWaterNowZoneList4
{
//    [self.manager GET:@"api/4/waterNowZone" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/watering/zone"] : [self urlByAppendingAccessTokenToUrl:@"api/4/zone"];
      [self.manager GET:relUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([WaterNowZone4 class])] serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestWaterActionsForZone:(NSNumber*)zoneId
{
    if ([ServerProxy usesAPI3]) {
        [self requestWaterActionsForZone3:zoneId];
    } else {
        [self requestWaterActionsForZone4:zoneId];
    }
}

- (void)requestWaterActionsForZone4:(NSNumber*)zoneId
{
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/zone/%@", zoneId]] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            NSArray *response = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([WaterNowZone4 class])];
            WaterNowZone4 *rez = (response.count > 0) ? response[0] : nil;
            [self.delegate serverResponseReceived:rez serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

// Request one single zone (Used in Water Now->Zone screen)
- (void)requestWaterActionsForZone3:(NSNumber*)zoneId
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zoneedit",
                                             @"zid": zoneId} success:^(AFHTTPRequestOperation *operation, id responseObject) {

                                                 if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                                                     NSDictionary *zoneDict = [responseObject objectForKey:@"zone"];
                                                     if ([zoneDict isKindOfClass:[NSDictionary class]]) {
                                                         WaterNowZone *zone = [WaterNowZone createFromJson:zoneDict];
                                                         [self.delegate serverResponseReceived:zone serverProxy:self userInfo:nil];
                                                     }
                                                 }

                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation userInfo:nil];
                                             }];
}

- (BOOL)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter
{
    if ([ServerProxy usesAPI3]) {
        return [self api3ToggleWateringOnZone:zone withCounter:counter];
    }
    
    if ([Utils isZoneIdle:zone]) {
        [self api4StartWateringOnZone:zone withCounter:counter];
        return YES;
    }
    [self api4StopWateringOnZone:zone];
    return NO;
}

- (void)api4StopWateringOnZone:(WaterNowZone*)zone
{
    NSDictionary *paramsDic = @{@"zid" : zone.id};
    
    [self.manager POST: [self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/zone/%@/stop", zone.id]] parameters:paramsDic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)api4StartWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter
{
    NSDictionary *paramsDic = @{@"id" : zone.id,
                                @"time": counter
                                };
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? @"api/4/zone/%@/start" : @"api/4/waterZone";
    [self.manager POST: [self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:relUrl, zone.id]] parameters:paramsDic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

// Toggle a zone (Used in Water Now->Zone screen and when toggling watering using switches from main screen)
// Return value means: YES - if watering started, NO - if watering stopped
- (BOOL)api3ToggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter
{
    BOOL isIdle = [Utils isZoneIdle:zone];
    StartStopWatering *startStopWatering = [StartStopWatering new];
    startStopWatering.id = zone.id;
    startStopWatering.counter = isIdle ? [Utils fixedZoneCounter:counter isIdle:isIdle] : [NSNumber numberWithInteger:0];

    zone.counter = startStopWatering.counter;
    
    NSDictionary *params = [self toDictionaryFromObject:startStopWatering];
    [self.manager POST:[NSString stringWithFormat:@"/ui.cgi?action=zonesave&from=zoneedit&zid=%@", zone.id] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The server returns an empty response when success
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:nil serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
    
    return [startStopWatering.counter intValue] != 0;
}

- (BOOL)setWateringOnZone:(WaterNowZone*)zone toState:(int)state withCounter:(NSNumber*)counter
{
    StartStopWatering *startStopWatering = [StartStopWatering new];
    startStopWatering.id = zone.id;
    startStopWatering.counter = state ? [Utils fixedZoneCounter:counter isIdle:YES] : [NSNumber numberWithInteger:0];
    
    zone.counter = startStopWatering.counter;
    
    NSDictionary *params = [self toDictionaryFromObject:startStopWatering];
    [self.manager POST:[NSString stringWithFormat:@"/ui.cgi?action=zonesave&from=zoneedit&zid=%@", zone.id] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The server returns an empty response when success
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            [self.delegate serverResponseReceived:nil serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
    
    return [startStopWatering.counter intValue] != 0;
}

- (void)stopAllWateringZones
{
    [self.manager GET:@"/ui.cgi?action=stopall" parameters:@{@"action": @"stopall"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
         if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
             ServerResponse *response = nil;
             if (responseObject) {
                 NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                 response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
             }
             [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [self handleError:error fromOperation:operation userInfo:nil];
     }];
}

- (void)getRainDelay {
    if ([ServerProxy usesAPI3]) {
        [self getRainDelay3];
    } else {
        [self getRainDelay4];
    }
}

- (void)getRainDelay4 {
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/restrictions/raindelay"] : [self urlByAppendingAccessTokenToUrl:@"api/4/rainDelay"];
    [self.manager GET: relUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            id responseArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([RainDelay class])];
            [self.delegate serverResponseReceived:responseArray[0] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)getRainDelay3 {
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings", @"what": @"rainDelay"}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([RainDelay class])];
                      ServerResponse *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                      [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)setRainDelay:(NSNumber*)value
{
    if ([ServerProxy usesAPI3]) {
        [self setRainDelay3:value];
    } else {
        [self setRainDelay4:value];
    }
}

- (void)setRainDelay4:(NSNumber*)value {
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/restrictions/raindelay"] : [self urlByAppendingAccessTokenToUrl:@"api/4/rainDelay"];
    NSDictionary *params = [NSDictionary dictionaryWithObject:value forKey:@"rainDelay"];
    [self.manager POST: relUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            id responseArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
            [self.delegate serverResponseReceived:responseArray[0] serverProxy:self userInfo:params];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)setRainDelay3:(NSNumber*)value
{
    NSDictionary *params = [NSDictionary dictionaryWithObject:value forKey:@"rainDelay"];
    [self.manager POST:@"/ui.cgi?action=settings&what=rainDelay" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            ServerResponse *response = nil;
            if (responseObject) {
                NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            }
            [self.delegate serverResponseReceived:response serverProxy:self userInfo:params];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (id)fixedZonesJSON:(AFHTTPRequestOperation*)operation
{
    // Relates to #124
    // The "forecastData" field comes duplicated from all sprinklers <= 3.60
    // This fix replaces all "forecastData:" strings with "forecastData%d:", parses the response to a dictionary and takes the last "forecastData%d" key
    
    NSMutableString *responseString = [[[NSString alloc] initWithData:[operation responseData] encoding:NSUTF8StringEncoding] mutableCopy];
    
    NSString *substring = @"\"forecastData\":";
    BOOL found = NO;
    int keyIndex = 0;
    do {
        found = NO;
        NSRange searchRange = NSMakeRange(0, responseString.length);
        NSRange foundRange;
        if (searchRange.location < responseString.length) {
            searchRange.length = responseString.length-searchRange.location;
            foundRange = [responseString rangeOfString:substring options:nil range:searchRange];
            if (foundRange.location != NSNotFound) {
                found = YES;
                NSString *newKey = [NSString stringWithFormat:@"\"forecastData%04d\":", keyIndex++];
                [responseString replaceCharactersInRange:foundRange withString:newKey];
            }
        }
    } while (found);
    
    NSError *error = nil;
    NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
    
    NSArray *values = [responseObject objectForKey:@"zones"];
    for (NSMutableDictionary *obj in values) {
        if ([obj isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableArray *keys = [NSMutableArray array];
            for (NSString *key in [obj allKeys]) {
                if ([key hasPrefix:@"forecastData"]) {
                    [keys addObject:key];
                }
            }
            
            NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(compare:)];
            if ([sortedKeys count] > 0) {
                [obj setObject:[obj objectForKey:[sortedKeys lastObject]] forKey:@"forecastData"];

                // Remove the duplicate keys
                for (NSString *key in sortedKeys) {
                    [obj removeObjectForKey:key];
                }
            }
        }
    }
    
    return responseObject;
}

- (void)requestZones {
    if ([ServerProxy usesAPI3]) {
        [self requestZones3];
    } else {
        [self requestZonesProperties];
    }
}

- (void)requestZonesProperties
{
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/zone/properties"] : [self urlByAppendingAccessTokenToUrl:@"api/4/zoneProperties"];
    [self.manager GET:relUrl parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      responseObject = [self fixedZonesJSON:operation];
                      
                      NSArray *values = [responseObject objectForKey:@"zones"];
                      if (values) {
                          NSMutableArray *returnValues = [NSMutableArray array];
                          for (id obj in values) {
                              if ([obj isKindOfClass:[NSDictionary class]]) {
                                  ZoneProperties4 *zone = [ZoneProperties4 createFromJson:obj];
                                  [returnValues addObject:zone];
                              }
                          }
                          [self.delegate serverResponseReceived:returnValues serverProxy:self userInfo:nil];
                      }
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestZonePropertiesWithId:(int)zoneId
{
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? @"api/4/zone/%d/properties" : @"api/4/zoneProperties/%d";
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:relUrl, zoneId]] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      id obj = [self fixedZonesJSON:operation];
                      ZoneProperties4 *zone = nil;
                      if ([obj isKindOfClass:[NSDictionary class]]) {
                          zone = [ZoneProperties4 createFromJson:obj];
                      }
                      [self.delegate serverResponseReceived:zone serverProxy:self userInfo:nil];
                    }
                }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestZones4 {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/zone"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([WaterNowZone4 class])] serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestZones3 {
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings", @"what": @"zones"}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      
                      responseObject = [self fixedZonesJSON:operation];

                      NSArray *values = [responseObject objectForKey:@"zones"];
                      if (values) {
                          NSMutableArray *returnValues = [NSMutableArray array];
                          for (id obj in values) {
                              if ([obj isKindOfClass:[NSDictionary class]]) {
                                  Zone *zone = [Zone createFromJson:obj];
                                  [returnValues addObject:zone];
                              }
                          }
                          [_delegate serverResponseReceived:returnValues serverProxy:self userInfo:nil];
                      }
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)createProgram:(Program4*)program
{
    NSMutableDictionary *params = [[program toDictionary] mutableCopy];
    [params removeObjectForKey:@"uid"];
    
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/program"] : [self urlByAppendingAccessTokenToUrl:@"api/4/program/create"];
    [self.manager POST:relUrl parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                      [self.delegate serverResponseReceived:[rezArray firstObject] serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestProgramWithId:(int)programId {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/program/%d", programId]] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      Program4 *program = [Program4 createFromJson:responseObject];
                      [self.delegate serverResponseReceived:program serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestPrograms {
    if ([ServerProxy usesAPI3]) {
        [self requestPrograms3];
    } else {
        [self requestPrograms4];
    }
}

- (void)requestPrograms4 {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/program"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *values = [responseObject objectForKey:@"programs"];
                      if (values) {
                          NSMutableArray *returnValues = [NSMutableArray array];
                          for (id obj in values) {
                              if ([obj isKindOfClass:[NSDictionary class]]) {
                                  Program4 *program = [Program4 createFromJson:obj];
                                  [returnValues addObject:program];
                              }
                          }
                          [_delegate serverResponseReceived:returnValues serverProxy:self userInfo:nil];
                      }
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)requestPrograms3 {
    [self.manager GET:@"ui.cgi" parameters:@{@"action" : @"settings", @"what" : @"programs"}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *values = [responseObject objectForKey:@"programs"];
                      if (values) {
                          NSMutableArray *returnValues = [NSMutableArray array];
                          for (id obj in values) {
                              if ([obj isKindOfClass:[NSDictionary class]]) {
                                  Program *program = [Program createFromJson:obj];
                                  [returnValues addObject:program];
                              }
                          }
                          [_delegate serverResponseReceived:returnValues serverProxy:self userInfo:nil];
                      }
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)startProgram4:(Program4*)program {
    NSDictionary *params = @{@"pid" : [NSNumber numberWithInt:program.programId]};
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/program/%d/start", program.programId]] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                       [self.delegate serverResponseReceived:[rezArray firstObject] serverProxy:self userInfo:@"running"];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)stopProgram4:(Program4*)program {
    NSDictionary *params = @{@"pid" : [NSNumber numberWithInt:program.programId]};
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/program/%d/stop", program.programId]] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                       [self.delegate serverResponseReceived:[rezArray firstObject] serverProxy:self userInfo:@"stopped"];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)stopAllPrograms4 {
    NSDictionary *params = @{@"all" : [NSNumber numberWithBool:YES]};
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/watering/stopall"] : [self urlByAppendingAccessTokenToUrl:@"api/4/program/stopAll"];
    [self.manager POST:relUrl parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                       [self.delegate serverResponseReceived:[rezArray firstObject] serverProxy:self userInfo:@"stopped"];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)runNowProgram:(Program*)program {
    [self runNowProgram3:program];
}

- (void)runNowProgram3:(Program*)program {
    if (program) {
        // 3.55 and 3.56 can only Stop programs
        [self.manager POST:@"/ui.cgi" parameters:@{@"action" : @"settings",
                                                   @"what" : [Utils isDevice357Plus] ? @"run_now" : @"stop_now",
                                                   @"pid" : [NSNumber numberWithInt:program.programId]}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                StartStopProgramResponse *response = nil;
                if (responseObject) {
                    NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([StartStopProgramResponse class])];
                    response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                }
                [self.delegate serverResponseReceived:response serverProxy:self userInfo:@"runNowProgram"];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error fromOperation:operation userInfo:@"runNowProgram"];
        }];
    }
}

- (void)saveProgram:(Program*)program {
    if ([ServerProxy usesAPI3]) {
        [self saveProgram3:program];
    } else {
        [self saveProgram4:program];
    }
}

- (void)saveProgram4:(Program*)program {
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? @"api/4/program/%d" : @"api/4/program/%d/update";
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:relUrl, program.programId]] parameters:[program toDictionary]
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                       [self.delegate serverResponseReceived:[rezArray firstObject] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)saveProgram3:(Program*)program {
    if (program) {
        //        NSMutableDictionary *params = [[self toDictionaryFromObject:program] mutableCopy];
        //        [params setObject:[Utils formattedTime:program.startTime forTimeFormat:program.timeFormat] forKey:@"programStartTime"];
        //        [params removeObjectForKey:@"startTime"];
        NSDictionary *params = [program toDictionary];
        
        [self.manager POST:@"ui.cgi?action=settings&what=programs" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                ServerResponse *response = nil;
                if (responseObject) {
                    NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                    response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                }
                [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error fromOperation:operation userInfo:nil];
        }];
    }
}

- (void)deleteProgram:(int)programId {
    if ([ServerProxy usesAPI3]) {
        [self deleteProgram3:programId];
    } else {
        [self deleteProgram4:programId];
    }
}

- (void)deleteProgram4:(int)programId {
    NSDictionary *params = @{@"pid" : [NSNumber numberWithInt:programId]};
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:@"api/4/program/%d/delete", programId]] parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                      [self.delegate serverResponseReceived:@{@"serverResponse" : [rezArray firstObject], @"pid" : [NSNumber numberWithInt:programId]} serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)deleteProgram3:(int)programId {

    NSDictionary *paramsDic = @{@"action": @"settings",
                                @"what": @"delete_program",
                                @"pid": [NSNumber numberWithInt:programId]};

    [self.manager POST:@"/ui.cgi" parameters:paramsDic
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
               ServerResponse *response = nil;
               if (responseObject) {
                   NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                   response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
               }
               NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:response, @"serverResponse", [NSNumber numberWithInt:programId], @"pid", nil];
               [_delegate serverResponseReceived:d serverProxy:self userInfo:nil];
           }
       }
       failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           [self handleError:error fromOperation:operation userInfo:nil];
       }];
}

- (void)programCycleAndSoak:(int)programId cycles:(int)nr_of_cycles soak:(int)soak_minutes cs_on:(int)cs_on
{
    NSDictionary *paramsDic = @{@"action": @"settings",
                                @"what": @"cycle_soak",
                                @"pid": [NSNumber numberWithInt:programId],
                                @"cycles" : [NSNumber numberWithInt:nr_of_cycles],
                                @"soak" : [NSNumber numberWithInt:soak_minutes],
                                @"cs_on" : [NSNumber numberWithInt:cs_on]
                                };
    
    [self.manager POST:@"/ui.cgi" parameters:paramsDic
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       ServerResponse *response = nil;
                       if (responseObject) {
                           NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                           response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                       }
                       [_delegate serverResponseReceived:response serverProxy:self userInfo:paramsDic];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)programStationDelay:(int)programId delay:(int)delay_minutes delay_on:(int)delay_on
{
    NSDictionary *paramsDic = @{@"action": @"settings",
                                @"what": @"station_delay",
                                @"pid": [NSNumber numberWithInt:programId],
                                @"delay" : [NSNumber numberWithInt:delay_minutes],
                                @"delay_on" : [NSNumber numberWithInt:delay_on]
                                };
    
    [self.manager POST:@"/ui.cgi" parameters:paramsDic
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       ServerResponse *response = nil;
                       if (responseObject) {
                           NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                           response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                       }
                       [_delegate serverResponseReceived:response serverProxy:self userInfo:paramsDic];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)saveZone:(Zone *)zone {
    if ([ServerProxy usesAPI3]) {
        [self saveZone3:zone];
    } else {
        [self saveZone4:(ZoneProperties4*)zone];
    }
}

- (void)saveZone4:(ZoneProperties4 *)zone {
    NSDictionary *params = @{@"name" : zone.name,
                             @"type" : @(zone.vegetation),
                             @"active" : @(zone.active),
                             @"internet" : zone.internet,
                             @"history" : zone.history,
                             @"savings" : zone.savings,
                             @"slope" : zone.slope,
                             @"sun" : zone.sun,
                             @"soil" : zone.soil,
                             @"master" : @(zone.masterValve),
                             @"before": @(zone.before),
                             @"after" : @(zone.after),
                             @"waterSense" : [zone.advancedProperties toDictionary]
                             };
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? @"api/4/zone/%d/properties" : @"api/4/zoneProperties/%d";
    [self.manager POST: [self urlByAppendingAccessTokenToUrl:[NSString stringWithFormat:relUrl, zone.zoneId]] parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            id responseArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
            [self.delegate serverResponseReceived:responseArray[0] serverProxy:self userInfo:params];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)saveZone3:(Zone *)zone {
    if (zone) {
        NSDictionary *params = @{@"id" : @(zone.zoneId), @"active" : @(zone.active), @"after" : @(zone.after), @"before": @(zone.before),
                                 @"forecastData" : @(zone.forecastData), @"historicalAverage" : @(zone.historicalAverage), @"masterValve" : @(zone.masterValve),
                                 @"name" : zone.name, @"vegetation" : [NSString stringWithFormat:@"%d", zone.vegetation]};
        NSString *url = [NSString stringWithFormat:@"ui.cgi?action=settings&what=zones&zid=%d", zone.zoneId];
        [self.manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                NSArray *response = nil;
                if (responseObject) {
                    NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])];
                    response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                }
                [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error fromOperation:operation userInfo:nil];
        }];
    }
}

- (void)requestUpdateStartForVersion:(int)version
{
    NSString *relUrl = ([[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] && version == 4) ? @"api/%d/machine/update" : @"api/%d/update";
    relUrl = [NSString stringWithFormat:relUrl, version];
    
    if (version == 4) relUrl = [self urlByAppendingAccessTokenToUrl:relUrl]; // Append access token for API 4
    
    [self.manager POST:relUrl parameters:@{@"update": [NSNumber numberWithBool:YES]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([UpdateStartInfo class])];

            UpdateStartInfo *updateStartInfo = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            [self.delegate serverResponseReceived:updateStartInfo serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestUpdateCheckForVersion:(int)version
{
    NSString *relUrl = ([[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] && version == 4) ? @"api/%d/machine/update" : @"api/%d/update";
    relUrl = [NSString stringWithFormat:relUrl, version];
    
    if (version == 4) relUrl = [self urlByAppendingAccessTokenToUrl:relUrl]; // Append access token for API 4
    
    [self.manager GET:[NSString stringWithFormat:relUrl, version] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            id updateInfo = nil;
            if ([ServerProxy usesAPI3]) {
                UpdateInfo *updateInfo3 = [UpdateInfo createFromJson:responseObject];
                updateInfo = updateInfo3;
            } else {
                UpdateInfo4 *updateInfo4 = [UpdateInfo4 createFromJson:responseObject];
                updateInfo = updateInfo4;
            }
            [self.delegate serverResponseReceived:updateInfo serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestAPIVersion
{
    [self.manager GET:@"api/apiVer" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
            NSArray *parsedArray = responseObject ? [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([APIVersion class])] : nil;
            APIVersion *version = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            if (!version.apiVer) {
                // Most likely the response is from API4
                NSArray *parsedArray = responseObject ? [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([APIVersion4 class])] : nil;
                version = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            }
            [self.delegate serverResponseReceived:version serverProxy:self userInfo:@"apiVer"];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:@"apiVer"];
    }];
}


- (void)requestAPIVersionWithTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:@"GET"
                                                                           URLString:[[NSURL URLWithString:[self urlByAppendingAccessTokenToUrl:@"api/apiVer"] relativeToURL:self.manager.baseURL] absoluteString]
                                                                          parameters:nil];
    request.timeoutInterval = timeoutInterval;
    
    AFHTTPRequestOperation *operation =
    [self.manager HTTPRequestOperationWithRequest:request
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              
                                              if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                                                  NSArray *parsedArray = responseObject ? [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([APIVersion class])] : nil;
                                                  APIVersion *version = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                  if (!version.apiVer) {
                                                      // Most likely the response is from API4
                                                      NSArray *parsedArray = responseObject ? [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([APIVersion4 class])] : nil;
                                                      version = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                  }
                                                  [self.delegate serverResponseReceived:version serverProxy:self userInfo:@"apiVer"];
                                              }
                                              
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              [self handleError:error fromOperation:operation userInfo:@"apiVer"];
                                          }];
    [self.manager.operationQueue addOperation:operation];
}

- (void)reboot {
    NSString *relUrl = [[[NSUserDefaults standardUserDefaults] objectForKey:kDebugNewAPIVersion] boolValue] ? [self urlByAppendingAccessTokenToUrl:@"api/4/machine/reboot"] : [self urlByAppendingAccessTokenToUrl:@"api/4/reboot"];
    [self.manager POST:relUrl parameters:@{}
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       NSArray *rezArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([API4StatusResponse class])];
                       [self.delegate serverResponseReceived:[rezArray firstObject] serverProxy:self userInfo:@"stopped"];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)handleError:(NSError *)error fromOperation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    if ([self passLoggedOutFilter:operation]) {
        // Just a simple error
        DLog(@"NetworkError: %@", error);
        BOOL cancelled = ([error code] == NSURLErrorCancelled) && ([[error domain] isEqualToString:NSURLErrorDomain]);
        if (!cancelled) {
            [_delegate serverErrorReceived:error serverProxy:self operation:operation userInfo:userInfo];
        }
    }
}

- (BOOL)passErrorFilter:(id)responseObject
{
    if ([ServerProxy usesAPI3]) {
        return YES;
    }
    
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSArray *allKeys = [responseObject allKeys];
        if (allKeys.count == 2) {
            if ((([allKeys[0] isEqualToString:@"message"]) && ([allKeys[1] isEqualToString:@"statusCode"])) ||
                (([allKeys[1] isEqualToString:@"message"]) && ([allKeys[0] isEqualToString:@"statusCode"]))) {
                NSNumber *statusCode = [responseObject objectForKey:@"statusCode"];
                if ([statusCode intValue] != API4StatusCode_Success) {
                    NSString *message = [responseObject objectForKey:@"message"];
                    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                    [userInfo setValue:message forKey:NSLocalizedDescriptionKey];
                    [self handleError:[NSError errorWithDomain:@"Sprinkler" code:[statusCode intValue] userInfo:userInfo] fromOperation:nil userInfo:nil];
                    return NO;
                }
            }
        }
    } else {
        assert(0); // TODO: remove it from API4 code at the end
    }
    
    return YES;
}

- (BOOL)passLoggedOutFilter:(AFHTTPRequestOperation *)operation
{
    if ([self isLoggedOut:operation]) {
        DLog(@"NetworkError. Logged out error received");
        [self.delegate loggedOut];
        return NO;
    }

    return YES;
}

- (BOOL)isLoggedOut:(AFHTTPRequestOperation *)operation
{
    BOOL isLoggedOut = NO;
    NSData *responseData = [operation responseData];
    if ([ServerProxy usesAPI3]) {
        if ([@"{ \"status\":\"OUT\",\"message\":\"LOgged OUT\"}" isEqualToString:[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]]) {
            return YES;
        }
        
        if ((([[[operation response] MIMEType] isEqualToString:@"json/html"]) ||
             ([[[operation response] MIMEType] isEqualToString: @"text/plain"])) &&
            (responseData)) {
            NSError *jsonError = nil;
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:nil error:&jsonError];
            if (!jsonError) {
                if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                    // On Android, the 'status' field length is tested. Make it so on iOS too. (See mail on Apr 29)
                    if (([[jsonObject objectForKey:@"message"] isEqualToString:@"LOgged OUT"]) &&
                        ([[jsonObject objectForKey:@"status"] length] > 0)) {
                        isLoggedOut = YES;
                    }
                }
            }
        }
    } else {
        if (responseData) {
            NSError *jsonError = nil;
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:nil error:&jsonError];
            if ((API4StatusCode)[[jsonObject objectForKey:@"statusCode"] intValue] == API4StatusCode_LoggedOut) {
                isLoggedOut = YES;
            }
        }
    }

    return isLoggedOut;
}

#pragma mark - Cloud

- (void)validateEmail:(NSString*)email deviceName:(NSString*)deviceName mac:(NSString*)mac
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (email) params[@"email"] = email;
    if (deviceName) params[@"deviceName"] = deviceName;
    if (mac) params[@"mac"] = mac;
    params[@"apiKey"] = kSprinklerAPIKey;
    
    [self.manager POST:@"validate-email" parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:@"validate-email-cloud"];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)requestCloudSprinklers:(NSDictionary*)accounts phoneID:(NSString*)phoneID {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:@"credentials"];
    for (NSString *email in accounts) {
        [params[@"credentials"] addObject:@{@"email" : email, @"pwd" : accounts[email]}];
    }
    if (phoneID.length) params[@"phoneID"] = phoneID;

    [self.manager POST:@"get-sprinklers" parameters:params
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:responseObject serverProxy:self userInfo:@"get-sprinklers-cloud"];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)requestCloudSettings {
    [self.manager GET:[self urlByAppendingAccessTokenToUrl:@"api/4/provision/cloud"] parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                      CloudSettings *cloudSettings = [CloudSettings createFromJson:responseObject];
                      [self.delegate serverResponseReceived:cloudSettings serverProxy:self userInfo:nil];
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation userInfo:nil];
              }];
}

- (void)saveCloudSettings:(CloudSettings*)cloudSettings {
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision/cloud"] parameters:cloudSettings.toDictionary
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)enableRemoteAccess:(BOOL)enable {
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision/cloud/enable"] parameters:@{@"enable" : @(enable)}
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

- (void)saveCloudEmail:(NSString*)email {
    [self.manager POST:[self urlByAppendingAccessTokenToUrl:@"api/4/provision/cloud/email"] parameters:@{@"email" : email}
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (([self passLoggedOutFilter:operation]) && ([self passErrorFilter:responseObject])) {
                       [self.delegate serverResponseReceived:[ServerProxy fromJSON:responseObject toClass:NSStringFromClass([API4StatusResponse class])] serverProxy:self userInfo:nil];
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation userInfo:nil];
               }];
}

#pragma mark - Response/request objects conversion

+ (NSArray*)fromJSONArray:(NSArray*)jsonArray toClass:(NSString*)className
{
    NSMutableArray *responseArray = [NSMutableArray array];
    for (NSDictionary *jsonDic in jsonArray) {
        [responseArray addObject:[ServerProxy fromJSON:jsonDic toClass:className]];
    }
    
    return responseArray;
}

+ (id)fromJSON:(NSDictionary*)jsonDic toClass:(NSString*)className
{
    Class ObjectClass = NSClassFromString(className);
    
    if (ObjectClass == nil) {
        DLog(@"Error: class of type '%@' doesn't exist.", className);
        return nil;
    }
    
    NSObject* loadedObject = [[ObjectClass alloc] init];
    
    for (NSString *key in jsonDic) {
        if ([loadedObject respondsToSelector:NSSelectorFromString(key)]) {
            // Use the following lines to debug types of received data members
//            objc_property_t property = class_getProperty(ObjectClass, [key UTF8String]);
//            const char * type = property_getAttributes(property);
//            NSString *typeString = [NSString stringWithUTF8String:type];
//            NSArray *attributes = [typeString componentsSeparatedByString:@","];
//            Class typeAttributeClass = NSClassFromString([attributes objectAtIndex:0]);
//            NSLog(@"%@. type in dict:%@ type in receiving class:%@", key, NSStringFromClass([[jsonDic valueForKey:key] class]), typeAttributeClass);
            [loadedObject setValue:[jsonDic valueForKey:key] forKey:key];
        } else {
            DLog(@"Error: response object of class %@ doesn't implement property '%@' of type %@", className, key, NSStringFromClass([[jsonDic valueForKey:key] class]));
        }
    }
    
    return loadedObject;
}

- (NSDictionary *)toDictionaryFromObject:(id)object {
    unsigned int outCount, i;
    NSMutableDictionary *dict = [NSMutableDictionary new];
    objc_property_t *properties = class_copyPropertyList([object class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if (propName) {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            id prop = [object valueForKey:propertyName];
            if ([prop isKindOfClass:[NSDate class]]) {
                NSDate *date = (NSDate*)prop;
                [dict setObject:[NSNumber numberWithDouble:[date timeIntervalSince1970]] forKey:propertyName];
            }
            else if ([prop isKindOfClass:[NSArray class]]) {
                NSMutableArray *archivedArray = [NSMutableArray array];
                NSArray *array = (NSArray *)prop;
                for (id obj in array) {
                    [archivedArray addObject:[self toDictionaryFromObject:obj]];
                }
                [dict setObject:archivedArray forKey:propertyName];
            } else {
                id objectValue = [object valueForKey:propertyName];
                if (objectValue) {
                    [dict setObject:objectValue forKey:propertyName];
                }
            }
        }
    }
    free(properties);
    
    return dict;
}

- (NSData*)toJSONFromObject:(id)object {
    NSDictionary *dict = [self toDictionaryFromObject:object];
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    //  NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (error) {
        DLog(@"Error encoding object of type '%@': %@", NSStringFromClass([object class]), error);
    }
    return data;
}

@end
