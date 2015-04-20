//
//  FeatureDao.m
//  TestCoreData
//
//  Created by pingwr on 15-4-20.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import "FeatureDao.h"

@implementation FeatureDao

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    return [super initWithManagedObjectContext:managedObjectContext entityClass:[Feature class]];
}

@end
