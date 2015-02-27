//
//  Parser.m
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "Parser.h"
#import "Additions.h"

#pragma mark -

@interface ParserParameter ()

+ (ParserParameterType)parserParameterTypeForValue:(id)value;

@end

#pragma mark -

@implementation ParserParameter

+ (ParserParameterType)parserParameterTypeForValue:(id)value {
    if (!value) return ParserParameterTypeNull;
    if ([value isKindOfClass:[NSNull class]]) return ParserParameterTypeNull;
    if ([value isKindOfClass:[NSString class]]) return ParserParameterTypeString;
    if ([value isKindOfClass:[NSNumber class]]) {
        if ((__bridge CFBooleanRef)value == kCFBooleanTrue) return ParserParameterTypeBoolean;
        if ((__bridge CFBooleanRef)value == kCFBooleanFalse) return ParserParameterTypeBoolean;
        return ParserParameterTypeNumber;
    }
    return ParserParameterTypeUnknown;
}

@end

#pragma mark -

@implementation Parser

+ (Parser*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        Parser *parser = [Parser new];
        
        parser.uid = [jsonObj nullProofedIntValueForKey:@"uid"];
        parser.lastRun = [jsonObj nullProofedStringValueForKey:@"lastRun"];
        parser.name = [jsonObj nullProofedStringValueForKey:@"name"];
        parser.enabled = [jsonObj nullProofedBoolValueForKey:@"enabled"];
        
        NSDictionary *paramsDictionary = [jsonObj valueForKey:@"params"];
        if (![paramsDictionary isKindOfClass:[NSDictionary class]]) parser.params = nil;
        else {
            NSMutableArray *params = [NSMutableArray new];
            for (NSString *key in paramsDictionary.allKeys) {
                ParserParameter *parameter = [ParserParameter new];
                parameter.name = key;
                parameter.value = paramsDictionary[key];
                parameter.parameterType = [ParserParameter parserParameterTypeForValue:parameter.value];
                
                [params addObject:parameter];
            }
            parser.params = params;
        }
        
        return parser;
    }
    return nil;
}

@end
