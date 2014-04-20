//
//  RestrictionsData.h
//  Sprinklers
//
//  Created by Adrian Manolache on 16/01/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RestrictionsData : NSObject
        
@property (nonatomic, strong) NSNumber *hotDays;
@property (nonatomic, strong) NSNumber *freezeProtect;
@property (nonatomic, strong) NSString *months;

@end
