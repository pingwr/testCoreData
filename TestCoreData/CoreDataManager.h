//
//  CoreDataManager.h
//  TestCoreData
//
//  Created by wping on 4/13/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContextForWrite;

- (NSEntityDescription*)entityForWrite:(BOOL)forWrite fromClass:(Class)class;
- (id)createEntityObjectForWrite:(BOOL)forWrite fromClass:(Class)class;

+ (CoreDataManager*)singleton;

@end
