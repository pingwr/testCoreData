//
//  UserDao.m
//  TestCoreData
//
//  Created by pingwr on 15-4-20.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import "UserDao.h"

@implementation UserDao

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    return [super initWithManagedObjectContext:managedObjectContext entityClass:[User class]];
}


@end
