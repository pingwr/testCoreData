//
//  UserDao.h
//  TestCoreData
//
//  Created by pingwr on 15-4-20.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import "PTEntityDao.h"
#import "User.h"

@interface UserDao : PTEntityDao

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
