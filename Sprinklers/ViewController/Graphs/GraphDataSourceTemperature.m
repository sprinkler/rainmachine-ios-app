//
//  GraphDataSourceTemperature.m
//  Sprinklers
//
//  Created by Istvan Sipos on 26/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDataSourceTemperature.h"
#import "ServerProxy.h"
#import "WeatherData.h"
#import "WeatherData4.h"

@implementation GraphDataSourceTemperature

- (void)requestData {
    [self.serverProxy requestWeatherData];
}

- (NSDictionary*)valuesFromLoadedData:(id)data {
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self valuesFromArray:(NSArray*)data key:@"maxt"];
}

@end
