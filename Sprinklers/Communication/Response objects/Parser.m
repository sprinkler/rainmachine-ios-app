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
- (BOOL)isEqualToParserParameter:(ParserParameter*)parserParameter;

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

- (id)copyWithZone:(NSZone*)copyZone {
    ParserParameter *parserParameter = [(ParserParameter*)[[self class] allocWithZone:copyZone] init];
    
    parserParameter.name = self.name;
    parserParameter.value = self.value;
    parserParameter.parameterType = self.parameterType;
    
    return parserParameter;
}

- (BOOL)isEqualToParserParameter:(ParserParameter*)parserParameter {
    if (self.parameterType != parserParameter.parameterType) return NO;
    if (![self.name isEqual:parserParameter.name]) return NO;
    if (![self.value isEqual:parserParameter.value]) return NO;
    return YES;
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
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            [params sortUsingDescriptors:@[sortDescriptor]];
            
            parser.params = params;
        }
        
        return parser;
    }
    return nil;
}

- (id)copyWithZone:(NSZone*)copyZone {
    Parser *parser = [(Parser*)[[self class] allocWithZone:copyZone] init];
    
    parser.uid = self.uid;
    parser.lastRun = self.lastRun;
    parser.name = self.name;
    parser.enabled = self.enabled;
    
    NSMutableArray *paramsCopy = [NSMutableArray new];
    for (ParserParameter *parserParameter in self.params) {
        [paramsCopy addObject:[parserParameter copy]];
    }
    parser.params = paramsCopy;
    
    return parser;
}

- (BOOL)isEqualToParser:(Parser*)parser {
    if (parser.uid != self.uid) return NO;
    if (![parser.lastRun isEqual:self.lastRun]) return NO;
    if (![parser.name isEqual:self.name]) return NO;
    if (parser.enabled != self.enabled) return NO;
    if (parser.params.count != self.params.count) return NO;
    
    for (int index = 0; index < parser.params.count; index++) {
        ParserParameter *parserParameter = parser.params[index];
        ParserParameter *parameter = self.params[index];
        if (![parserParameter isEqualToParserParameter:parameter]) return NO;
    }
    
    return YES;
}

- (NSDictionary*)paramsDictionary {
    NSMutableDictionary *paramsDictionary = [NSMutableDictionary new];
    
    for (ParserParameter *parameter in self.params) {
        [paramsDictionary setValue:parameter.value forKey:parameter.name];
    }
    
    return paramsDictionary;
}

@end
