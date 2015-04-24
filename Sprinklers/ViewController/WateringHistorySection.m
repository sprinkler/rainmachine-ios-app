//
//  WateringHistorySection.m
//  Sprinklers
//
//  Created by Istvan Sipos on 24/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "WateringHistorySection.h"
#import "WaterLogDay.h"
#import "WaterLogProgram.h"

@implementation WateringHistorySection

+ (WateringHistorySection*)sectionWithType:(WateringHistorySectionType)sectionType
                               waterLogDay:(WaterLogDay*)waterLogDay
                           waterLogProgram:(WaterLogProgram*)waterLogProgram {

    return [[self alloc] initWithType:sectionType waterLogDay:waterLogDay waterLogProgram:waterLogProgram];
}

- (id)initWithType:(WateringHistorySectionType)sectionType
       waterLogDay:(WaterLogDay*)waterLogDay
   waterLogProgram:(WaterLogProgram*)waterLogProgram {

    self = [super init];
    if (!self) return nil;
    
    _sectionType = sectionType;
    _waterLogDay = waterLogDay;
    _waterLogProgram = waterLogProgram;
    
    return self;
}

- (NSInteger)numberOfRows {
    if (self.sectionType == WateringHistorySectionTypeHeader) return 1;
    if (self.sectionType == WateringHistorySectionTypeWaterLogDayHeader) return 1;
    if (self.sectionType == WateringHistorySectionTypeWaterLogProgram) {
        if (!self.waterLogProgram) return 1;
        return self.waterLogProgram.zones.count + 1;
    }
    return 0;
}

@end
