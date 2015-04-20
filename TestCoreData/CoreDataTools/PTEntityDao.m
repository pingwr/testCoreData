//
//  PTEntityDao.m
//  TestCoreData
//
//  Created by pingwr on 15-4-20.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import "PTEntityDao.h"

@interface PTEntityDao ()
{
    NSManagedObjectContext* _managedObjectContext;
}

@property(nonatomic) Class entityClass;

@end

@implementation PTEntityDao
- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext entityClass:(Class)entityClass
{
    self = [super init];
    if(self)
    {
        _managedObjectContext = managedObjectContext;
        _entityClass = entityClass;
    }
    return self;
}

- (NSEntityDescription*)entityDescription
{
    return [NSEntityDescription entityForName:NSStringFromClass([self entityClass]) inManagedObjectContext:_managedObjectContext];
}

- (id)newObject
{
    
    return [[[self entityClass] alloc] initWithEntity:[self entityDescription] insertIntoManagedObjectContext:_managedObjectContext];
}

- (void)insertObject:(id)object
{
    [_managedObjectContext insertObject:object];
}

- (id)findObjectByIDValue:(NSObject*)idValue
{
    return [self findObjectByAttributeName:@"id" attributeValue:idValue];
}

- (id)findObjectByAttributeName:(NSString*)attributeName attributeValue:(NSObject*)attributeValue
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [self entityDescription];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K == %@",attributeName,attributeValue];
    [fetchRequest setPredicate:predicate];
    
    NSArray* objects = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if(objects.count == 1)
        return objects[0];
    else
        return nil;
}


@end
