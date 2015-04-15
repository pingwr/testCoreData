//
//  AppConfigures.m
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "AppConfigures.h"

@interface AppConfigures ()
{
    PTCoreDataManager* _coreDataManager;
}

@end


@implementation AppConfigures

+ (AppConfigures*)singleton
{
    static AppConfigures* instance;
    if(instance == nil)
    {
        instance = [AppConfigures new];
    }
    
    return instance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _coreDataManager = [[PTCoreDataManager alloc] initWithConfig:[[PTCoreDataCfg alloc] initWithMomdName:@"" sqliteName:@""]];
    }
    return self;
}

- (PTCoreDataContext*)getMainContext
{
    return [_coreDataManager getMainContext];
}

- (PTCoreDataContext*)getThreadContext
{
    return [_coreDataManager getThreadContext];
}

@end
