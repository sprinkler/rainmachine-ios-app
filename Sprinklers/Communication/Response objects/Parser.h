//
//  Parser.h
//  Sprinklers
//
//  Created by Istvan Sipos on 27/02/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ParserParameterTypeUnknown,
    ParserParameterTypeNull,
    ParserParameterTypeBoolean,
    ParserParameterTypeNumber,
    ParserParameterTypeString
} ParserParameterType;

@interface ParserParameter : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id value;
@property (nonatomic, assign) ParserParameterType parameterType;

@end

@interface Parser : NSObject

@property (nonatomic, assign) int uid;
@property (nonatomic, strong) NSString *lastRun;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *params;
@property (nonatomic, assign) BOOL enabled;

+ (Parser*)createFromJson:(NSDictionary*)jsonObj;

@end
