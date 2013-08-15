//
//  +NSString.h
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

+ (BOOL)isEmpty:(NSString *)value;
+ (NSString *)stringWithUUID;

- (NSString *)stringFromMD5;
- (NSString *)capitalizedFirstLetter;
- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string options:(NSStringCompareOptions)options;

// Strips HTML tags & comments, removes extra whitespace and decodes HTML character entities.
- (NSString *)stringByConvertingHTMLToPlainText;

// Decode all HTML entities using GTM.
- (NSString *)stringByDecodingHTMLEntities;

// Encode all HTML entities using GTM.
- (NSString *)stringByEncodingHTMLEntities;

// Minimal unicode encoding will only cover characters from table
// A.2.2 of http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
// which is what you want for a unicode encoded webpage.
- (NSString *)stringByEncodingHTMLEntities:(BOOL)isUnicode;

// Replace newlines with <br /> tags.
- (NSString *)stringWithNewLinesAsBRs;

// Remove newlines and white space from string.
- (NSString *)stringByRemovingNewLinesAndWhitespace;

// Wrap plain URLs in <a href="..." class="linkified">...</a>
// - Ignores URLs inside tags (any URL beginning with =")
// - HTTP & HTTPS schemes only
// - Only works in iOS 4+ as we use NSRegularExpression (returns self if not supported so be careful with NSMutableStrings)
// - Expression: (?<!=")\b((http|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:/~\+#]*[\w\-\@?^=%&amp;/~\+#])?)
// - Adapted from http://regexlib.com/REDetails.aspx?regexp_id=96
- (NSString *)stringByLinkifyingURLs;

@end
