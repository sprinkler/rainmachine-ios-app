//
//  Sprinkler.h
//  Sprinklers
//
//  Created by Fabian Matyas on 17/01/15.
//  Copyright (c) 2015 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DBZone;

@interface Sprinkler : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * isDiscovered;
@property (nonatomic, retain) NSNumber * isLocalDevice;
@property (nonatomic, retain) NSString * lastError;
@property (nonatomic, retain) NSDate * lastSprinklerVersionRequest;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSNumber * loginRememberMe;
@property (nonatomic, retain) NSString * mac;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nrOfFailedConsecutiveDiscoveries;
@property (nonatomic, retain) NSString * port;
@property (nonatomic, retain) NSString * sprinklerId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * apFlag;
@property (nonatomic, retain) NSSet *zones;
@end

@interface Sprinkler (CoreDataGeneratedAccessors)

- (void)addZonesObject:(DBZone *)value;
- (void)removeZonesObject:(DBZone *)value;
- (void)addZones:(NSSet *)values;
- (void)removeZones:(NSSet *)values;

@end
