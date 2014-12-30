//
//  GraphDataSourceWaterConsume.m
//  Sprinklers
//
//  Created by Istvan Sipos on 31/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSourceWaterConsume.h"

#pragma mark -

@implementation GraphDataSourceWaterConsume

- (void)requestData {
    [self.serverProxy requestWeatherData];
}

- (NSDictionary*)valuesFromLoadedData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self valuesFromArray:(NSArray*)data key:@"percentage"];
}

- (NSDictionary*)topValuesFromLoadedData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self valuesFromArray:(NSArray*)data key:@"maxt"];
}

- (NSDictionary*)iconImageIndexesFromLoadedData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self valuesFromArray:(NSArray*)data key:@"icon"];
}

@end
