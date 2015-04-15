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
        
        BOOL saveSuccess = [_managedObjectContext save:nil];
        
        if((_parentContext != nil) && saveSuccess)
        {
            [_parentContext performSaveWithBlock:nil  resultBlock:resultBlock];
        }
        else
        {
            if(_managedObjectContext.concurrencyType == NSMainQueueConcurrencyType)
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

@end
