//
//  GeocodingRequest.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GeocodingRequest.h"

NSString *GeocodingRequestResultTypeJson    = @"json";
NSString *GeocodingRequestResultTypeXml     = @"xml";

#pragma mark -

@interface GeocodingRequest ()

@property (nonatomic, readonly) NSString *parameterString;
@property (nonatomic, readonly) NSString *geocodingRequestURL;

- (NSDictionary*)parseResponseData:(NSData*)responseData;
- (NSDictionary*)parseJsonData:(NSData*)responseData;
- (NSDictionary*)parseXmlData:(NSData*)responseData;

@end

#pragma mark -

@implementation GeocodingRequest

#pragma mark - Init

+ (instancetype)geocodingRequestWithParameters:(NSDictionary*)parameters {
    return [[self alloc] initWithParameters:parameters];
}

- (instancetype)initWithParameters:(NSDictionary*)parameters {
    self = [super init];
    if (!self) return nil;
    
    _parameters = parameters;
    _resultType = GeocodingRequestResultTypeJson;
    
    return self;
}

- (void)executeRequestWithCompletionHandler:(GeocodingRequestCompletionHandler)completionHandler {
    if (!self.geocodingRequestBaseURL) completionHandler(nil, nil);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.geocodingRequestURL]];
    [request setValue:[NSString stringWithFormat:@"application/%@",self.resultType] forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSDictionary *responseDictionary = nil;
        id result = nil;
        if (!connectionError) responseDictionary = [self parseResponseData:data];
        if (responseDictionary) result = [self resultFromDictionary:responseDictionary];
        completionHandler(result, connectionError);
    }];
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    return nil;
}

#pragma mark - Request configuration

- (NSString*)geocodingRequestBaseURL {
    return nil;
}

- (NSString*)parameterString {
    NSMutableArray *parameterPairsArray = [NSMutableArray new];
    for (NSString *key in self.parameters) {
        NSString *value = self.parameters[key];
        [parameterPairsArray addObject:[NSString stringWithFormat:@"%@=%@",key,value]];
    }
    return [parameterPairsArray componentsJoinedByString:@"&"];
}

- (NSString*)geocodingRequestURL {
    NSString *parameterString = self.parameterString;
    if (self.parameterString.length) return [NSString stringWithFormat:@"%@/%@?%@",self.geocodingRequestBaseURL,self.resultType,parameterString];
    return [NSString stringWithFormat:@"%@/%@",self.geocodingRequestBaseURL,self.resultType];
}

- (NSDictionary*)parseResponseData:(NSData*)responseData {
    if ([self.resultType isEqualToString:GeocodingRequestResultTypeJson]) return [self parseJsonData:responseData];
    else if ([self.resultType isEqualToString:GeocodingRequestResultTypeXml]) return [self parseXmlData:responseData];
    return nil;
}

- (NSDictionary*)parseJsonData:(NSData*)responseData {
    return [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
}

- (NSDictionary*)parseXmlData:(NSData*)responseData {
    return nil;
}

@end
