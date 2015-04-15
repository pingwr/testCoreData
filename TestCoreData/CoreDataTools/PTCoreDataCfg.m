//
//  PTCoreDataCfg.m
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "PTCoreDataCfg.h"

@implementation PTCoreDataCfg
- (id)initWithMomdName:(NSString*)momdName sqliteName:(NSString*)sqliteName
{
    self = [super init];
    if(self)
    {
        _momdName = momdName;
        _sqliteName = sqliteName;
    }
    return self;
}

@end
