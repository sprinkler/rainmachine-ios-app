//
//  +UIButton.h
//  RedRover
//

#import <UIKit/UIKit.h>

@interface UIButton (Additions)

- (void)setupAsRoundColouredButton:(UIColor*)color;
- (void)setupWithImage:(UIImage*)img;
- (void)setCustomRMFontWithCode:(unsigned short)code size:(int)size;

@end
