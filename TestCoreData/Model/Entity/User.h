//
//  User.h
//  
//
//  Created by wping on 4/26/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, assign) int32_t id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * data;

@end
