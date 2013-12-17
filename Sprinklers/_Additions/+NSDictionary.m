//
//  +NSDictionary.m
//

#import "+NSDictionary.h"

@implementation NSDictionary (Additions)

+ (NSDictionary *)dictionaryWithContentsOfData:(NSData *)data {
	
	CFPropertyListRef plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)data, kCFPropertyListImmutable, NULL);
	
	if ([(__bridge id)plist isKindOfClass:[NSDictionary class]]) {
		return (__bridge NSDictionary*)plist;
	} else {
		return nil;
	}

}

- (NSString *) nullProofedStringValueForKey: (NSString *)key {
    if (![self objectForKey:key])
        return @"";
    else
        return [[self objectForKey:key] isEqual:[NSNull null]] ? @"" : [self objectForKey:key];
}

- (int)nullProofedIntValueForKey: (NSString *)key {
    if (![self objectForKey:key])
        return 0;
    else
        return [[self objectForKey:key] isEqual:[NSNull null]] ? 0 : [[self objectForKey:key] intValue];
}

- (BOOL)nullProofedBoolValueForKey: (NSString *)key {
    if (![self objectForKey:key])
        return NO;
    else
        return [[self objectForKey:key] isEqual:[NSNull null]] ? NO : [[self objectForKey:key] boolValue];
}

@end
