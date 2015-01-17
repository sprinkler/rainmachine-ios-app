//
//  GraphStyle.h
//  Sprinklers
//
//  Created by Istvan Sipos on 10/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GraphDescriptor;

@interface GraphStyle : NSObject

@property (nonatomic, strong) GraphDescriptor *graphDescriptor;
@property (nonatomic, strong) NSArray *values;

- (void)plotRasterInRect:(CGRect)rect context:(CGContextRef)context;
- (void)plotGraphInRect:(CGRect)rect context:(CGContextRef)context;
- (void)plotInRect:(CGRect)rect context:(CGContextRef)context;

@end
