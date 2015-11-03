//
//  Provision.h
//  Sprinklers
//
//  Created by Istvan Sipos on 21/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProvisionSystem;
@class ProvisionLocation;

@interface Provision : NSObject

@property (nonatomic, strong) ProvisionSystem *system;
@property (nonatomic, strong) ProvisionLocation *location;

+ (Provision*)createFromJson:(NSDictionary*)jsonObj;

@end
