//
//  Provision.m
//  Sprinklers
//
//  Created by Istvan Sipos on 21/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "Provision.h"
#import "ProvisionSystem.h"
#import "ProvisionLocation.h"

@implementation Provision

+ (Provision*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        Provision *provision = [[Provision alloc] init];
        
        provision.system = [ProvisionSystem createFromJson:[jsonObj valueForKey:@"system"]];
        provision.location = [ProvisionLocation createFromJson:[jsonObj valueForKey:@"location"]];
        
        return provision;
    }
    return nil;
}

@end
