//
//  +UIScreen.m
//  SportsFan
//
//  Created by Daniel Cristolovean on 9/27/12.
//
//

#import "+UIScreen.h"

@implementation UIScreen (Additions)

+ (CGRect)getScreenSize {
    return [[UIScreen mainScreen] bounds];
}

+ (CGFloat)getScreenHeight {
    return [[UIScreen mainScreen] bounds].size.height;
}

+ (CGFloat)getScreenWidth {
    return [[UIScreen mainScreen] bounds].size.width;
}

@end
