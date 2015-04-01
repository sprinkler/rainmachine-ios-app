//
//  GraphStyleBars.m
//  Sprinklers
//
//  Created by Istvan Sipos on 10/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphStyleBars.h"
#import "GraphDescriptor.h"
#import "GraphTimeInterval.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"

@implementation GraphStyleBars

- (void)plotGraphInRect:(CGRect)rect context:(CGContextRef)context {
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, self.graphDescriptor.displayAreaDescriptor.graphDisplayColor.CGColor);
    
    CGFloat barSizeWidth = (self.graphDescriptor.graphTimeInterval ? [self.graphDescriptor.displayAreaDescriptor.graphBarsWidthDictionary[@(self.graphDescriptor.graphTimeInterval.type)] doubleValue] : 0.0);
    CGFloat graphBarsTopPadding = self.graphDescriptor.displayAreaDescriptor.graphBarsTopPadding + self.graphDescriptor.displayAreaDescriptor.valuesDisplayHeight;
    CGFloat graphBarsBottomPadding = self.graphDescriptor.displayAreaDescriptor.graphBarsBottomPadding - 1.0;
    CGFloat displayHeight = rect.size.height - graphBarsTopPadding - graphBarsBottomPadding;
    CGFloat displayWidth = rect.size.width - self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding - self.graphDescriptor.visualAppearanceDescriptor.graphContentTrailingPadding;
    
    CGFloat barDisplayWidth = displayWidth / self.values.count;
    CGFloat barOriginX = self.graphDescriptor.visualAppearanceDescriptor.graphContentLeadingPadding + (barDisplayWidth - barSizeWidth) / 2.0;
    
    NSMutableArray *coordinatesX = [NSMutableArray new];
    
    for (id value in self.values) {
        [coordinatesX addObject:@(barOriginX)];
        
        if (value == [NSNull null]) {
            barOriginX += barDisplayWidth;
            continue;
            
        }
        
        NSNumber *numberValue = (NSNumber*)value;
        
        CGFloat absoluteValue = (numberValue.doubleValue - self.graphDescriptor.displayAreaDescriptor.minValue);
        CGFloat valuesIntervalLength = (self.graphDescriptor.displayAreaDescriptor.maxValue - self.graphDescriptor.displayAreaDescriptor.minValue);
        if (valuesIntervalLength == 0.0) valuesIntervalLength = 1.0;
        
        CGFloat barSizeHeight = absoluteValue / valuesIntervalLength * displayHeight;
        CGRect barRect = CGRectIntegral(CGRectMake(barOriginX, rect.size.height - barSizeHeight - graphBarsBottomPadding, barSizeWidth, barSizeHeight));
        CGContextFillRect(context, barRect);
        
        barOriginX += barDisplayWidth;
    }
    
    self.coordinatesX = coordinatesX;
    
    CGContextRestoreGState(context);
}

@end
