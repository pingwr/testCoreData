//
//  Feature.h
//  TestCoreData
//
//  Created by wping on 4/13/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NS_OPTIONS(int32_t, FeatureType) {
    FeatureTypeInheri = 1,
    FeatureTypeRelation,
    FeatureTypeThreadRW,
    
};

@interface Feature : NSManagedObject

@property(assign,nonatomic) FeatureType type;
@property(copy,nonatomic) NSString* name;
@property(assign,nonatomic) BOOL unread;

@end
