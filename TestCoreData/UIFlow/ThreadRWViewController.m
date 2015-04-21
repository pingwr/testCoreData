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
    NSMutableArray* _tasks;
}
@end

@implementation ThreadRWViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        _descriptions = [NSMutableArray new];
        _tasks = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self addTask_MainInsertThreadRead];
    [self addTask_ThreadInsertMainRead];
    [self addTask_MainInsertWithoutSaveThreadRead];
    [self addTask_ThreadInsertWithoutSaveMainRead];
    [self addTask_MainInsertWithoutSaveThreadReadByObjectId];
    [self addTask_ThreadInsertWithoutSaveMainReadByObjectId];
    
    [self continueNextTask];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)continueNextTask
{
    if(_tasks.count > 0)
    {
        void (^block)() = _tasks[0];
        [_tasks removeObjectAtIndex:0];
        block();
        
    }
    else
    {
        [self.tableView reloadData];
    }
}

- (void)deleteAllUsersWithBlock:(void (^)())block
{
    [[[AppConfigures singleton] getThreadContext] performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
        
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        [dao deleteAllObjects];
        
    } resultBlock:^(BOOL success) {
        if(block)
            block();
    }];
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
    [_descriptions addObject:[NSString stringWithFormat:@"%@: %@",(mainThread ? @"M":@"          S"),desc]];
}

- (void)pushTaskDesc:(NSString*)desc
{
    [_descriptions addObject:[NSString stringWithFormat:@"********* %@",desc]];
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
- (void)addTask_MainInsertThreadRead
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in M,read in S"];
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
            
            [self deleteAllUsersWithBlock:^{
                [self continueNextTask];
            }];
        }];

    };
    [_tasks addObject:block];
}

- (void)addTask_ThreadInsertMainRead
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in S,read in M"];
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
            
            [self deleteAllUsersWithBlock:^{
                [self continueNextTask];
            }];
        }];
    };
    [_tasks addObject:block];
}

- (void)addTask_MainInsertWithoutSaveThreadRead
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in M without Save,read in S"];

        PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
        NSManagedObjectContext *managedObjectContextMain = mainContext.managedObjectContext;
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContextMain];
        User* user;
        user = [dao newObject];
        user.id = 2;
        user.name = @"a2";
        
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:YES];
        
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        __block User* threadUser;
        [threadContext performQueryAndWaitWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
            threadUser = [dao findObjectByIDValue:@(user.id)];
            
        }];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? user : threadUser)]] mainThread:NO];
        
        [self deleteAllUsersWithBlock:^{
            [self continueNextTask];
        }];
    
    };
    [_tasks addObject:block];
}

- (void)addTask_ThreadInsertWithoutSaveMainRead
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in S without Save,read in M"];
        
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        NSManagedObjectContext *managedObjectContextThread = threadContext.managedObjectContext;
        [managedObjectContextThread performBlock:^{
            
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContextThread];
            User* user;
            user = [dao newObject];
            user.id = 2;
            user.name = @"a2";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:NO];

                __block User* mainUser;
                PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
                [mainContext performQueryAndWaitWithBlock:^(NSManagedObjectContext *managedObjectContext) {
                    UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
                    mainUser = [dao findObjectByIDValue:@(user.id)];
                }];
                
                [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(mainUser==nil ? @"can't " : @""),[self userDesc:(mainUser==nil ? user : mainUser)]] mainThread:YES];
                
                [self deleteAllUsersWithBlock:^{
                    [self continueNextTask];
                }];
            });

        }];
        
    };
    [_tasks addObject:block];
}

- (void)addTask_MainInsertWithoutSaveThreadReadByObjectId
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in M without Save,read in S by object id"];
        
        PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
        NSManagedObjectContext *managedObjectContextMain = mainContext.managedObjectContext;
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContextMain];
        User* user;
        user = [dao newObject];
        user.id = 3;
        user.name = @"a3";
        
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:YES];
        
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        __block User* threadUser1;
        __block User* threadUser2;
        __block User* threadUser3;
        [threadContext performQueryAndWaitWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            
            threadUser1 = (User*)[managedObjectContext objectRegisteredForID:user.objectID];
            threadUser2 = (User*)[managedObjectContext objectWithID:user.objectID];
            threadUser3 = (User*)[managedObjectContext existingObjectWithID:user.objectID error:nil];
            
        }];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectRegisteredForID",(threadUser1==nil ? @"can't " : @""),[self userDesc:(threadUser1==nil ? user : threadUser1)]] mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(threadUser2==nil ? @"can't " : @""),[self userDesc:(threadUser2==nil ? user : threadUser2)]] mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by existingObjectWithID",(threadUser3==nil ? @"can't " : @""),[self userDesc:(threadUser3==nil ? user : threadUser3)]] mainThread:NO];
        
        [self deleteAllUsersWithBlock:^{
            [self continueNextTask];
        }];
        
    };
    [_tasks addObject:block];
}

- (void)addTask_ThreadInsertWithoutSaveMainReadByObjectId
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in S without Save,read in M by object id"];
        
        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        NSManagedObjectContext *managedObjectContextThread = threadContext.managedObjectContext;
        [managedObjectContextThread performBlock:^{
            
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContextThread];
            User* user;
            user = [dao newObject];
            user.id = 3;
            user.name = @"a3";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:NO];
                
                __block User* mainUser1;
                __block User* mainUser2;
                __block User* mainUser3;
                PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
                [mainContext performQueryAndWaitWithBlock:^(NSManagedObjectContext *managedObjectContext) {
                    mainUser1 = (User*)[managedObjectContext objectRegisteredForID:user.objectID];
                    mainUser2 = (User*)[managedObjectContext objectWithID:user.objectID];
                    mainUser3 = (User*)[managedObjectContext existingObjectWithID:user.objectID error:nil];
                }];
                
                [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectRegisteredForID",(mainUser1==nil ? @"can't " : @""),[self userDesc:(mainUser1==nil ? user : mainUser1)]] mainThread:YES];
                [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(mainUser2==nil ? @"can't " : @""),[self userDesc:(mainUser2==nil ? user : mainUser2)]] mainThread:YES];
                [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by existingObjectWithID",(mainUser3==nil ? @"can't " : @""),[self userDesc:(mainUser3==nil ? user : mainUser3)]] mainThread:YES];
                
                [self deleteAllUsersWithBlock:^{
                    [self continueNextTask];
                }];
            });
            
        }];
        
    };
    [_tasks addObject:block];
}


@end
