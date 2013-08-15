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

@end
