//
//  PTCoreDataContext.h
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PTCoreDataContext : NSObject

@property(nonatomic,readonly) NSManagedObjectContext* managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext parentContext:(PTCoreDataContext*)parentContext;
- (void)performSaveWithBlock:(void (^)(NSManagedObjectContext* managedObjectContext))block resultBlock:(void (^)(BOOL success))resultBlock;

@end
