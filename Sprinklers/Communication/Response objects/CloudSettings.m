//
//  CloudSettings.m
//  Sprinklers
//
//  Created by Istvan Sipos on 13/03/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import "CloudSettings.h"
#import "Additions.h"

@implementation CloudSettings

+ (CloudSettings*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        CloudSettings *cloudSettings = [CloudSettings new];
        
        cloudSettings.enabled = [jsonObj nullProofedBoolValueForKey:@"enabled"];
        cloudSettings.email = [jsonObj nullProofedStringValueForKey:@"email"];
        cloudSettings.pendingEmail = [jsonObj nullProofedStringValueForKey:@"pendingEmail"];
        
        return cloudSettings;
    }
    return nil;
}

- (NSDictionary*)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    [dictionary setValue:@(self.enabled) forKey:@"enabled"];
    [dictionary setValue:self.email forKey:@"email"];
    [dictionary setValue:self.pendingEmail forKey:@"pendingEmail"];
    
    return dictionary;
}

@end
