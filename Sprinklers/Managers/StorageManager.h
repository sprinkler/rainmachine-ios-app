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
@property (nonatomic, retain, readwrite) Sprinkler *currentSprinkler; // TODO: make this property persistent

- (void)addSprinkler:(NSString *)name ipAddress:(NSString *)ip port:(NSString *)port;
- (void)deleteSprinkler:(NSString *)name;
- (Sprinkler *)getSprinkler:(NSString *)name;
- (NSArray *)getSprinklers;

- (void)saveData;

+ (StorageManager*)current;

@end
