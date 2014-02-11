//
//  StorageManager.h
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sprinkler.h"

@interface StorageManager : NSObject

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readwrite) Sprinkler *currentSprinkler; // TODO: keep the name of the current sprinkler persistent in the db

- (Sprinkler*)addSprinkler:(NSString *)name ipAddress:(NSString *)ip port:(NSString *)port isLocal:(NSNumber*)isLocal save:(BOOL)save;
- (void)deleteSprinkler:(NSString *)name;
- (void)deleteLocalSprinklers;
- (Sprinkler *)getSprinkler:(NSString *)name address:(NSString*)address port:(NSString*)port local:(NSNumber*)local;
- (Sprinkler *)getSprinkler:(NSString *)name local:(NSNumber*)local;
- (NSArray *)getSprinklersOnLocalNetwork:(NSNumber*)locals;

- (void)saveData;

+ (StorageManager*)current;

@end
