//
//  PTEntityDao.h
//  TestCoreData
//
//  Created by pingwr on 15-4-20.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PTEntityDao : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext entityClass:(Class)entityClass;
- (NSEntityDescription*)entityDescription;
- (id)newObject;
- (void)insertObject:(id)object;
- (id)findObjectByIDValue:(NSObject*)idValue;
- (id)findObjectByAttributeName:(NSString*)attributeName attributeValue:(NSObject*)attributeValue;

@end
