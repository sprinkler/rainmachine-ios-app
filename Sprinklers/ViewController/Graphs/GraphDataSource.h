//
//  GraphDataSource.h
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerProxy.h"

@interface GraphDataSource : NSObject <SprinklerResponseProtocol>

@property (nonatomic, strong) NSDictionary *values;
@property (nonatomic, strong) NSDictionary *topValues;
@property (nonatomic, strong) NSDictionary *iconImageIndexes;
@property (nonatomic, strong) ServerProxy *serverProxy;
@property (nonatomic, strong) NSError *error;

+ (GraphDataSource*)defaultDataSource;
- (void)startLoading;

- (NSDictionary*)valuesFromArray:(NSArray*)array key:(NSString*)key;

- (void)requestData;
- (NSDictionary*)valuesFromLoadedData:(id)data;
- (NSDictionary*)topValuesFromLoadedData:(id)data;
- (NSDictionary*)iconImageIndexesFromLoadedData:(id)data;

@end
