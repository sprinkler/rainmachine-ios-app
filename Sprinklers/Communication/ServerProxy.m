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
#import "ServerResponse.h"
#import "Utils.h"
#import "Program.h"
#import "APIVersion.h"
#import "UpdateInfo.h"
#import "UpdateStartInfo.h"
#import "StorageManager.h"

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
                                       [self.delegate loginSucceededAndRemembered:[self isLoginRememberedForCurrentSprinkler]];
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      BOOL success = NO;
                                      if ([[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self.manager baseURL]] count] > 0) {
                                        if ([[[operation response] MIMEType] isEqualToString:@"text/html"]) {
                                          success = YES;
                                        }
                                      }
                                      if (success) {
                                        [self.delegate loginSucceededAndRemembered:[self isLoginRememberedForCurrentSprinkler]];
                                      } else {
                                        NSHTTPURLResponse *response = operation.response;
                                        if ((NSUInteger)response.statusCode == 200) {
                                          [self.delegate loggedOut];
                                        } else {
                                          [self handleError:error fromOperation:operation];
                                        }
                                      }
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
                
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"wateringrestrictions"] toClass:NSStringFromClass([RestrictionsData class])] serverProxy:self];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error fromOperation:operation];
        }];
}

- (void)requestWeatherData
{
    [self.manager GET: @"ui.cgi" parameters:@{@"action": @"weatherdata"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey: @"HomeScreen"] toClass:NSStringFromClass([WeatherData class])] serverProxy:self];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [self handleError:error fromOperation:operation];
    }];
}

// Get Zones list (Used in Water Now main screen)
- (void)requestWaterNowZoneList
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zones"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([WaterNowZone class])] serverProxy:self];
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

        [self handleError:error fromOperation:operation];
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
                                                         [self.delegate serverResponseReceived:zone serverProxy:self];
                                                     }
                                                 }

                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [self handleError:error fromOperation:operation];
                                             }];
}

// Toggle a zone (Used in Water Now->Zone screen and when toggling watering using switches from main screen)
- (void)toggleWateringOnZone:(WaterNowZone*)zone withCounter:(NSNumber*)counter
{
    BOOL isIdle = [Utils isZoneIdle:zone];
    StartStopWatering *startStopWatering = [StartStopWatering new];
    startStopWatering.id = zone.id;
    startStopWatering.counter = isIdle ? [Utils fixedZoneCounter:counter isIdle:isIdle] : [NSNumber numberWithInteger:0];

    NSDictionary *params = [self toDictionaryFromObject:startStopWatering];
    [self.manager POST:[NSString stringWithFormat:@"/ui.cgi?action=zonesave&from=zoneedit&zid=%@", zone.id] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The server returns an empty response when success
        if ([self passLoggedOutFilter:operation]) {
            [self.delegate serverResponseReceived:nil serverProxy:self];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation];
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
                          if (_delegate && [_delegate respondsToSelector:@selector(serverResponseReceived:serverProxy:)]) {
                              [_delegate serverResponseReceived:returnValues serverProxy:self];
                          }
                      }
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation];
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
                          if (_delegate && [_delegate respondsToSelector:@selector(serverResponseReceived:serverProxy:)]) {
                              [_delegate serverResponseReceived:returnValues serverProxy:self];
                          }
                      }
                  }
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [self handleError:error fromOperation:operation];
              }];
}

- (void)deleteProgram:(int)programId {
    [self.manager POST:@"ui.cgi?action=settings&what=programs" parameters:@{@"id": @(programId)}
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if ([self passLoggedOutFilter:operation]) {
                       if (_delegate && [_delegate respondsToSelector:@selector(programDeleted:)]) {
                           [_delegate programDeleted:programId];
                       }
                   }
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   [self handleError:error fromOperation:operation];
               }];
     
}

- (void)saveZone:(Zone *)zone {
    if (zone) {
        NSDictionary *params = @{@"id" : @(zone.zoneId), @"active" : @(zone.active), @"after" : @(zone.after), @"before": @(zone.before),
                                 @"forecastData" : @(zone.forecastData), @"historicalAverage" : @(zone.historicalAverage), @"masterValve" : @(zone.masterValve),
                                 @"name" : zone.name, @"vegetation" : @(zone.vegetation)};
        [self.manager POST:@"ui.cgi?action=settings&what=zones" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([self passLoggedOutFilter:operation]) {
                [self.delegate serverResponseReceived:[ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([ServerResponse class])] serverProxy:self];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self handleError:error fromOperation:operation];
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
            [self.delegate serverResponseReceived:updateStartInfo serverProxy:self];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation];
    }];
}


- (void)requestUpdateCheckForVersion:(int)version
{
    NSString *requestUrl = [NSString stringWithFormat:@"api/%d/update", version];
    [self.manager GET:requestUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            UpdateInfo *updateInfo = [UpdateInfo createFromJson:responseObject];
            [self.delegate serverResponseReceived:updateInfo serverProxy:self];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation];
    }];
}

- (void)requestAPIVersion
{
    [self.manager GET:@"api/apiVer" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if ([self passLoggedOutFilter:operation]) {
            NSArray *parsedArray = [ServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject] toClass:NSStringFromClass([APIVersion class])];
            APIVersion *version = ([parsedArray count] > 0) ? [parsedArray firstObject] : nil;
            [self.delegate serverResponseReceived:version serverProxy:self];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error fromOperation:operation];
    }];
}

- (void)handleError:(NSError *)error fromOperation:(AFHTTPRequestOperation *) operation {
    if ([self passLoggedOutFilter:operation]) {
        // Just a simple error
        DLog(@"NetworkError: %@", error);
        BOOL cancelled = ([error code] == NSURLErrorCancelled) && ([[error domain] isEqualToString:NSURLErrorDomain]);
        if (!cancelled) {
            [_delegate serverErrorReceived:error serverProxy:self];
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
                if (([[jsonObject objectForKey:@"message"] isEqualToString:@"LOgged OUT"]) &&
                    ([[jsonObject objectForKey:@"status"] isEqualToString:@"OUT"])) {
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
            [dict setObject:[object valueForKey:propertyName] forKey:propertyName];
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
