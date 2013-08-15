//
//  +UIColor.h
//  SportsFan
//
//  Created by Daniel Cristolovean on 8/7/12.
//
//

#import <Foundation/Foundation.h>

@interface UIColor (Additions)

+ (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length;
+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end
