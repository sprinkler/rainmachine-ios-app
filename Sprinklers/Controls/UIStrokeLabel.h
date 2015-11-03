//
//  UIStrokeLabel.h
//  BounceThatApp
//
//  Created by Daniel Cristolovean on 4/3/12.
//  Copyright (c) 2012 VLF Networks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIStrokeLabel : UILabel {
    
    float strokeWidth;
    UIColor *strokeColor;
}

@property (nonatomic) float strokeWidth;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic) BOOL drawOutline;
@property (nonatomic) BOOL drawGradient;

@end
