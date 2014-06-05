//
//  StorageManager.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/17/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "StorageManager.h"
#import "Utils.h"
#import "Constants.h"
#import "DBZone.h"
#import "WaterNowZone.h"

static StorageManager *current = nil;

@implementation StorageManager

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize currentSprinkler = __currentSprinkler;

#pragma mark - Singleton

+ (StorageManager*)current {
	@synchronized(self) {
		if (current == nil)
			current = [[super allocWithZone:NULL] init];
	}
	return current;
}

#pragma mark - Methods

- (Sprinkler*)addSprinkler:(NSString *)name ipAddress:(NSString *)ip port:(NSString *)port isLocal:(NSNumber*)isLocal save:(BOOL)save {
    Sprinkler *sprinkler = [NSEntityDescription insertNewObjectForEntityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    sprinkler.name = name;
    sprinkler.address = [Utils fixedSprinklerAddress:ip];
    sprinkler.port = port;
    sprinkler.isLocalDevice = isLocal;
    sprinkler.isDiscovered = @YES;

    if (save) {
        [self saveData];
    }
    
    return sprinkler;
}

- (void)deleteLocalSprinklers
{
    NSArray *localSprinklers = [NSMutableArray arrayWithArray:[[StorageManager current] getSprinklersFromNetwork:NetworkType_Local aliveDevices:@NO]];
    for (Sprinkler *sprinkler in localSprinklers) {
        [self.managedObjectContext deleteObject:sprinkler];
    }
}

- (BOOL)deleteSprinklerWithName:(NSString *)name {
    Sprinkler *sprinkler = [self getSprinkler:name local:nil];
    if (sprinkler) {
        [self.managedObjectContext deleteObject:sprinkler];
        [self saveData];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)deleteSprinkler:(Sprinkler *)sprinkler {
    if (sprinkler) {
        [self.managedObjectContext deleteObject:sprinkler];
        [self saveData];
        
        return YES;
    }
    
    return NO;
}

- (Sprinkler *)getSprinkler:(NSString *)name local:(NSNumber*)local {
    NSError *error;
    NSArray *items;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = nil;
    
    if (local) {
        predicate = [NSPredicate predicateWithFormat:@"name == %@ AND isLocalDevice == %@", name, local];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    }
    [fetchRequest setPredicate:predicate];
    
    items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (items && items.count == 1) {
        return items[0];
    }
    return nil;
}

- (Sprinkler *)getSprinkler:(NSString *)name address:(NSString*)address port:(NSString*)port local:(NSNumber*)local {
    NSError *error;
    NSArray *items;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = nil;
    
    if (local) {
        predicate = [NSPredicate predicateWithFormat:@"name == %@ AND address == %@ AND port == %@ AND isLocalDevice == %@", name, address, port, local];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"name == %@ AND address == %@ AND port == %@", name, address, port];
    }
    [fetchRequest setPredicate:predicate];
    
    items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (items && items.count == 1) {
        return items[0];
    }
    return nil;
}

- (NSArray *)getSprinklersFromNetwork:(NetworkType)networkType aliveDevices:(NSNumber*)aliveDevices {
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    NSString *isDiscoveredFilter = [aliveDevices boolValue] ? @"isDiscovered == YES" : @"(isDiscovered == NO OR isDiscovered == nil)";

    if (networkType != NetworkType_All) {
        NSString *isLocalDeviceFilter = (networkType == NetworkType_Local) ? @"isLocalDevice == YES" : @"(isLocalDevice == NO OR isLocalDevice == nil)";
        NSString *predicateFormat = [NSString stringWithFormat:@"%@ AND %@", isLocalDeviceFilter, isDiscoveredFilter];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        [fetchRequest setPredicate:predicate];
    } else {
        NSString *predicateFormat = [NSString stringWithFormat:@"%@", isDiscoveredFilter];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        [fetchRequest setPredicate:predicate];
    }
    
    NSSortDescriptor *sort0 = [[NSSortDescriptor alloc] initWithKey:@"isLocalDevice" ascending:NO];
    NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort0, sort1, nil]];
    
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

- (NSArray *)getAllSprinklersFromNetwork{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sprinkler" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort0 = [[NSSortDescriptor alloc] initWithKey:@"isLocalDevice" ascending:NO];
    NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort0, sort1, nil]];
    
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

- (DBZone*)addZoneWithId:(NSNumber*)theId
{
    DBZone *dbZone = [NSEntityDescription insertNewObjectForEntityForName:@"DBZone" inManagedObjectContext:self.managedObjectContext];
    dbZone.id = theId;
    dbZone.sprinkler = self.currentSprinkler;
    
    return dbZone;
}

- (DBZone*)zoneWithId:(NSNumber*)theId
{
    for (DBZone *zone in self.currentSprinkler.zones) {
        if ([zone.id isEqualToNumber:theId]) {
            return zone;
        }
    }
    return nil;
}

- (void)setZoneCounter:(WaterNowZone*)zone
{
    DBZone *dbZone = [self zoneWithId:zone.id];
    if (!dbZone) {
        dbZone = [self addZoneWithId:zone.id];
    }
    
    dbZone.counter = zone.counter;
    
    [self saveData];
}

- (void)applyMigrationFix
{
    // This fix is done to work around the case when during the default migration from model1->model6 (app v1->v2) the isDiscovered field took the default NO value.
    // For remote sprinklers isDiscovered's value should always be YES. This fix walks through all remote devices which migrated wrongly during model1->model6 and fixes them.
    // Get list of remote sprinklers with isDiscovered == NO
    
    NSArray *remoteSprinklers = [self getSprinklersFromNetwork:NetworkType_Remote aliveDevices:@NO];
    for (Sprinkler *sprinkler in remoteSprinklers) {
        sprinkler.isDiscovered = @YES;
        sprinkler.isLocalDevice = @NO;
    }
    
    if (remoteSprinklers.count > 0) {
        [self saveData];
    }
}

- (void)fixBrokenSprinklerAddresses
{
    // Migration
    // This fix applies for sprinker address urls which were stored together with the port (in early versions)
    // Here parse the port and store it into the port field.
    
    BOOL wasFixed = NO;
    NSArray *sprinklers = [self getAllSprinklersFromNetwork];
    for (Sprinkler *sprinkler in sprinklers) {
        NSURL *url = [NSURL URLWithString:sprinkler.address];
        NSString *port = [[url port] stringValue];

        if ([port length] > 0) {
            if ([port length] + 1  < [sprinkler.address length]) {
                sprinkler.address = [sprinkler.address substringToIndex:[sprinkler.address length] - ([port length] + 1)];
            }
            
            sprinkler.port = port;
            
            wasFixed = YES;
        }
        
        if ([sprinkler.port length] == 0) {
            sprinkler.port = @"443";
            
            wasFixed = YES;
        }
    }
    
    if (wasFixed) {
        [self saveData];
    }
}

#pragma mark - Core Data Stack

- (void)saveData {
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Save error: %@", [error localizedDescription]);
    }
}

- (NSString *)stringApplicationCachesDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSString *)stringApplicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
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

//START:progressivelyMigrateURLMethodName
- (BOOL)progressivelyMigrateURL:(NSURL*)sourceStoreURL
                         ofType:(NSString*)type
                        toModel:(NSManagedObjectModel*)finalModel
                          error:(NSError**)error
{
    //END:progressivelyMigrateURLMethodName
    //START:progressivelyMigrateURLHappyCheck
    NSDictionary *sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type
                                                               URL:sourceStoreURL
                                                             error:error];
    if (!sourceMetadata) return NO;
    
    if ([finalModel isConfiguration:nil
        compatibleWithStoreMetadata:sourceMetadata]) {
        *error = nil;
        return YES;
    }
    //END:progressivelyMigrateURLHappyCheck
    //START:progressivelyMigrateURLFindModels
    //Find the source model
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel
                                         mergedModelFromBundles:nil
                                         forStoreMetadata:sourceMetadata];
    NSAssert(sourceModel != nil, ([NSString stringWithFormat:
                                   @"Failed to find source model\n%@",
                                   sourceMetadata]));
    
    //Find all of the mom and momd files in the Resources directory
    NSMutableArray *modelPaths = [NSMutableArray array];
    NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                            inDirectory:nil];
    for (NSString *momdPath in momdArray) {
        NSString *resourceSubpath = [momdPath lastPathComponent];
        NSArray *array = [[NSBundle mainBundle]
                          pathsForResourcesOfType:@"mom"
                          inDirectory:resourceSubpath];
        [modelPaths addObjectsFromArray:array];
    }
    NSArray* otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom"
                                                              inDirectory:nil];
    [modelPaths addObjectsFromArray:otherModels];
    
    if (!modelPaths || ![modelPaths count]) {
        //Throw an error if there are no models
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"No models found in bundle"
                forKey:NSLocalizedDescriptionKey];
        //Populate the error
        *error = [NSError errorWithDomain:@"Zarra" code:8001 userInfo:dict];
        return NO;
    }
    //END:progressivelyMigrateURLFindModels
    
    //See if we can find a matching destination model
    //START:progressivelyMigrateURLFindMap
    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;
    for (modelPath in modelPaths) {
        targetModel = [[NSManagedObjectModel alloc]
                       initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
        mappingModel = [NSMappingModel mappingModelFromBundles:nil
                                                forSourceModel:sourceModel
                                              destinationModel:targetModel];
        //If we found a mapping model then proceed
        if (mappingModel) break;
    }
    //We have tested every model, if nil here we failed
    if (!mappingModel) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"No models found in bundle"
                forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"Zarra"
                                     code:8001
                                 userInfo:dict];
        return NO;
    }
    //END:progressivelyMigrateURLFindMap
    //We have a mapping model and a destination model.  Time to migrate
    //START:progressivelyMigrateURLMigrate
    NSMigrationManager *manager = [[NSMigrationManager alloc]
                                   initWithSourceModel:sourceModel
                                   destinationModel:targetModel];
    
    NSString *modelName = [[modelPath lastPathComponent]
                           stringByDeletingPathExtension];
    NSString *storeExtension = [[sourceStoreURL path] pathExtension];
    NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];
    //Build a path to write the new store
    storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath,
                 modelName, storeExtension];
    NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];
    
    if (![manager migrateStoreFromURL:sourceStoreURL
                                 type:type
                              options:nil
                     withMappingModel:mappingModel
                     toDestinationURL:destinationStoreURL
                      destinationType:type
                   destinationOptions:nil
                                error:error]) {
        return NO;
    }
    //END:progressivelyMigrateURLMigrate
    //Migration was successful, move the files around to preserve the source
    //START:progressivelyMigrateURLMoveAndRecurse
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    guid = [guid stringByAppendingPathExtension:modelName];
    guid = [guid stringByAppendingPathExtension:storeExtension];
    NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
    NSString *backupPath = [appSupportPath stringByAppendingPathComponent:guid];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager moveItemAtPath:[sourceStoreURL path]
                              toPath:backupPath
                               error:error]) {
        //Failed to copy the file
        return NO;
    }
    //Move the destination to the source path
    if (![fileManager moveItemAtPath:storePath
                              toPath:[sourceStoreURL path]
                               error:error]) {
        //Try to back out the source move first, no point in checking it for errors
        [fileManager moveItemAtPath:backupPath
                             toPath:[sourceStoreURL path]
                              error:nil];
        return NO;
    }
    //We may not be at the "current" model yet, so recurse
    return [self progressivelyMigrateURL:sourceStoreURL
                                  ofType:type 
                                 toModel:finalModel 
                                   error:error];
    //END:progressivelyMigrateURLMoveAndRecurse
}

- (NSManagedObjectModel *)managedObjectModelForVersion:(NSString *)version
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"Sprinklers.momd/Sprinklers %@",version] withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return model;
}

- (void) setAllSprinklersDiscovered
{
    NSArray* array = [self getAllSprinklersFromNetwork];
    BOOL doSave = NO;
    for (int i=0; i<array.count; i++) {
        Sprinkler* sprinkler = [array objectAtIndex: i];
        if ([sprinkler.isDiscovered intValue] == 0) {
            sprinkler.isDiscovered = [NSNumber numberWithInt: 1];
            doSave = YES;
        }
    }
    
    if (doSave)
        [self saveData];
}
    
- (BOOL) persistenStoreExistsInCaches {
    NSString *storePath = [[self stringApplicationCachesDirectory] stringByAppendingPathComponent:@"sprinklers.sqlite"];
 
    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath] == YES) {
        
        return YES;
    }
    
    return NO;
}

- (BOOL) persistenStoreExistsInDocuments {
    NSString *storePath = [self persistentStoreLocation];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath] == YES) {
        return YES;
    }
    
    return NO;
}

- (NSString*) sprinklerStoreDirectory {
    return @"sprinkler_store";
}

- (NSString*) persistentStoreLocation
{
    [self createStoreDataDirectoryIfNeeded];

    return [[[self stringApplicationDocumentsDirectory] stringByAppendingPathComponent: [self sprinklerStoreDirectory]]
     stringByAppendingPathComponent:@"sprinklers.sqlite"];
}

- (void) createStoreDataDirectoryIfNeeded {
    
    NSError* error;
    NSString* directoryPath = [[self stringApplicationDocumentsDirectory] stringByAppendingPathComponent:[self sprinklerStoreDirectory]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath] == NO)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath: directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
}

- (void) migrateStoreFromCachesToDocuments:(NSPersistentStoreCoordinator*) storeCoordinator andStore: (NSPersistentStore*) store{

    NSError* error = nil;
    NSString *storePath = [self persistentStoreLocation];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    [storeCoordinator migratePersistentStore:store toURL:storeURL options:nil withType:NSSQLiteStoreType error:&error];
}

- (void) moveStoreFromCachesToDocuments {

    NSString *storePath = nil;
    // load store
    storePath = [[self stringApplicationCachesDirectory] stringByAppendingPathComponent: @"sprinklers.sqlite"];
    
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    NSError *error = nil;
    NSPersistentStore* store = [__persistentStoreCoordinator persistentStoreForURL:storeURL];
    
    [self migrateStoreFromCachesToDocuments:__persistentStoreCoordinator andStore:store];
    
    // delete old persistent store
    if ([[NSFileManager defaultManager] fileExistsAtPath: storePath]) {
        
        // Remove the persistent store associated to the old location
        [self removeOldStoreFromStoreCoordinator:__persistentStoreCoordinator];
        
        if (![[NSFileManager defaultManager] removeItemAtPath:storePath error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)removeOldStoreFromStoreCoordinator:(NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    NSString *oldStorePath = [[self stringApplicationCachesDirectory] stringByAppendingPathComponent:@"sprinklers.sqlite"];
    NSURL *oldStoreURL = [NSURL fileURLWithPath:oldStorePath];
    
    NSPersistentStore *persistentStore = [persistentStoreCoordinator persistentStoreForURL:oldStoreURL];
    if (persistentStore) {
        NSError *error = nil;
        [persistentStoreCoordinator removePersistentStore:persistentStore error:&error];
        if (error) {
            NSLog(@"Error removing old store: %@", error);
        }
    }
}

- (void) removeDuplicates {
    
    NSArray* array = [self getAllSprinklersFromNetwork];
    
    NSMutableArray* sprinklersToDelete = [NSMutableArray array];

    for (int i=0; i<array.count; i++) {
        Sprinkler* sprinkler = [array objectAtIndex: i];
        if ([sprinkler.isDiscovered intValue] == 0) {
            
            // this is an old sprinkler, if something else with the same name exists, delete it
            for (int j=0; j<array.count; j++) {
                if (i != j) {
                    Sprinkler* sprinkler2 = [array objectAtIndex: j];
                    if ([sprinkler2.isDiscovered intValue] == 1) { // this is a new sprinkler
                        if ([sprinkler.name isEqualToString: sprinkler2.name] == YES) {
                            // first sprinkler must be deleted from
                            
                            [sprinklersToDelete addObject: sprinkler];
                        }
                    }
                }
            }
            
        }
    }
    
    for (Sprinkler* sprinkler in sprinklersToDelete) {
        [self.managedObjectContext deleteObject:sprinkler];
    }
    
    if (sprinklersToDelete.count > 0) {
        [self saveData];
    }
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    BOOL storeNeedsToRelocate = NO;
    
    NSString *storePath = [self persistentStoreLocation];
    
    // run once code
    if ([self persistenStoreExistsInCaches] && ![self persistenStoreExistsInDocuments]) {
        storeNeedsToRelocate = YES;
        storePath = [[self stringApplicationCachesDirectory] stringByAppendingPathComponent:@"sprinklers.sqlite"];
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSPersistentStore* store = nil;
    if (!(store=[__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // run once code
    if (storeNeedsToRelocate) {
        [self removeDuplicates];
        
        [self setAllSprinklersDiscovered];
    
        [self moveStoreFromCachesToDocuments];
    }
    
    [self fixBrokenSprinklerAddresses];
    
    return __persistentStoreCoordinator;
}

- (void)setCurrentSprinkler:(Sprinkler *)currentSprinklerP
{
    if (currentSprinklerP != __currentSprinkler) {
        __currentSprinkler = currentSprinklerP;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewSprinklerSelected object:nil];
}

@end
