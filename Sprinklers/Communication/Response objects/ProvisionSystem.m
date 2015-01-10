//
//  ProvisionSystem.m
//  Sprinklers
//
//  Created by Istvan Sipos on 21/11/14.
//  Copyright (c) 2014 Tremend. All rights reserved.
//

#import "ProvisionSystem.h"
#import "Additions.h"

@implementation ProvisionSystem


+ (ProvisionSystem*)createFromJson:(NSDictionary*)jsonObj {
    if (jsonObj) {
        ProvisionSystem *system = [[ProvisionSystem alloc] init];
        
        system.httpEnabled = [jsonObj nullProofedBoolValueForKey:@"httpEnabled"];
        system.useCommandLineArguments = [jsonObj nullProofedBoolValueForKey:@"useCommandLineArguments"];
        system.hardwareVersion = [jsonObj nullProofedIntValueForKey:@"hardwareVersion"];
        system.databasePath = [jsonObj nullProofedStringValueForKey:@"databasePath"];
        system.programListShowInactive = [jsonObj nullProofedBoolValueForKey:@"programListShowInactive"];
        system.programZonesShowInactive = [jsonObj nullProofedBoolValueForKey:@"programZonesShowInactive"];
        system.useMasterValve = [jsonObj nullProofedBoolValueForKey:@"useMasterValve"];
        system.masterValveBefore = [jsonObj nullProofedIntValueForKey:@"masterValveBefore"];
        system.wizardHasRun = [jsonObj nullProofedBoolValueForKey:@"wizardHasRun"];
        system.apiVersion = [jsonObj nullProofedStringValueForKey:@"apiVersion"];
        system.maxWateringCoef = [jsonObj nullProofedDoubleValueForKey:@"maxWateringCoef"];
        system.masterValveAfter = [jsonObj nullProofedIntValueForKey:@"masterValveAfter"];
        system.managedMode = [jsonObj nullProofedBoolValueForKey:@"managedMode"];
        system.zoneListShowInactive = [jsonObj nullProofedBoolValueForKey:@"zoneListShowInactive"];
        system.selfTest = [jsonObj nullProofedBoolValueForKey:@"selfTest"];
        system.netName = [jsonObj nullProofedStringValueForKey:@"netName"];
        system.localValveCount = [jsonObj nullProofedIntValueForKey:@"localValveCount"];
        system.zoneDuration = [jsonObj objectForKey:@"zoneDuration"];
        system.keepDataHistory = [jsonObj nullProofedBoolValueForKey:@"keepDataHistory"];
        
        return system;
    }
    return nil;
}

@end
