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

+ (GraphDataSource*)defaultDataSource;
- (void)reloadGraphDataSource;

- (NSDictionary*)valuesFromArray:(NSArray*)array key:(NSString*)key;
- (NSDictionary*)valuesFromLoadedData;
- (NSDictionary*)topValuesFromLoadedData;
- (NSDictionary*)iconImageIndexesFromLoadedData;

@end
