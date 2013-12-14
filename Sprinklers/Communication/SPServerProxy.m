//
//  SPServerProxy.m
//  AFNetworking iOS Example
//
//  Created by Fabian Matyas on 02/12/13.
//  Copyright (c) 2013 Gowalla. All rights reserved.
//

#import "SPServerProxy.h"
#import "AFHTTPRequestOperationManager.h"
#import "SPWeatherData.h"
#import "SPZoneProperty.h"
#import "SPWaterNowZone.h"
#import "SPStartStopWatering.h"
#import "SPZonePropertiesResponse.h"
#import <objc/runtime.h>

@implementation SPServerProxy

- (id)initWithServerURL:(NSString*)serverURL delegate:(id<SPSprinklerResponseProtocol>)del {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.delegate = del;
    self.serverURL = serverURL;
    
//    [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingOperationDidStartNotification
//                                                      object:nil
//                                                       queue:nil
//                                                  usingBlock:^(NSNotification *note) {
//                                                    NSMutableURLRequest *r = (NSMutableURLRequest *)[[note object] request];
//                                                    DLog(@"Operation Started with URL: %@ body: %@", [r URL], [[NSString alloc] initWithData:[r HTTPBody] encoding:NSUTF8StringEncoding]);
//                                                  }];

    NSURL *baseURL = [NSURL URLWithString:serverURL];
    self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];

    // TODO: remove invalid certificates policy in the future
    AFSecurityPolicy *policy = [[AFSecurityPolicy alloc] init];
    [policy setAllowInvalidCertificates:YES];
    [self.manager setSecurityPolicy:policy];
  
    return self;
}

- (void)loginWithUserName:(NSString*)userName password:(NSString*)password rememberMe:(BOOL)rememberMe
{
    NSDictionary *paramsDic;
    if (rememberMe) {
        paramsDic = @{@"action": @"login",
          @"user": userName,
          @"password": password,
          @"remember": @"true"
                      };
    } else {
        paramsDic = @{@"action": @"login",
          @"user": userName,
          @"password": password
                      };
    }
  
    [self.manager POST:@"/ui.cgi" parameters:paramsDic
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         //DLog(@"Success code: %d", [[operation response] statusCode]);
                                       [self.delegate loginSucceeded];
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      BOOL success = NO;
                                      if ([[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self.manager baseURL]] count] > 0) {
                                        if ([[[operation response] MIMEType] isEqualToString:@"text/html"]) {
                                          success = YES;
                                        }
                                      }
                                      if (success) {
                                        [self.delegate loginSucceeded];
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

- (void)requestWeatherData
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"weatherdata"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
      [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[responseObject objectForKey:@"HomeScreen"] toClass:NSStringFromClass([SPWeatherData class])]];
      
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [self handleError:error fromOperation:operation];
    }];
}

- (void)requestZonePropertyList
{
  [self.manager GET:@"ui.cgi" parameters:@{@"action": @"settings",
                                           @"what": @"zones"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
    [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([SPZoneProperty class])]];
  
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self handleError:error fromOperation:operation];
  }];
}

- (void)requestWaterNowZoneList
{
  [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zones"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             
                                             [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[responseObject objectForKey:@"zones"] toClass:NSStringFromClass([SPWaterNowZone class])]];
                                             
                                           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             [self handleError:error fromOperation:operation];
                                           }];
}

- (void)requestWaterActionsForZone:(NSNumber*)zoneId
{
  [self.manager GET:@"ui.cgi" parameters:@{@"action": @"zoneedit",
                                           @"zid": zoneId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
                                             [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[NSArray arrayWithObject:[responseObject objectForKey:@"zones"]]
                                                               toClass:NSStringFromClass([SPWaterNowZone class])]];
    
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self handleError:error fromOperation:operation];
  }];
}

- (void)sendStartStopZoneWatering:(SPStartStopWatering*)zoneProperty
{
  NSDictionary *params = [self toDictionaryFromObject:zoneProperty];
  [self.manager POST:@"ui.cgi?action=zonesave" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
  
    // TODO: figure out the response type
//    [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[responseObject objectForKey:@"Zones"] toClass:NSStringFromClass([SPZoneProperty class])]];
    
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self handleError:error fromOperation:operation];
  }];
}

- (void)sendZoneProperties:(SPZoneProperty*)zoneProperty
{
  NSDictionary *params = [self toDictionaryFromObject:zoneProperty];
  [self.manager POST:@"ui.cgi?action=settings&what=zones" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
    [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[NSArray arrayWithObject:responseObject]
                                                               toClass:NSStringFromClass([SPZonePropertiesResponse class])]];
    
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self handleError:error fromOperation:operation];
  }];
}

- (void)handleError:(NSError*)error fromOperation:(AFHTTPRequestOperation*) operation
{
  BOOL isLoggedOut = NO;
  NSError *jsonError = nil;
  NSData* responseData = [operation responseData];
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
  
  if (isLoggedOut) {
    DLog(@"NetworkError. Logged out error received");
    [self.delegate loggedOut];
  } else {
    // Just a simple error
    DLog(@"NetworkError: %@", error);
    [self.delegate serverErrorReceived:error];
  }
}

#pragma mark - Response/request objects conversion

+ (NSArray*)fromJSONArray:(NSArray*)jsonArray toClass:(NSString*)className
{
  NSMutableArray *responseArray = [NSMutableArray array];
  for (NSDictionary *jsonDic in jsonArray) {
    [responseArray addObject:[SPServerProxy fromJSON:jsonDic toClass:className]];
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
      // Use this line to debug types of received data members
      NSLog(@"%@:, %@", key, NSStringFromClass([[jsonDic valueForKey:key] class]));
      [loadedObject setValue:[jsonDic valueForKey:key] forKey:key];
    } else {
      DLog(@"Error: response object of class %@ doesn't implement property '%@' of type %@", className, key, NSStringFromClass([[jsonDic valueForKey:key] class]));
    }
  }
  
  return loadedObject;
}

- (NSDictionary*)toDictionaryFromObject:(id)object {
  unsigned int outCount, i;
  NSMutableDictionary *dict = [NSMutableDictionary new];
  objc_property_t *properties = class_copyPropertyList([object class], &outCount);
  for(i = 0; i < outCount; i++) {
    objc_property_t property = properties[i];
    const char *propName = property_getName(property);
    if(propName) {
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

- (void)dealloc
{
//  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
