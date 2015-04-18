//
//  PTCoreDataContext.m
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "PTCoreDataContext.h"

@interface PTCoreDataContext ()
{
    PTCoreDataContext* _parentContext;
}

@end


@implementation PTCoreDataContext

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext parentContext:(PTCoreDataContext*)parentContext
{
    self = [super init];
    if(self)
    {
        _managedObjectContext = managedObjectContext;
        _parentContext = parentContext;
    }
    return self;
}

- (void)performSaveWithBlock:(void (^)(NSManagedObjectContext* managedObjectContext))block resultBlock:(void (^)(BOOL success))resultBlock
{
    [_managedObjectContext performBlock:^{
       
        if(block)
            block(_managedObjectContext);
        
//        NSLog(@"%@,%@ before save",self,_managedObjectContext.hasChanges ? @"has changed" : @"no changed");
        BOOL saveSuccess = [_managedObjectContext save:nil];
//        NSLog(@"%@,%@ after save",self,_managedObjectContext.hasChanges ? @"has changed" : @"no changed");
        if((_parentContext != nil) && saveSuccess)
        {
            [_parentContext performSaveWithBlock:nil  resultBlock:resultBlock];
        }
        else
        {
            if([self isMainQueueContext])
            {
                if(resultBlock)
                    resultBlock(saveSuccess);
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if(resultBlock)
                        resultBlock(saveSuccess);
                    
                });
            }
            
        }
    }];
}

- (BOOL)isMainQueueContext
{
    return (_managedObjectContext.concurrencyType == NSMainQueueConcurrencyType);
}

- (NSEntityDescription*)entityDescriptionOfClass:(Class)class
{
    return [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:_managedObjectContext];
}

- (id)newEntityByClass:(Class)class
{
    
    return [[class alloc] initWithEntity:[self entityDescriptionOfClass:class] insertIntoManagedObjectContext:_managedObjectContext];
}

- (id)findEntityOfClass:(Class)class attributeName:(NSString*)attributeName attributeValue:(NSObject*)attributeValue
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [self entityDescriptionOfClass:class];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K == %@",attributeName,attributeValue];
    [fetchRequest setPredicate:predicate];

    __block NSArray* objects;
    if([[NSThread currentThread] isMainThread] == [self isMainQueueContext])
    {
        objects = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    }
    else
    {
        [_managedObjectContext performBlockAndWait:^{
            
            objects = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
            
        }];
    }
    if(objects.count == 1)
        return objects[0];
    else
        return nil;
}

@end
