//
//  +NSDictionary.h
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Additions)

+ (NSDictionary *)dictionaryWithContentsOfData:(NSData *)data;

- (NSString *)nullProofedStringValueForKey: (NSString *)key;
- (int)nullProofedIntValueForKey: (NSString *)key;
- (double)nullProofedDoubleValueForKey: (NSString *)key;
- (BOOL)nullProofedBoolValueForKey: (NSString *)key;

@end
