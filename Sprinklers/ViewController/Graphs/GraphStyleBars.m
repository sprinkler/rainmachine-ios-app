//
//  GraphStyleBars.m
//  Sprinklers
//
//  Created by Istvan Sipos on 10/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphStyleBars.h"
#import "GraphVisualAppearanceDescriptor.h"
#import "GraphDisplayAreaDescriptor.h"

@implementation GraphStyleBars

- (void)plotGraphInRect:(CGRect)rect context:(CGContextRef)context {
    NSInteger maxValue = 0;
    for (NSNumber *value in self.values) {
        if (value.integerValue > maxValue) maxValue = value.integerValue;
    }
    
    CGContextSetFillColorWithColor(context, self.displayAreaDescriptor.graphDisplayColor.CGColor);
    
    CGFloat barSizeWidth = self.displayAreaDescriptor.graphBarsWidth;
    CGFloat graphBarsTopPadding = self.displayAreaDescriptor.graphBarsTopPadding + self.displayAreaDescriptor.valuesDisplayHeight;
    CGFloat graphBarsBottomPadding = self.displayAreaDescriptor.graphBarsBottomPadding - 1.0;
    CGFloat displayHeight = rect.size.height - graphBarsTopPadding - graphBarsBottomPadding;
    CGFloat displayWidth = rect.size.width - self.visualDescriptor.graphContentLeadingPadding - self.visualDescriptor.graphContentTrailingPadding;
    
    CGFloat barDisplayWidth = displayWidth / self.values.count;
    CGFloat barOriginX = self.visualDescriptor.graphContentLeadingPadding + (barDisplayWidth - barSizeWidth) / 2.0;
    
    for (NSNumber *value in self.values) {
        CGFloat barSizeHeight = value.doubleValue / (double)maxValue * displayHeight;
        CGRect barRect = CGRectIntegral(CGRectMake(barOriginX, rect.size.height - barSizeHeight - graphBarsBottomPadding, barSizeWidth, barSizeHeight));
        CGContextFillRect(context, barRect);
        
        barOriginX += barDisplayWidth;
    }
}

@end
