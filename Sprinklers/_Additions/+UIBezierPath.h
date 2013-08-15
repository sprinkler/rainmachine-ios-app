//
//  UIBezierPath.h
//  FootballSupporter
//
//  Created by Daniel Cristolovean on 12/2/12.
//  Copyright (c) 2012 Foca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Additions)

+ (UIBezierPath *)dqd_bezierPathWithArrowFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint tailWidth:(CGFloat)tailWidth headWidth:(CGFloat)headWidth headLength:(CGFloat)headLength;

@end
