//
//  WateringHistorySection.h
//  Sprinklers
//
//  Created by Istvan Sipos on 24/04/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WaterLogDay;
@class WaterLogProgram;

typedef enum {
    WateringHistorySectionTypeHeader,
    WateringHistorySectionTypeWaterLogDayHeader,
    WateringHistorySectionTypeWaterLogProgram
} WateringHistorySectionType;

@interface WateringHistorySection : NSObject

@property (nonatomic, assign) WateringHistorySectionType sectionType;
@property (nonatomic, strong) WaterLogDay *waterLogDay;
@property (nonatomic, strong) WaterLogProgram *waterLogProgram;

+ (WateringHistorySection*)sectionWithType:(WateringHistorySectionType)sectionType
                               waterLogDay:(WaterLogDay*)waterLogDay
                           waterLogProgram:(WaterLogProgram*)waterLogProgram;

- (id)initWithType:(WateringHistorySectionType)sectionType
       waterLogDay:(WaterLogDay*)waterLogDay
   waterLogProgram:(WaterLogProgram*)waterLogProgram;

@property (nonatomic, readonly) NSInteger numberOfRows;

@end
