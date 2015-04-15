//
//  AppConfigures.h
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTCoreDataManager.h"

@interface AppConfigures : NSObject

+ (AppConfigures*)singleton;

//should be called in main thread
- (PTCoreDataContext*)getMainContext;
- (PTCoreDataContext*)getThreadContext;

@end
