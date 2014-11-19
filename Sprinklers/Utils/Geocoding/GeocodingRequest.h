//
//  GeocodingRequest.h
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *GeocodingRequestResultTypeJson;
extern NSString *GeocodingRequestResultTypeXml;

typedef void (^GeocodingRequestCompletionHandler)(id result, NSError *error);

@interface GeocodingRequest : NSObject

@property (nonatomic, readonly) NSString *geocodingRequestBaseURL;
@property (nonatomic, readonly) NSString *geocodingAPIKey;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, strong) NSString *resultType;

+ (instancetype)geocodingRequestWithParameters:(NSDictionary*)parameters;
- (instancetype)initWithParameters:(NSDictionary*)parameters;
- (void)executeRequestWithCompletionHandler:(GeocodingRequestCompletionHandler)completionHandler;
- (id)resultFromDictionary:(NSDictionary*)dictionary;

@end
