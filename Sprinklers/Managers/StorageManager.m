//
//  StorageManager.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "StorageManager.h"

static StorageManager *current = nil;

@implementation StorageManager

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

#pragma mark - Singleton

+ (id)current {
	@synchronized(self) {
		if (current == nil)
			current = [[super allocWithZone:NULL] init];
	}
	return current;
}

#pragma mark - Methods

- (void)addSprinkler:(NSString *)name ipAddress:(NSString *)ip port:(NSString *)port {
    Sprinkler *sprinkler = [NSEntityDescription insertNewObjectForEntityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    sprinkler.name = name;
    sprinkler.address = ip;
    sprinkler.port = port;
    [self saveData];
}

- (void)deleteSprinkler:(NSString *)name {
    Sprinkler *sprinkler = [self getSprinkler:name];
    if (sprinkler) {
        [self.managedObjectContext deleteObject:sprinkler];
        [self saveData];
    }
}

- (Sprinkler *)getSprinkler:(NSString *)name {
    NSError *error;
    NSArray *items;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    [fetchRequest setPredicate:predicate];
    
    items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (items && items.count == 1) {
        return items[0];
    }
    return nil;
}

- (NSArray *)getSprinklers {
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

#pragma mark - Core Data Stack

- (void)saveData {
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Save error: %@", [error localizedDescription]);
    }
}

- (NSString *)stringApplicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

- (void)reloadManagedObjectContext {
    
    __managedObjectContext = nil;
    __persistentStoreCoordinator = nil;
    __managedObjectModel = nil;
    
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Sprinklers" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    NSString *storePath = [[self stringApplicationDocumentsDirectory] stringByAppendingPathComponent:@"sprinklers.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return __persistentStoreCoordinator;
}

@end
