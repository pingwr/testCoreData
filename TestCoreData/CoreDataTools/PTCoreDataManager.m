//
//  PTCoreDataManager.m
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "PTCoreDataManager.h"

@interface PTCoreDataManager ()
{
    PTCoreDataCfg* _config;
    NSManagedObjectModel* _managedObjectModel;
    NSPersistentStoreCoordinator* _persistentStoreCoordinator;
    
    PTCoreDataContext* _rootContext;
    PTCoreDataContext* _mainContext;
    PTCoreDataContext* _threadContext;
}

@end

@implementation PTCoreDataManager
- (id)initWithConfig:(PTCoreDataCfg*)config
{
    self = [super init];
    if(self)
    {
        _config = config;
    }
    return self;
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.arcsoft.com.TestCoreData" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_config.momdName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:_config.sqliteName];
    NSError *error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
//        NSString *failureReason = @"There was an error creating or loading the application's saved data.";
//        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
//        dict[NSUnderlyingErrorKey] = error;
//        error = [NSError errorWithDomain:@"PTCoreDataError" code:9999 userInfo:dict];
//        // Replace this with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

- (PTCoreDataContext*)getMainContext
{
    if(_mainContext == nil)
    {
        _mainContext = [self createCoreDataContextWithParentContext:[self getRootContext] mainQueue:YES];
    }
    
    return _mainContext;
}

- (PTCoreDataContext*)getThreadContext
{
    if(_threadContext == nil)
    {
        _threadContext = [self createCoreDataContextWithParentContext:[self getMainContext] mainQueue:NO];
    }
    
    return _threadContext;
}

- (PTCoreDataContext*)createCoreDataContextWithParentContext:(PTCoreDataContext*)parentContext mainQueue:(BOOL)mainQueue
{
    NSManagedObjectContext* managedObjectContext = [self createManagedObjectContextWithParentContext:parentContext.managedObjectContext mainQueue:mainQueue];
    return [[PTCoreDataContext alloc] initWithManagedObjectContext:managedObjectContext parentContext:parentContext];
}

- (PTCoreDataContext*)getRootContext
{
    if(_rootContext == nil)
    {
        NSManagedObjectContext* managedObjectContext = [self createManagedObjectContextWithParentContext:nil mainQueue:NO];
        _rootContext = [[PTCoreDataContext alloc] initWithManagedObjectContext:managedObjectContext parentContext:nil];
    }
    
    return _rootContext;
}

- (NSManagedObjectContext*)createManagedObjectContextWithParentContext:(NSManagedObjectContext*)parentContext mainQueue:(BOOL)mainQueue
{
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:mainQueue ? NSMainQueueConcurrencyType : NSPrivateQueueConcurrencyType];
    if(parentContext)
    {
        [managedObjectContext setParentContext:parentContext];
    }
    else
    {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator)
        {
            [managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
        else
        {
            managedObjectContext = nil;
        }
    }
    
    return managedObjectContext;
}

@end
