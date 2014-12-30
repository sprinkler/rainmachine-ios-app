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

- (NSDictionary*)createValues;
- (NSArray*)createIconImages;

@end

#pragma mark -

@implementation GraphDataSource

#pragma mark - Initialization

+ (GraphDataSource*)defaultDataSource {
    GraphDataSource *dataSource = [self new];
    
    dataSource.values = [dataSource createValues];
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
    if (![GraphsManager randomizeTestData]) {
        [self requestData];
    }
}

- (void)requestData {
    
}

- (NSDictionary*)valuesFromLoadedData:(id)data {
    return nil;
}

#pragma mark - Helper methods

- (NSDictionary*)createValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    if (![GraphsManager randomizeTestData]) {
        for (NSInteger index = 0; index < self.maxValuesCount; index++) [values setValue:@0 forKey:[NSString stringWithFormat:@"%d",(int)index]];
    } else {
        for (NSInteger index = 0; index < self.maxValuesCount; index++) {
            [values setValue:@((int)((double)rand() / (double)RAND_MAX * 100.0))
                      forKey:[NSString stringWithFormat:@"%d",(int)index]];
        }
    }
    
    return values;
}

- (NSArray*)createIconImages {
    NSMutableArray *iconImages = [NSMutableArray new];
    
    if (![GraphsManager randomizeTestData]) {
        UIImage *image = [UIImage imageNamed:@"na_small_white"];
        UIImage *iconImage = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
        for (NSInteger index = 0; index < self.maxValuesCount; index++) [iconImages addObject:iconImage];
    } else {
        for (NSInteger index = 0; index < self.maxValuesCount; index++) {
            UIImage *image = [Utils smallWhiteWeatherImageFromCode:@((int)((double)rand() / (double)RAND_MAX * 24.0))];
            UIImage *iconImage = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:image.imageOrientation];
            [iconImages addObject:iconImage];
        }
    }
    
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
