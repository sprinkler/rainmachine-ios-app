//
//  GoogleRequest.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *GoogleRequestResultTypeJson;
extern NSString *GoogleRequestResultTypeXml;

typedef void (^GoogleRequestCompletionHandler)(id result, NSError *error);

@interface GoogleRequest : NSObject <NSURLConnectionDelegate>

@property (nonatomic, readonly) NSString *googleRequestBaseURL;
@property (nonatomic, readonly) NSString *googleAPIKey;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, strong) NSString *resultType;

+ (instancetype)googleRequestWithParameters:(NSDictionary*)parameters;
- (instancetype)initWithParameters:(NSDictionary*)parameters;
- (void)executeRequestWithCompletionHandler:(GoogleRequestCompletionHandler)completionHandler;
- (void)cancelRequest;
- (id)resultFromDictionary:(NSDictionary*)dictionary;

@end
