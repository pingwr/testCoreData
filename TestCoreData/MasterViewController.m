//
//  MasterViewController.m
//  TestCoreData
//
//  Created by wping on 4/13/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "MasterViewController.h"
#import "Feature.h"
#import "AppConfigures.h"
#import "ThreadRWViewController.h"
#import "FeatureDao.h"
#import "WritePerformaceViewController.h"
#import "QueryPerformanceViewController.h"

@interface MasterViewController ()

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self createFeatures];
}

- (void)createFeatures
{
    NSDictionary* dictFeatures = @{
                                   @(FeatureTypeInheri):@"继承"
                                   ,@(FeatureTypeRelation):@"关系"
                                   ,@(FeatureTypeThreadRW):@"跨线程读写对象"
                                   ,@(FeatureTypeSavePerformace):@"保存性能"
                                   ,@(FeatureTypeQueryPerformace):@"查询性能"
                                   ,@(FeatureTypeMemoryUsed):@"内存使用"
                                   };
    NSArray *fetchedObjects = self.fetchedResultsController.fetchedObjects;
    NSMutableArray* needCreateFeatureTypes = [NSMutableArray arrayWithArray:dictFeatures.allKeys];
    for(Feature* feature in fetchedObjects)
    {
        if(dictFeatures[@(feature.type)])
        {
            [needCreateFeatureTypes removeObject:@(feature.type)];
        }
    }
    
    if(needCreateFeatureTypes.count > 0)
    {
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        [threadContext performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            
            FeatureDao* dao = [[FeatureDao alloc] initWithManagedObjectContext:managedObjectContext];
            for(NSNumber* type in needCreateFeatureTypes)
            {
                Feature* featureNew = [dao newObject];
                featureNew.type = [type intValue];
                featureNew.name = dictFeatures[type];
                
                [dao insertObject:featureNew];
            }

        } resultBlock:^(BOOL success) {
            
            NSLog(@"create features %@",success ? @"success" : @"failed");
            
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    
    [self createFeatures];

}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
        id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [mainContext performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            [managedObjectContext deleteObject:object];
        } resultBlock:nil];

    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Feature *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [object.name stringByAppendingString:(object.unread ? @" (new)" : @" (readed)")];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* vc;
    Feature *feature = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    switch(feature.type)
    {
        case FeatureTypeThreadRW:
            vc = [[ThreadRWViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case FeatureTypeSavePerformace:
            vc = [[WritePerformaceViewController alloc] initWithNibName:nil bundle:nil];
            break;
        case FeatureTypeQueryPerformace:
            vc = [[QueryPerformanceViewController alloc] initWithNibName:nil bundle:nil];
            break;
        default:
            break;
    }
    if(vc == nil)
        return;
    
    [self.navigationController pushViewController:vc animated:YES];
    
    if(feature.unread)
    {
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getMainContext];
        [threadContext performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            feature.unread = NO;
            
        } resultBlock:nil];
    }
    
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [mainContext entityDescriptionOfClass:[Feature class]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
//    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"unread" ascending:NO];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"type" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor,sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:mainContext.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */


@end
