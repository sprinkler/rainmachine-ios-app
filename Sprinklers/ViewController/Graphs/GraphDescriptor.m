//
//  GraphDescriptor.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphDescriptor.h"
#import "GraphTimeInterval.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphTitleAreaDescriptor.h"
#import "GraphIconsBarDescriptor.h"
#import "GraphValuesBarDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"
#import "GraphDateBarDescriptor.h"
#import "GraphDataSource.h"
#import "GraphsManager.h"

#pragma mark -

@implementation GraphDescriptor {
    GraphTimeInterval *_graphTimeInterval;
}

+ (GraphDescriptor*)defaultDescriptor {
    GraphDescriptor *descriptor = [GraphDescriptor new];
    
    descriptor.dataSource = [GraphDataSource defaultDataSource];
    descriptor.visualAppearanceDescriptor = [GraphVisualAppearanceDescriptor defaultDescriptor];
    descriptor.titleAreaDescriptor = [GraphTitleAreaDescriptor defaultDescriptor];
    descriptor.displayAreaDescriptor = [GraphDisplayAreaDescriptor defaultDescriptor];
    descriptor.dateBarDescriptor = [GraphDateBarDescriptor defaultDescriptor];
    descriptor.graphTimeInterval = [GraphTimeInterval graphTimeIntervalWithType:GraphTimeIntervalType_Weekly];
    
    return descriptor;
}

- (CGFloat)totalGraphHeight {
    return self.titleAreaDescriptor.titleAreaHeight +
        self.iconsBarDescriptor.iconsBarHeight +
        self.valuesBarDescriptor.valuesBarHeight +
        self.displayAreaDescriptor.displayAreaHeight +
        self.dateBarDescriptor.dateBarHeight + 6.0;
}

- (GraphTimeInterval*)graphTimeInterval {
    return _graphTimeInterval;
}

- (void)setGraphTimeInterval:(GraphTimeInterval*)graphTimeInterval {
    _graphTimeInterval = graphTimeInterval;
    
    NSInteger currentDateValueIndex = -1;
    
    self.dateBarDescriptor.timeIntervalValue = graphTimeInterval.timeIntervalValue;
    self.dateBarDescriptor.dateValues = [graphTimeInterval dateValuesForCount:graphTimeInterval.maxValuesCount currentDateValueIndex:&currentDateValueIndex];
    self.dateBarDescriptor.selectedDateValueIndex = currentDateValueIndex;
}

@end
