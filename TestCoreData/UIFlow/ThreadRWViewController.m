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

#define MAKE_USERNAME_(id,extra) [NSString stringWithFormat:@"u%d%@%@",id,(extra ? @"_" : @""),(extra ? @(extra) : @"")];
#define MAKE_USERNAME(id)   MAKE_USERNAME_(id,0)

static int32_t nextUserId = 0;

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
    [self addTask_UpdateWithoutSave];
    
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
    NSString* log = [NSString stringWithFormat:@"%@: %@",(mainThread ? @"M":@"          S"),desc];
    [_descriptions addObject:log];
    NSLog(@"%@",log);
}

- (void)pushTaskDesc:(NSString*)desc
{
    NSString* log = [NSString stringWithFormat:@"********* %@",desc];
    [_descriptions addObject:log];
    NSLog(@"%@",log);
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
- (PTCoreDataContext*)getCoreDataContextOfMainThread:(BOOL)mainThread
{
    if(mainThread)
        return [[AppConfigures singleton] getMainContext];
    else
        return [[AppConfigures singleton] getThreadContext];
}

- (NSManagedObjectContext*)getManagedObjectContextOfMainThread:(BOOL)mainThread
{
    return [[self getCoreDataContextOfMainThread:mainThread] managedObjectContext];
}

- (User*)insertUserInMainThread:(BOOL)mainThread
{
    __block User* user;
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContextOfMainThread:mainThread];
    [managedObjectContext performBlockAndWait:^{
        
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        user = [dao newObject];
        user.id = ++nextUserId;
        user.name = MAKE_USERNAME(user.id);

    }];
    
    return user;
}

- (User*)findUserById:(int32_t)id mainThread:(BOOL)mainThread
{
    __block User* user;
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContextOfMainThread:mainThread];
    [managedObjectContext performBlockAndWait:^{
        
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        user = [dao findObjectByIDValue:@(id)];
        
    }];
    
    return user;
}

- (void)addTask_MainInsertThreadRead
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"insert in M,read in S"];
        __block User* user;
        [[self getCoreDataContextOfMainThread:YES] performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
            user = [dao newObject];
            user.id = ++nextUserId;
            user.name = MAKE_USERNAME(user.id);
            
        } resultBlock:^(BOOL success) {
            
            [self pushDesc:[NSString stringWithFormat:@"save user %@",[self userDesc:user]] mainThread:YES];
            
            User* threadUser = [self findUserById:user.id mainThread:NO];
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
        __block User* user;
        [[self getCoreDataContextOfMainThread:NO] performUpdateWithBlock:^(NSManagedObjectContext *managedObjectContext) {
            
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
            user = [dao newObject];
            user.id = ++nextUserId;
            user.name = MAKE_USERNAME(user.id);
            
        } resultBlock:^(BOOL success) {
            
            [self pushDesc:[NSString stringWithFormat:@"save user %@",[self userDesc:user]] mainThread:NO];
            
            User* mainUser = [self findUserById:user.id mainThread:YES];
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

        User* user = [self insertUserInMainThread:YES];
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:YES];
        
        User* threadUser = [self findUserById:user.id mainThread:NO];
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
        
        User* user = [self insertUserInMainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:NO];

        User* mainUser = [self findUserById:user.id mainThread:YES];;
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(mainUser==nil ? @"can't " : @""),[self userDesc:(mainUser==nil ? user : mainUser)]] mainThread:YES];
        
        [self deleteAllUsersWithBlock:^{
            [self continueNextTask];
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
        user.id = ++nextUserId;
        user.name = MAKE_USERNAME(user.id);
        
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
            user.id = ++nextUserId;
            user.name = MAKE_USERNAME(user.id);
            
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

- (void)addTask_UpdateWithoutSave
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"update between M and S without save"];

        PTCoreDataContext* threadContext = [[AppConfigures singleton] getThreadContext];
        PTCoreDataContext* mainContext = [[AppConfigures singleton] getMainContext];
        NSManagedObjectContext *managedObjectContextThread = threadContext.managedObjectContext;
        NSManagedObjectContext *managedObjectContextMain = mainContext.managedObjectContext;
        
        __block User* userMain;
        __block User* threadUser;

        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContextMain];
        userMain = [dao newObject];
        userMain.id = ++nextUserId;
        userMain.name = MAKE_USERNAME(userMain.id);
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:userMain]] mainThread:YES];
        
        [managedObjectContextThread performBlockAndWait:^{
//            threadUser = (User*)[managedObjectContextThread existingObjectWithID:userMain.objectID error:nil];
            threadUser = (User*)[managedObjectContextThread objectWithID:userMain.objectID];
        }];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by existingObjectWithID",(threadUser==nil ? @"can't " : @""),(threadUser!=nil ? [self userDesc:threadUser] : @"")] mainThread:NO];

        userMain.name = MAKE_USERNAME_(userMain.id,1);
        [self pushDesc:[NSString stringWithFormat:@"update user %@",[self userDesc:userMain]] mainThread:YES];
        
        [managedObjectContextThread performBlockAndWait:^{
            threadUser = (User*)[managedObjectContextThread existingObjectWithID:userMain.objectID error:nil];
        }];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by existingObjectWithID",(threadUser==nil ? @"can't " : @""),(threadUser!=nil ? [self userDesc:threadUser] : @"")] mainThread:NO];
        
        [self deleteAllUsersWithBlock:^{
            [self continueNextTask];
        }];
        
    };
    [_tasks addObject:block];
}

@end
