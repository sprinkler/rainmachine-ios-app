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
    descriptor.canDisable = YES;
    descriptor.isDisabled = NO;
    
    return descriptor;
}

- (id)copyWithZone:(NSZone*)zone {
    GraphDescriptor *descriptor = [GraphDescriptor new];
    
    descriptor.graphIdentifier = self.graphIdentifier;
    descriptor.dataSource = self.dataSource;
    descriptor.graphTimeInterval = self.graphTimeInterval;
    descriptor.visualAppearanceDescriptor = self.visualAppearanceDescriptor;
    descriptor.titleAreaDescriptor = self.titleAreaDescriptor;
    descriptor.iconsBarDescriptorsDictionary = self.iconsBarDescriptorsDictionary;
    descriptor.valuesBarDescriptorsDictionary = self.valuesBarDescriptorsDictionary;
    descriptor.displayAreaDescriptor = self.displayAreaDescriptor;
    descriptor.dateBarDescriptor = self.dateBarDescriptor;
    descriptor.canDisable = self.canDisable;
    descriptor.isDisabled = self.isDisabled;

    return descriptor;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[GraphDescriptor class]]) return NO;
    return [self.graphIdentifier isEqualToString:((GraphDescriptor*)object).graphIdentifier];
}

- (CGFloat)totalGraphHeight {
    GraphIconsBarDescriptor *iconsBarDescriptor = (self.graphTimeInterval ? self.iconsBarDescriptorsDictionary[@(self.graphTimeInterval.type)] : nil);
    GraphValuesBarDescriptor *valuesBarDescriptor = (self.graphTimeInterval ? self.valuesBarDescriptorsDictionary[@(self.graphTimeInterval.type)] : nil);
    
    return self.titleAreaDescriptor.titleAreaHeight +
        iconsBarDescriptor.iconsBarHeight +
        valuesBarDescriptor.valuesBarHeight +
        self.displayAreaDescriptor.displayAreaHeight +
        self.dateBarDescriptor.dateBarHeight + 6.0;
}

- (void)setIsDisabled:(BOOL)isDisabled {
    _isDisabled = isDisabled;
    if (isDisabled) {
        self.visualAppearanceDescriptor.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        self.titleAreaDescriptor.titleAreaSeparatorColor = [UIColor colorWithWhite:221.0 / 255.0 alpha:1.0];
        self.displayAreaDescriptor.dashedLinesColor = [UIColor colorWithWhite:236.0 / 255.0 alpha:1.0];
    } else {
        self.visualAppearanceDescriptor.backgroundColor = [UIColor colorWithRed:kSprinklerBlueColor[0] green:kSprinklerBlueColor[1] blue:kSprinklerBlueColor[2] alpha:1];
        self.titleAreaDescriptor.titleAreaSeparatorColor = [UIColor colorWithRed:156.0 / 255.0 green:205.0 / 255.0 blue:230.0 / 255.0 alpha:1.0];
        self.displayAreaDescriptor.dashedLinesColor = [UIColor colorWithRed:206.0 / 255.0 green:225.0 / 255.0 blue:235.0 / 255.0 alpha:1.0];
    }
}

@end
