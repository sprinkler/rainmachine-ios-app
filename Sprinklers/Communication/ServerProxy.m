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
#import "RestrictionsData.h"
#import "WaterNowZone.h"
#import "StartStopWatering.h"
#import "SetRainDelay.h"
#import "ServerResponse.h"
#import "Utils.h"
#import "Program.h"
#import "APIVersion.h"
#import "UpdateInfo.h"
#import "UpdateStartInfo.h"
#import "StorageManager.h"
#import "RainDelay.h"
#import "SettingsUnits.h"
#import "SettingsDate.h"
#import "SettingsPassword.h"
#import "StartStopProgramResponse.h"

@implementation ServerProxy

- (id)initWithServerURL:(NSString *)serverURL delegate:(id<SprinklerResponseProtocol>)del jsonRequest:(BOOL)jsonRequest {
    self = [super init];
    if (!self) {
        return nil;
    }
    
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
        
- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe
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
                                      if ([[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self.manager baseURL]] count] > 0) {
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
                                                 
                                                 if ([self passLoggedOutFilter:operation]) {
                                                     NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([SettingsUnits class])];
                                                     SettingsUnits *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                     [self.delegate loginSucceededAndRemembered:[self isLoginRememberedForCurrentSprinkler] unit:response.units];
                                                 }
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation userInfo:nil];
                                             }];
}

- (BOOL)isLoginRememberedForCurrentSprinkler
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self.manager baseURL]];
    for (NSHTTPCookie *cookie in cookies) {
        if (([[cookie name] isEqualToString:@"login"]) && (![cookie isSessionOnly])) {
            return YES;
        }
    }
    
    return NO;
}

- (void)requestWateringRestrictions
{
    DLog(@"%s", __PRETTY_FUNCTION__);
    
        [self.manager GET:@"/api/4/wateringrestrictions" parameters: nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"wateringrestrictions"] toClass:NSStringFromClass([RestrictionsData class])] serverProxy:self userInfo:nil];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error fromOperation:operation userInfo:nil];
        }];
}

#pragma mark - Settings

- (void)setNewPassword:(NSString*)newPassword confirmPassword:(NSString*)confirmPassword oldPassword:(NSString*)oldPassword
{
    [self.manager POST:@"/ui.cgi?action=settings&what=password" parameters:@{@"newPass" : newPassword,
                                                                             @"confirmPass" : confirmPassword,
                                                                             @"oldPass" : oldPassword
                                                                             } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
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
        
        if ([self passLoggedOutFilter:operation]) {
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
                                                  
      if ([self passLoggedOutFilter:operation]) {
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
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings",
                                             @"what" : @"timedate"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 
                                                 if ([self passLoggedOutFilter:operation]) {
                                                     NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"settings"]] toClass:NSStringFromClass([SettingsDate class])];
                                                     ServerResponse *response = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
                                                     [self.delegate serverResponseReceived:response serverProxy:self userInfo:nil];
                                                 }
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation userInfo:nil];
                                             }];
}

- (void)setSettingsDate:(SettingsDate*)settingsDate
{
    NSDictionary *params = [self toDictionaryFromObject:settingsDate];
    
    [self.manager POST:@"/ui.cgi?action=settings&what=timedate" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
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
                                                 
                                                 if ([self passLoggedOutFilter:operation]) {
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
        
        if ([self passLoggedOutFilter:operation]) {
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

#pragma mark - Wheather

- (void)requestWeatherData
{
    [self.manager GET: @"ui.cgi" parameters:@{@"action": @"weatherdata"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey: @"HomeScreen"] toClass:NSStringFromClass([WeatherData class])] serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

// Get Zones list (Used in Water Now main screen)
- (void)requestWaterNowZoneList
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zones"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([WaterNowZone class])] serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    // TODO: comment out Debug server code
//    NSArray *responseObject = [NSArray arrayWithObjects:
//                               [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:2], @"id", @"mere", @"name", @"Unknown", @"type", @"Pending", @"state", nil],
//                               [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3], @"id", @"pere", @"name", @"Unknown", @"type", @"Watering", @"state", nil],
//                               [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3], @"id", @"pere", @"name", @"Unknown", @"type", @"", @"state", nil],
//                               [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3], @"id", @"pere", @"name", @"Unknown", @"type", @"Watering", @"state", [NSNumber numberWithInteger:180], @"counter", nil],
//                               nil];
//    [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:responseObject toClass:NSStringFromClass([SPWaterNowZone class])]];

        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

// Request one single zone (Used in Water Now->Zone screen)
- (void)requestWaterActionsForZone:(NSNumber*)zoneId
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zoneedit",
                                             @"zid": zoneId} success:^(AFHTTPRequestOperation *operation, id responseObject) {

                                                 if ([self passLoggedOutFilter:operation]) {
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

// Toggle a zone (Used in Water Now->Zone screen and when toggling watering using switches from main screen)
// Return value means: YES - if watering started, NO - if watering stopped
- (BOOL)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter
{
    BOOL isIdle = [Utils isZoneIdle:zone];
    StartStopWatering *startStopWatering = [StartStopWatering new];
    startStopWatering.id = zone.id;
    startStopWatering.counter = isIdle ? [Utils fixedZoneCounter:counter isIdle:isIdle] : [NSNumber numberWithInteger:0];

    zone.counter = startStopWatering.counter;
    
    NSDictionary *params = [self toDictionaryFromObject:startStopWatering];
    [self.manager POST:[NSString stringWithFormat:@"/ui.cgi?action=zonesave&from=zoneedit&zid=%@", zone.id] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The server returns an empty response when success
        if ([self passLoggedOutFilter:operation]) {
            [self.delegate serverResponseReceived:nil serverProxy:self userInfo:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
    
    return [startStopWatering.counter intValue] != 0;
}

- (void)getRainDelay {
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings", @"what": @"rainDelay"}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if ([self passLoggedOutFilter:operation]) {
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
    NSDictionary *params = [NSDictionary dictionaryWithObject:value forKey:@"rainDelay"];
    [self.manager POST:@"/ui.cgi?action=settings&what=rainDelay" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self passLoggedOutFilter:operation]) {
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

- (void)requestZones {
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings", @"what": @"zones"}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if ([self passLoggedOutFilter:operation]) {
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

- (void)requestPrograms {
    [self.manager GET:@"ui.cgi" parameters:@{@"action" : @"settings", @"what" : @"programs"}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  if ([self passLoggedOutFilter:operation]) {
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

- (void)runNowProgram:(Program*)program {
    if (program) {
        // 3.55 and 3.56 can only Stop programs
        [self.manager POST:@"/ui.cgi" parameters:@{@"action" : @"settings",
                                                   @"what" : [Utils isDevice357Plus] ? @"run_now" : @"stop_now",
                                                   @"pid" : [NSNumber numberWithInt:program.programId]}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self passLoggedOutFilter:operation]) {
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
    if (program) {
        //        NSMutableDictionary *params = [[self toDictionaryFromObject:program] mutableCopy];
        //        [params setObject:[Utils formattedTime:program.startTime forTimeFormat:program.timeFormat] forKey:@"programStartTime"];
        //        [params removeObjectForKey:@"startTime"];
        NSDictionary *params = [program toDictionary];
        
        [self.manager POST:@"ui.cgi?action=settings&what=programs" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self passLoggedOutFilter:operation]) {
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
    NSDictionary *paramsDic = @{@"action": @"settings",
                                @"what": @"delete_program",
                                @"pid": [NSNumber numberWithInt:programId]};

    [self.manager POST:@"/ui.cgi" parameters:paramsDic
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
           if ([self passLoggedOutFilter:operation]) {
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
                   if ([self passLoggedOutFilter:operation]) {
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
                   if ([self passLoggedOutFilter:operation]) {
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
    if (zone) {
        NSDictionary *params = @{@"id" : @(zone.zoneId), @"active" : @(zone.active), @"after" : @(zone.after), @"before": @(zone.before),
                                 @"forecastData" : @(zone.forecastData), @"historicalAverage" : @(zone.historicalAverage), @"masterValve" : @(zone.masterValve),
                                 @"name" : zone.name, @"vegetation" : [NSString stringWithFormat:@"%d", zone.vegetation]};
        NSString *url = [NSString stringWithFormat:@"ui.cgi?action=settings&what=zones&zid=%d", zone.zoneId];
        [self.manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self passLoggedOutFilter:operation]) {
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
    NSString *requestUrl = [NSString stringWithFormat:@"api/%d/update", version];
    [self.manager POST:requestUrl parameters:@{@"update": [NSNumber numberWithBool:YES]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
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
    NSString *requestUrl = [NSString stringWithFormat:@"api/%d/update", version];
    [self.manager GET:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            UpdateInfo *updateInfo = [UpdateInfo createFromJson:responseObject];
            [self.delegate serverResponseReceived:updateInfo serverProxy:self userInfo:nil];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:nil];
    }];
}

- (void)requestAPIVersion
{
    [self.manager GET:@"api/apiVer" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([APIVersion class])];
            APIVersion *version = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            [self.delegate serverResponseReceived:version serverProxy:self userInfo:@"apiVer"];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation userInfo:@"apiVer"];
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
    NSData *responseData = [operation responseData];
    if ([@"{ \"status\":\"OUT\",\"message\":\"LOgged OUT\"}" isEqualToString:[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]]) {
        return YES;
    }
    
    BOOL isLoggedOut = NO;
    NSError *jsonError = nil;
    if ((([[[operation response] MIMEType] isEqualToString:@"json/html"]) ||
         ([[[operation response] MIMEType] isEqualToString: @"text/plain"])) &&
        (responseData)) {
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

    return isLoggedOut;
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
