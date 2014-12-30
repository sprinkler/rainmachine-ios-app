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

@interface GraphDataSource ()

@property (nonatomic, readonly) NSInteger maxValuesCount;

- (NSArray*)createIconImages;

@end

#pragma mark -

@implementation GraphDataSource

#pragma mark - Initialization

+ (GraphDataSource*)defaultDataSource {
    GraphDataSource *dataSource = [self new];
    
    dataSource.iconImages = [dataSource createIconImages];
    dataSource.groupingModel = GraphDataSourceGroupingModel_Average;
    
    return dataSource;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    _serverProxy = [[ServerProxy alloc] initWithSprinkler:[Utils currentSprinkler] delegate:self jsonRequest:YES];
    
    return self;
}

#pragma mark - Configuration

- (NSInteger)maxValuesCount {
    return 7;
}

#pragma mark - Override in subclasses

- (void)startLoading {
    [self requestData];
}

- (void)requestData {
    
}

- (NSDictionary*)valuesFromLoadedData:(id)data {
    return nil;
}

#pragma mark - Helper methods

- (NSArray*)createIconImages {
    NSMutableArray *iconImages = [NSMutableArray new];
    
    UIImage *image = [UIImage imageNamed:@"na_small_white"];
    UIImage *iconImage = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
    for (NSInteger index = 0; index < self.maxValuesCount; index++) [iconImages addObject:iconImage];
    
    return iconImages;
}

#pragma mark - ProxyService delegate

- (void)serverResponseReceived:(id)data serverProxy:(id)serverProxy userInfo:(id)userInfo {
    NSDictionary *values = [self valuesFromLoadedData:data];
    if (values) self.values = values;
    
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
