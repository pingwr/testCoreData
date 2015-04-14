//
//  MasterViewController.h
//  TestCoreData
//
//  Created by wping on 4/13/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;


@end

