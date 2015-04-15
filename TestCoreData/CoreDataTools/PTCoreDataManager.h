//
//  PTCoreDataManager.h
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTCoreDataCfg.h"
#import "PTCoreDataContext.h"

@interface PTCoreDataManager : NSObject

- (id)initWithConfig:(PTCoreDataCfg*)config;

//should be called in main thread
- (PTCoreDataContext*)getMainContext;
- (PTCoreDataContext*)getThreadContext;
- (PTCoreDataContext*)getRootContext;

@end
