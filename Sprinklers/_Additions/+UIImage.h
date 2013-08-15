//
//  +UIImage.h
//  SportsFan
//
//  Created by Daniel Cristolovean on 8/8/12.
//
//

#import <Foundation/Foundation.h>

@interface UIImage (Additions)

- (UIImage *)negativeImage;
- (UIImage *)scaleToSize: (CGSize)size;
- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
- (CGSize) aspectScaledImageSizeForImageView:(UIImageView *)iv image:(UIImage *)im;

@end
