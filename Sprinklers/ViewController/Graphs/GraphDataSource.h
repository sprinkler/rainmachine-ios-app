//
//  GraphDataSource.h
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphDataFormatter;

@interface GraphDataSource : NSObject

@property (nonatomic, strong) NSDictionary *values;
@property (nonatomic, strong) NSDictionary *topValues;
@property (nonatomic, strong) NSDictionary *iconImageIndexes;

@property (nonatomic, assign) double minValue;
@property (nonatomic, assign) double midValue;
@property (nonatomic, assign) double maxValue;

+ (GraphDataSource*)defaultDataSource;
- (void)reloadGraphDataSource;

- (NSDictionary*)valuesFromArray:(NSArray*)array key:(NSString*)key;
- (NSDictionary*)valuesFromLoadedData;
- (NSDictionary*)topValuesFromLoadedData;
- (NSDictionary*)iconImageIndexesFromLoadedData;
- (NSArray*)valuesForGraphDataFormatter;

@property (nonatomic, readonly) Class graphDataFormatterClass;
@property (nonatomic, readonly) BOOL shouldRoundMidValue;

@end
