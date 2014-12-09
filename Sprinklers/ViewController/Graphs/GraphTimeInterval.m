//
//  GraphTimeInterval.m
//  Sprinklers
//
//  Created by Istvan Sipos on 09/12/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "GraphTimeInterval.h"

#pragma mark -

@interface GraphTimeInterval ()

@property (nonatomic, assign) GraphTimeIntervalType type;
@property (nonatomic, strong) NSString *name;

+ (void)registerGraphTimeIntervalWithType:(GraphTimeIntervalType)type name:(NSString*)name;

@end

#pragma mark -

@implementation GraphTimeInterval

static NSMutableDictionary *registeredTimeIntervalsDictionary = nil;
static NSMutableArray *registeredTimeIntervals = nil;

+ (void)registerGraphTimeIntervalWithType:(GraphTimeIntervalType)type name:(NSString*)name {
    if (!registeredTimeIntervalsDictionary) registeredTimeIntervalsDictionary = [NSMutableDictionary new];
    if (!registeredTimeIntervals) registeredTimeIntervals = [NSMutableArray new];
    
    if ([registeredTimeIntervalsDictionary objectForKey:@(type)]) return;
    
    GraphTimeInterval *graphTimeInterval = [GraphTimeInterval new];
    graphTimeInterval.type = type;
    graphTimeInterval.name = name;
    
    [registeredTimeIntervalsDictionary setObject:graphTimeInterval forKey:@(type)];
    [registeredTimeIntervals addObject:graphTimeInterval];
}

+ (void)initialize {
    [self registerGraphTimeIntervalWithType:GraphTimeIntervalType_Weekly name:@"Week"];
    [self registerGraphTimeIntervalWithType:GraphTimeIntervalType_Monthly name:@"Month"];
    [self registerGraphTimeIntervalWithType:GraphTimeIntervalType_Yearly name:@"Year"];
}

+ (GraphTimeInterval*)graphTimeIntervalWithType:(GraphTimeIntervalType)type {
    return [registeredTimeIntervalsDictionary objectForKey:@(type)];
}

+ (NSArray*)graphTimeIntervals {
    return registeredTimeIntervals;
}

@end
