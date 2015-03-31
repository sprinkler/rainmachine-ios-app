//
//  GraphDataSourceRainAmount.m
//  Sprinklers
//
//  Created by Istvan Sipos on 31/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "GraphDataSourceRainAmount.h"
#import "GraphDataFormatterRainAmount.h"
#import "GraphsManager.h"
#import "ServerProxy.h"
#import "MixerDailyValue.h"
#import "Additions.h"
#import "Utils.h"

#pragma mark -

@interface GraphDataSourceRainAmount ()

- (NSDictionary*)qpfValuesFromMixerDailyValues:(NSArray*)mixerDailyValues;

@end

#pragma mark -

@implementation GraphDataSourceRainAmount

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    [[GraphsManager sharedGraphsManager] addObserver:self forKeyPath:@"mixerData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    return self;
}

- (void)dealloc {
    [[GraphsManager sharedGraphsManager] removeObserver:self forKeyPath:@"mixerData"];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    [self reloadGraphDataSource];
}

- (Class)graphDataFormatterClass {
    return [GraphDataFormatterRainAmount class];
}

#pragma mark - Data

- (NSDictionary*)valuesFromLoadedData {
    id data = [GraphsManager sharedGraphsManager].mixerData;
    if (![data isKindOfClass:[NSArray class]]) return nil;
    return [self qpfValuesFromMixerDailyValues:(NSArray*)data];
}

- (NSArray*)valuesForGraphDataFormatter {
    NSMutableArray *values = [NSMutableArray new];
    
    NSString *units = [Utils sprinklerLengthUnits];
    BOOL isInch = [units isEqualToString:@"inch"];
    
    for (MixerDailyValue *mixerDailyValue in [GraphsManager sharedGraphsManager].mixerData) {
        [values addObject:@{@"date" : mixerDailyValue.day,
                            @"qpf" : @(isInch ? mixerDailyValue.qpf / 25.4 : mixerDailyValue.qpf)}];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [values sortUsingDescriptors:@[sortDescriptor]];
    
    return values;
}

- (NSDictionary*)qpfValuesFromMixerDailyValues:(NSArray*)mixerDailyValues {
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    NSString *units = [Utils sprinklerLengthUnits];
    BOOL isInch = [units isEqualToString:@"inch"];
    
    for (MixerDailyValue *mixerDailyValue in mixerDailyValues) {
        NSString *day = [[NSDate sharedDateFormatterAPI4] stringFromDate:mixerDailyValue.day];
        if (!day.length) continue;
        
        double qpf = mixerDailyValue.qpf;
        if (isInch) qpf = qpf / 25.4;
        
        values[day] = @(qpf);
    }
    
    return values;
}

@end
