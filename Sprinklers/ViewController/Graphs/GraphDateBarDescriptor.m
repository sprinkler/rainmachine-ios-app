//
//  GraphDateBarDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDateBarDescriptor.h"
#import "GraphTimeInterval.h"

@implementation GraphDateBarDescriptor

+ (GraphDateBarDescriptor*)defaultDescriptor {
    GraphDateBarDescriptor *descriptor = [GraphDateBarDescriptor new];
    
    descriptor.dateBarHeight = 24.0;
    descriptor.weekdaysBarHeight = 16.0;
    descriptor.dateBarBottomPadding = 3.0;
    descriptor.timeIntervalFont = [UIFont systemFontOfSize:12.0];
    descriptor.timeIntervalColor = [UIColor whiteColor];
    descriptor.dateValuesFont = [UIFont systemFontOfSize:12.0];
    descriptor.dateValuesColor = [UIColor whiteColor];
    descriptor.dateValueSelectionColor = [UIColor whiteColor];
    
    return descriptor;
}

- (CGFloat)totalBarHeightForGraphTimeInterval:(GraphTimeInterval*)graphTimeInterval {
    if (![self hasWeekdaysBarForGraphTimeInterval:graphTimeInterval]) return self.dateBarHeight;
    return self.dateBarHeight + self.weekdaysBarHeight;
}

- (BOOL)hasWeekdaysBarForGraphTimeInterval:(GraphTimeInterval*)graphTimeInterval {
    return [self.hasWeekdaysBar containsObject:@(graphTimeInterval.type)];
}

@end
