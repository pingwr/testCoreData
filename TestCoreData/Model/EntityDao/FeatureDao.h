//
//  FeatureDao.h
//  TestCoreData
//
//  Created by pingwr on 15-4-20.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import "PTEntityDao.h"
#import "Feature.h"

@interface FeatureDao : PTEntityDao

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
