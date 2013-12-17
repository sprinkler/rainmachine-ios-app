//
//  UIImageView.h
//  MeinRezept
//
//  Created by Daniel Cristolovean on 6/20/13.
//
//

#import <Foundation/Foundation.h>

@interface UIImageView (Additions)

- (CGPoint)convertPointFromImage:(CGPoint)imagePoint;
- (CGRect)convertRectFromImage:(CGRect)imageRect;

- (CGPoint)convertPointFromView:(CGPoint)viewPoint;
- (CGRect)convertRectFromView:(CGRect)viewRect;

@end
