//
//  PTCoreDataCfg.h
//  TestCoreData
//
//  Created by wping on 4/15/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PTCoreDataCfg : NSObject

@property(nonatomic,readonly) NSString* momdName;
@property(nonatomic,readonly) NSString* sqliteName;

- (id)initWithMomdName:(NSString*)momdName sqliteName:(NSString*)sqliteName;

@end
