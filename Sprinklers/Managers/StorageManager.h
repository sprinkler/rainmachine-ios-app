//
//  StorageManager.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sprinkler.h"

@class DBZone;
@class WaterNowZone;

typedef enum {
    NetworkType_Local,
    NetworkType_Remote,
    NetworkType_All,
} NetworkType;

@interface StorageManager : NSObject

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readwrite) Sprinkler *currentSprinkler; // TODO: keep the name of the current sprinkler persistent in the db

- (Sprinkler*)addSprinkler:(NSString *)name ipAddress:(NSString *)ip port:(NSString *)port isLocal:(NSNumber*)isLocal email:(NSString*)email mac:(NSString*)mac save:(BOOL)save;
- (BOOL)deleteSprinklerWithName:(NSString *)name;
- (BOOL)deleteSprinkler:(Sprinkler *)sprinkler;
- (void)deleteLocalSprinklers;
- (void)increaseFailedCountersForDevicesOnNetwork:(NetworkType)networkType onlySprinklersWithEmail:(BOOL)onlySprinklersWithEmail;
- (Sprinkler *)getSprinklerBasedOnMAC:(NSString *)sprinklerMAC local:(NSNumber*)local;
- (Sprinkler *)getSprinkler:(NSString *)name address:(NSString*)address port:(NSString*)port local:(NSNumber*)local email:(NSString*)email;
- (Sprinkler *)getSprinkler:(NSString *)name local:(NSNumber*)local;
- (NSArray *)getSprinklersFromNetwork:(NetworkType)networkType aliveDevices:(NSNumber*)onlyDiscoveredDevices;
- (NSArray *)getAllSprinklersFromNetwork;
- (DBZone*)zoneWithId:(NSNumber*)theId;
- (void)setZoneCounter:(WaterNowZone*)zone;

- (void)applyMigrationFix;

- (void)saveData;
- (NSString*) persistentStoreLocation;

+ (StorageManager*)current;

@end
