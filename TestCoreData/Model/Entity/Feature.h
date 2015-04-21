//
//  Feature.h
//  TestCoreData
//
//  Created by pingwr on 15-4-18.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_OPTIONS(int32_t, FeatureType) {
    FeatureTypeInheri = 1,
    FeatureTypeRelation,
    FeatureTypeThreadRW,
    FeatureTypeSavePerformace,
    FeatureTypeQueryPerformace,
    FeatureTypeMemoryUsed,
    
};

@interface Feature : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic) FeatureType type;
@property (nonatomic) BOOL unread;

@end
