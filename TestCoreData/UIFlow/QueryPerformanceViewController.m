//
//  QueryPerformanceViewController.m
//  TestCoreData
//
//  Created by wping on 4/26/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "QueryPerformanceViewController.h"
#import "User.h"
#import "UserDao.h"
#import "AppConfigures.h"

#define MAKE_USERNAME_(id,extra) [NSString stringWithFormat:@"u%d%@%@",id,(extra ? @"_" : @""),(extra ? @(extra) : @"")];
#define MAKE_USERNAME(id)   MAKE_USERNAME_(id,0)

static int32_t nextUserId = 0;


@interface QueryPerformanceViewController ()
{
    
}
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@end

@implementation QueryPerformanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    
    [self insertUsersWithCount:1000];
    
}

- (void)insertUsersWithCount:(NSInteger)userCount
{
    PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
    [mainContext performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        NSInteger bufLen = 10240;
        for(NSInteger i=0;i<userCount;i++)
        {
            User* user = [dao newObject];
            user.id = ++nextUserId;
            user.name = MAKE_USERNAME(user.id);
//            user.data = [[NSData alloc] initWithBytesNoCopy:malloc(bufLen) length:bufLen];
        }
    } resultBlock:nil];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
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

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = user.name;
    NSLog(@"configureCell user name:%@",user.name);
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
    NSEntityDescription *entity = [mainContext entityDescriptionOfClass:[User class]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}

@end
