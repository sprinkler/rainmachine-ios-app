//
// +UIDevice.h
//

#import <Foundation/Foundation.h>

@interface UIDevice (Additions)

- (NSString *)uniqueDeviceIdentifier;

- (BOOL)isIPhone5;

- (BOOL)iOSGreaterThan:(float)version;

@end