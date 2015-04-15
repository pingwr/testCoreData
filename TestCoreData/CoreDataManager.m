//
//  CoreDataManager.m
//  TestCoreData
//
//  Created by wping on 4/13/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "CoreDataManager.h"

#define COREDATA_MOMD_NAME   @"TestCoreData"
#define COREDATA_SQLITE_NAME @"TestCoreData.sqlite"

@interface CoreDataManager ()
{
    
}

@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreDataManager

+ (CoreDataManager*)singleton
{
    static CoreDataManager* instance;
    if(instance == nil)
    {
        instance = [CoreDataManager new];
    }
    return instance;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectContextForWrite = _managedObjectContextForWrite;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.arcsoft.com.TestCoreData" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:COREDATA_MOMD_NAME withExtension:@"momd"];
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
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:COREDATA_SQLITE_NAME];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    return [self managedObjectContextForWrite:NO];
}

- (NSManagedObjectContext *)managedObjectContextForWrite {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    return [self managedObjectContextForWrite:YES];
}

- (NSManagedObjectContext *)managedObjectContextForWrite:(BOOL)forWrite {
    
    NSManagedObjectContext* managedObjectContext = (forWrite ? _managedObjectContextForWrite : _managedObjectContext);
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:forWrite ? NSPrivateQueueConcurrencyType : NSMainQueueConcurrencyType];
    if(forWrite)
    {
        managedObjectContext.parentContext = self.managedObjectContext;
        _managedObjectContextForWrite = managedObjectContext;
    }
    else
    {
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
        _managedObjectContext = managedObjectContext;
    }
    
    return managedObjectContext;
}

-(NSEntityDescription*)entityForWrite:(BOOL)forWrite fromClass:(Class)class
{
    return [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:[self managedObjectContextForWrite:forWrite]];
}

- (id)createEntityObjectForWrite:(BOOL)forWrite fromClass:(Class)class
{
    
    return [[class alloc] initWithEntity:[self entityForWrite:forWrite fromClass:class] insertIntoManagedObjectContext:[self managedObjectContextForWrite:forWrite]];
}

- (int)test
{
    int i =0;
    return i;
}

@end
