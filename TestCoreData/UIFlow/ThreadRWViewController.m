//
//  ThreadRWViewController.m
//  TestCoreData
//
//  Created by pingwr on 15-4-18.
//  Copyright (c) 2015年 DMSSQA. All rights reserved.
//

#import "ThreadRWViewController.h"
#import "AppConfigures.h"
#import "User.h"
#import "UserDao.h"

@interface ThreadRWViewController ()
{
    NSMutableArray* _descriptions;
}
@end

@implementation ThreadRWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    _descriptions = [NSMutableArray new];
//    [self testMainInsertThreadRead];
    [self testThreadInsertMainRead];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deleteAllUsers
{
    [[[AppConfigures singleton] getThreadContext] performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
        
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        [dao deleteAllObjects];
        
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

- (void)pushDesc:(NSString*)desc mainThread:(BOOL)mainThread
{
    [_descriptions addObject:[NSString stringWithFormat:@"%@: %@",(mainThread ? @"M":@"          T"),desc]];
}

- (NSString*)userDesc:(User*)user
{
    return [NSString stringWithFormat:@"{%d,%@}",user.id,user.name];
}

#pragma mark - Table View


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _descriptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = _descriptions[[indexPath row]];
}

#pragma mark - test functions
- (void)testMainInsertThreadRead
{
    PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
    __block User* user;
    [mainContext performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
       
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        user = [dao newObject];
        user.id = 1;
        user.name = @"a1";
        
    } resultBlock:^(BOOL success) {
        
        [self pushDesc:[NSString stringWithFormat:@"save user %@",[self userDesc:user]] mainThread:YES];
        
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
  
        __block User* threadUser;
        [threadContext performQueryAndWaitWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
            threadUser = [dao findObjectByIDValue:@(user.id)];

        }];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? user : threadUser)]] mainThread:NO];

        [self.tableView reloadData];
        [self deleteAllUsers];
    }];
}

- (void)testThreadInsertMainRead
{
    PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
    __block User* user;
    [threadContext performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
        
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        user = [dao newObject];
        user.id = 1;
        user.name = @"a1";
        
    } resultBlock:^(BOOL success) {
        
        [self pushDesc:[NSString stringWithFormat:@"save user %@",[self userDesc:user]] mainThread:NO];
        
        __block User* mainUser;
        PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
        [mainContext performQueryAndWaitWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
            mainUser = [dao findObjectByIDValue:@(user.id)];
        }];
        
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(mainUser==nil ? @"can't " : @""),[self userDesc:(mainUser==nil ? user : mainUser)]] mainThread:YES];
        
        [self.tableView reloadData];
        [self deleteAllUsers];
        
    }];
}

@end