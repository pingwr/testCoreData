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

- (User*)findUserByObjectRegisteredForID:(NSManagedObjectID*)objectID mainThread:(BOOL)mainThread
{
    __block User* user;
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContextOfMainThread:mainThread];
    [managedObjectContext performBlockAndWait:^{
        
        user = (User*)[managedObjectContext objectRegisteredForID:objectID];
        
    }];
    
    return user;
}

- (User*)findUserByObjectWithID:(NSManagedObjectID*)objectID mainThread:(BOOL)mainThread
{
    __block User* user;
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContextOfMainThread:mainThread];
    [managedObjectContext performBlockAndWait:^{
        
        user = (User*)[managedObjectContext objectWithID:objectID];
        
    }];
    
    return user;
}

- (User*)findUserByExistingObjectWithID:(NSManagedObjectID*)objectID mainThread:(BOOL)mainThread
{
    __block User* user;
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContextOfMainThread:mainThread];
    [managedObjectContext performBlockAndWait:^{
        
        user = (User*)[managedObjectContext existingObjectWithID:objectID error:nil];
        
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
        
        {
            User* user = [self insertUserInMainThread:YES];
            [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:YES];
            
            User* threadUser = [self findUserByObjectRegisteredForID:user.objectID mainThread:NO];
            [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectRegisteredForID",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? user : threadUser)]] mainThread:NO];
        }
        
        {
            User* user = [self insertUserInMainThread:YES];
            [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:YES];
            
            User* threadUser = [self findUserByObjectWithID:user.objectID mainThread:NO];
            [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? user : threadUser)]] mainThread:NO];
        }
        
        {
            User* user = [self insertUserInMainThread:YES];
            [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:YES];
            
            User* threadUser = [self findUserByExistingObjectWithID:user.objectID mainThread:NO];
            [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by existingObjectWithID",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? user : threadUser)]] mainThread:NO];
        }
        
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
        
        {
            User* user = [self insertUserInMainThread:NO];
            [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:NO];
            
            User* mainUser = [self findUserByObjectRegisteredForID:user.objectID mainThread:YES];
            [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectRegisteredForID",(mainUser==nil ? @"can't " : @""),[self userDesc:(mainUser==nil ? user : mainUser)]] mainThread:YES];
        }
        
        {
            User* user = [self insertUserInMainThread:NO];
            [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:NO];
            
            User* mainUser = [self findUserByObjectWithID:user.objectID mainThread:YES];
            [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(mainUser==nil ? @"can't " : @""),[self userDesc:(mainUser==nil ? user : mainUser)]] mainThread:YES];
        }
        
        {
            User* user = [self insertUserInMainThread:NO];
            [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:user]] mainThread:NO];
            
            User* mainUser = [self findUserByExistingObjectWithID:user.objectID mainThread:YES];
            [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by existingObjectWithID",(mainUser==nil ? @"can't " : @""),[self userDesc:(mainUser==nil ? user : mainUser)]] mainThread:YES];
        }
        
        [self deleteAllUsersWithBlock:^{
            [self continueNextTask];
        }];
        
    };
    [_tasks addObject:block];
}

- (void)addTask_UpdateWithoutSave
{
    void (^block)() = ^(){
        
        [self pushTaskDesc:@"update between M and S without save"];

        User* mainUser = [self insertUserInMainThread:YES];
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:mainUser]] mainThread:YES];
        
        User* threadUser = [self findUserByObjectWithID:mainUser.objectID mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(threadUser==nil ? @"can't " : @""),(threadUser!=nil ? [self userDesc:threadUser] : @"")] mainThread:NO];

        threadUser = [self findUserById:mainUser.id mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? mainUser : threadUser)]] mainThread:NO];
        
        mainUser.name = MAKE_USERNAME_(mainUser.id,1);
        [self pushDesc:[NSString stringWithFormat:@"update user %@",[self userDesc:mainUser]] mainThread:YES];
        
        threadUser = [self findUserByObjectWithID:mainUser.objectID mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(threadUser==nil ? @"can't " : @""),(threadUser!=nil ? [self userDesc:threadUser] : @"")] mainThread:NO];
        
        threadUser = [self findUserById:mainUser.id mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? mainUser : threadUser)]] mainThread:NO];
        
        
        
        
        mainUser = [self insertUserInMainThread:YES];
        [self pushDesc:[NSString stringWithFormat:@"insert user %@",[self userDesc:mainUser]] mainThread:YES];
        
        mainUser.name = MAKE_USERNAME_(mainUser.id,1);
        [self pushDesc:[NSString stringWithFormat:@"update user %@",[self userDesc:mainUser]] mainThread:YES];
        
        threadUser = [self findUserByObjectWithID:mainUser.objectID mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@ by objectWithID",(threadUser==nil ? @"can't " : @""),(threadUser!=nil ? [self userDesc:threadUser] : @"")] mainThread:NO];
        
        threadUser = [self findUserById:mainUser.id mainThread:NO];
        [self pushDesc:[NSString stringWithFormat:@"%@find user %@",(threadUser==nil ? @"can't " : @""),[self userDesc:(threadUser==nil ? mainUser : threadUser)]] mainThread:NO];
        

        [self deleteAllUsersWithBlock:^{
            [self continueNextTask];
        }];
        
    };
    [_tasks addObject:block];
}

@end
