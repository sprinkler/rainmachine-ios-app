//
//  GoogleRequest.m
//  Sprinklers
//
//  Created by Istvan Sipos on 18/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GoogleRequest.h"

NSString *GoogleRequestResultTypeJson   = @"json";
NSString *GoogleRequestResultTypeXml    = @"xml";

#pragma mark -

@interface GoogleRequest ()

@property (nonatomic, readonly) NSString *parameterString;
@property (nonatomic, readonly) NSString *googleRequestURL;

- (NSDictionary*)parseResponseData:(NSData*)responseData;
- (NSDictionary*)parseJsonData:(NSData*)responseData;
- (NSDictionary*)parseXmlData:(NSData*)responseData;

@property (nonatomic, copy) GoogleRequestCompletionHandler completionHandler;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *responseData;

@end

#pragma mark -

@implementation GoogleRequest

#pragma mark - Init

+ (instancetype)googleRequestWithParameters:(NSDictionary*)parameters {
    return [[self alloc] initWithParameters:parameters];
}

- (instancetype)initWithParameters:(NSDictionary*)parameters {
    self = [super init];
    if (!self) return nil;
    
    _parameters = parameters;
    _resultType = GoogleRequestResultTypeJson;
    
    return self;
}

- (void)executeRequestWithCompletionHandler:(GoogleRequestCompletionHandler)completionHandler {
    if (!self.googleRequestBaseURL) completionHandler(nil, nil);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.googleRequestURL]];
    [request setValue:[NSString stringWithFormat:@"application/%@",self.resultType] forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    
    self.completionHandler = completionHandler;
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.responseData = [NSMutableData new];
}

- (void)cancelRequest {
    [self.connection cancel];
    self.connection = nil;
    self.responseData = nil;
}

- (id)resultFromDictionary:(NSDictionary*)dictionary {
    return nil;
}

#pragma mark - Request configuration

- (NSString*)googleRequestBaseURL {
    return nil;
}

- (NSString*)googleAPIKey {
    return nil;
}

- (NSString*)parameterString {
    NSMutableArray *parameterPairsArray = [NSMutableArray new];
    for (NSString *key in self.parameters) {
        NSString *value = [self.parameters[key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [parameterPairsArray addObject:[NSString stringWithFormat:@"%@=%@",key,value]];
    }
    if (self.googleAPIKey.length) [parameterPairsArray addObject:[NSString stringWithFormat:@"key=%@",self.googleAPIKey]];
    return [parameterPairsArray componentsJoinedByString:@"&"];
}

- (NSString*)googleRequestURL {
    NSString *parameterString = self.parameterString;
    if (self.parameterString.length) return [NSString stringWithFormat:@"%@/%@?%@",self.googleRequestBaseURL,self.resultType,parameterString];
    return [NSString stringWithFormat:@"%@/%@",self.googleRequestBaseURL,self.resultType];
}

- (NSDictionary*)parseResponseData:(NSData*)responseData {
    if ([self.resultType isEqualToString:GoogleRequestResultTypeJson]) return [self parseJsonData:responseData];
    else if ([self.resultType isEqualToString:GoogleRequestResultTypeXml]) return [self parseXmlData:responseData];
    return nil;
}

- (NSDictionary*)parseJsonData:(NSData*)responseData {
    return [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
}

- (NSDictionary*)parseXmlData:(NSData*)responseData {
    return nil;
}

#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    self.responseData = nil;
    if (self.completionHandler) self.completionHandler(nil, error);
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    NSDictionary *responseDictionary = [self parseResponseData:self.responseData];
    self.responseData = nil;
    id result = [self resultFromDictionary:responseDictionary];
    if (self.completionHandler) self.completionHandler(result, nil);
}

@end
