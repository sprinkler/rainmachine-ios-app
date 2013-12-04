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

@implementation SPServerProxy

- (id)initWithServerURL:(NSString*)serverURL delegate:(id<SPSprinklerResponseProtocol>)del {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.delegate = del;
    
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
                                        [self handleError:error fromOperation:operation];
                                      }
                                  }];
}

- (void)requestWeatherData
{
    [self.manager GET:@"ui.cgi" parameters:@{@"action": @"weatherdata"} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
//        DLog(@"Success code: %d", [[operation response] statusCode]);
      [self.delegate serverResponseReceived:[SPServerProxy fromJSONArray:[responseObject objectForKey:@"HomeScreen"] toClass:NSStringFromClass([SPWeatherData class])]];
      
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
      [self handleError:error fromOperation:operation];
    }];
}

- (void)handleError:(NSError*)error fromOperation:(AFHTTPRequestOperation*) operation
{
  BOOL isLoggedOut = NO;
  NSError *jsonError = nil;
  NSData* responseData = [operation responseData];
  if (([[[operation response] MIMEType] isEqualToString:@"json/html"]) && (responseData)) {
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

#pragma mark - Response objects conversion

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
      [loadedObject setValue:[jsonDic valueForKey:key] forKey:key];
    } else {
      DLog(@"Error: response object of class %@ doesn't implement property '%@' of type %@", className, key, NSStringFromClass([[jsonDic valueForKey:key] class]));
    }
  }
  
  return loadedObject;
}

- (void)dealloc
{
//  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
