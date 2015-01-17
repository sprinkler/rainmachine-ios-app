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

- (void)reloadGraphDataSource {
    NSDictionary *values = [self valuesFromLoadedData];
    if (values) self.values = values;
    
    NSDictionary *topValues = [self topValuesFromLoadedData];
    if (topValues) self.topValues = topValues;
    
    NSDictionary *iconImageIndexes = [self iconImageIndexesFromLoadedData];
    if (iconImageIndexes) self.iconImageIndexes = iconImageIndexes;
}

#pragma mark - Override in subclasses

- (NSDictionary*)valuesFromLoadedData {
    return nil;
}

- (NSDictionary*)topValuesFromLoadedData {
    return nil;
}

- (NSDictionary*)iconImageIndexesFromLoadedData {
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

@end
