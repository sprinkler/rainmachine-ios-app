//
//  GoogleTimezone.h
//  Sprinklers
//
//  Created by Istvan Sipos on 20/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoogleTimezone : NSObject

@property (nonatomic, strong) NSString *timeZoneId;
@property (nonatomic, strong) NSString *timeZoneName;

+ (instancetype)timezoneWithDictionary:(NSDictionary*)dictionary;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
- (void)setupWithDictionary:(NSDictionary*)dictionary;

@end
