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

@interface ThreadRWViewController ()
{
    NSMutableArray* _descriptions;
}
@end

@implementation ThreadRWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self testMainInsertThreadRead];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)testMainInsertThreadRead
{
    PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
    __block User* user;
    [mainContext performSaveWithBlock:^(NSManagedObjectContext *managedObjectContext) {
       
        user = [mainContext newEntityByClass:[User class]];
        user.id = 1;
        user.name = @"a1";
        
    } resultBlock:^(BOOL success) {
        
        [self pushDesc:[NSString stringWithFormat:@"save user %@",[self userDesc:user]] mainThread:YES];
        
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        User* threadUser;
        threadUser = [threadContext findEntityOfClass:[User class] idValue:@(user.id)];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(threadUser==nil ? @"can't " : @""),[self userDesc:threadUser]] mainThread:NO];

        [self.tableView reloadData];
    }];
}

@end
