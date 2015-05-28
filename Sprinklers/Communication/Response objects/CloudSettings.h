//
//  CloudSettings.h
//  Sprinklers
//
//  Created by Istvan Sipos on 13/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CloudSettings : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *pendingEmail;

+ (CloudSettings*)createFromJson:(NSDictionary*)jsonObj;
- (NSDictionary*)toDictionary;

@end
