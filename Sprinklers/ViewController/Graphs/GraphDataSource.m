//
//  GraphDataSource.m
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSource.h"
#import "GraphsManager.h"
#import "ServerProxy.h"
#import "Utils.h"

#pragma mark -

@implementation GraphDataSource

#pragma mark - Initialization

+ (GraphDataSource*)defaultDataSource {
    GraphDataSource *dataSource = [self new];
    return dataSource;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    return self;
}

#pragma mark - Override in subclasses

- (void)startLoading {
    self.serverProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    [self requestData];
}

- (void)requestData {
    
}

- (NSDictionary*)valuesFromLoadedData:(id)data {
    return nil;
}

- (NSDictionary*)topValuesFromLoadedData:(id)data {
    return nil;
}

- (NSDictionary*)iconImageIndexesFromLoadedData:(id)data {
    return nil;
}

#pragma mark - Helper methods

- (NSDictionary*)valuesFromArray:(NSArray*)array key:(NSString*)key {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (id item in array) {
        NSString *day = [item valueForKey:@"day"];
        id value = [item valueForKey:key];
        if (!day.length || !value) continue;
        
        values[day] = value;
    }
    
    return values;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    NSDictionary *values = [self valuesFromLoadedData:data];
    if (values) self.values = values;
    
    NSDictionary *topValues = [self topValuesFromLoadedData:data];
    if (topValues) self.topValues = topValues;
    
    NSDictionary *iconImageIndexes = [self iconImageIndexesFromLoadedData:data];
    if (iconImageIndexes) self.iconImageIndexes = iconImageIndexes;
    
    self.serverProxy = nil;
    
    [[GraphsManager sharedGraphsManager] serverResponseReceived:data serverProxy:serverProxy userInfo:userInfo];
}

- (void)serverErrorReceived:(NSError*)error serverProxy:(id)serverProxy operation:(AFHTTPRequestOperation *)operation userInfo:(id)userInfo {
    self.error = error;
    self.serverProxy = nil;
    
    [[GraphsManager sharedGraphsManager] serverErrorReceived:error serverProxy:serverProxy operation:operation userInfo:userInfo];
}

- (void)loggedOut {
    [[GraphsManager sharedGraphsManager] loggedOut];
}

@end
