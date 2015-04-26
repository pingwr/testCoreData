//
//  WritePerformaceViewController.m
//  TestCoreData
//
//  Created by wping on 4/25/15.
//  Copyright (c) 2015 DMSSQA. All rights reserved.
//

#import "WritePerformaceViewController.h"
#import "AppConfigures.h"
#import "User.h"
#import "UserDao.h"

#define MAKE_USERNAME_(id,extra) [NSString stringWithFormat:@"u%d%@%@",id,(extra ? @"_" : @""),(extra ? @(extra) : @"")];
#define MAKE_USERNAME(id)   MAKE_USERNAME_(id,0)

static int32_t nextUserId = 0;


@interface WritePerformaceViewController ()
{
    NSMutableArray* _descriptions;
}

@end

@implementation WritePerformaceViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        _descriptions = [NSMutableArray new];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[self tableView] registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    [self startTest];
    [self.tableView reloadData];
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

- (void)deleteAllUsers
{
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContextOfMainThread:NO];
    [managedObjectContext performBlockAndWait:^{

        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        [dao deleteAllObjects];
        [managedObjectContext save:nil];
        
        NSManagedObjectContext* mainContext = managedObjectContext.parentContext;
        [mainContext performBlockAndWait:^{
            [mainContext save:nil];
            
            NSManagedObjectContext* rootContext = mainContext.parentContext;
            [rootContext performBlockAndWait:^{
                [mainContext save:nil];
            }];
        }];
        
    }];
}

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

- (void)performPerformanceBlock:(void (^)())block desc:(NSString*)desc mainThread:(BOOL)mainThread
{
    NSDate* date = [NSDate date];
    block();
    NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:date];
    [self pushDesc:[NSString stringWithFormat:@"%@: %f",desc,diff] mainThread:mainThread];
}

- (void)insertUsersInContext:(NSManagedObjectContext*)managedObjectContext userCount:(NSInteger)userCount
{
    [managedObjectContext performBlockAndWait:^{
        
        UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:managedObjectContext];
        NSInteger bufLen = 1024;
        for(NSInteger i=0;i<userCount;i++)
        {
            User* user = [dao newObject];
            user.id = ++nextUserId;
            user.name = MAKE_USERNAME(user.id);
            user.data = [[NSData alloc] initWithBytesNoCopy:malloc(bufLen) length:bufLen];
        }
        [managedObjectContext save:nil];
    }];
    
}

- (void)doInsertWithUserCount:(NSInteger)userCount fromMainContext:(BOOL)fromMainContext removeAfterDone:(BOOL)removeAfterDone
{
    NSManagedObjectContext* managedObjectContext = [self getManagedObjectContextOfMainThread:fromMainContext];
    NSString* contextDesc;
    if(fromMainContext)
        contextDesc = @"main context";
    else
        contextDesc = @"save context";
    
    [self pushTaskDesc:[NSString stringWithFormat:@"save %d users begin from %@",userCount,contextDesc]];
    [self performPerformanceBlock:^{
        
        [self insertUsersInContext:managedObjectContext userCount:userCount];
        
    } desc:contextDesc mainThread:fromMainContext];
    
    NSManagedObjectContext* rootContext;
    if(!fromMainContext)
    {
        [self performPerformanceBlock:^{
            
            [managedObjectContext.parentContext performBlockAndWait:^{
                
                [managedObjectContext.parentContext save:nil];
                
            }];
        } desc:@"main context" mainThread:!fromMainContext];
        rootContext = managedObjectContext.parentContext.parentContext;
    }
    else
    {
        rootContext = managedObjectContext.parentContext;
    }
    [self performPerformanceBlock:^{
        
        [rootContext performBlockAndWait:^{
            
            [rootContext save:nil];
            
        }];
    } desc:@"root context" mainThread:!fromMainContext];
    
    if(removeAfterDone)
    {
        [self performPerformanceBlock:^{
            [self deleteAllUsers];
        } desc:@"delete all users" mainThread:NO];
    }
}

- (void)startTest
{
    NSInteger maxCount = 4000;
    NSArray* userCounts = @[@(1),@(10),@(100),@(1000),@(maxCount)];
//    for(NSNumber* userCount in userCounts)
//    {
//        [self doInsertWithUserCount:[userCount integerValue] fromMainContext:YES removeAfterDone:YES];
//        [self doInsertWithUserCount:[userCount integerValue] fromMainContext:NO removeAfterDone:YES];
//
//        [self pushTaskDesc:[NSString stringWithFormat:@"save %d users begin from %@",[userCount integerValue],@"root context"]];
//        [self performPerformanceBlock:^{
//            
//            [self insertUsersInContext:[self getManagedObjectContextOfMainThread:YES].parentContext userCount:[userCount integerValue]];
//            
//        } desc:@"root context" mainThread:NO];
//        [self performPerformanceBlock:^{
//            [self deleteAllUsers];
//        } desc:@"delete all users" mainThread:NO];
//    }
//    
    [self pushTaskDesc:@"insert 10000 users"];
    [self performPerformanceBlock:^{
        
        [self insertUsersInContext:[self getManagedObjectContextOfMainThread:YES].parentContext userCount:maxCount];
        
    } desc:@"root context" mainThread:NO];
    
    for(NSNumber* userCount in userCounts)
    {
        [self doInsertWithUserCount:[userCount integerValue] fromMainContext:YES removeAfterDone:NO];
        [self doInsertWithUserCount:[userCount integerValue] fromMainContext:NO removeAfterDone:NO];
        
        [self pushTaskDesc:[NSString stringWithFormat:@"save %d users begin from %@",[userCount integerValue],@"root context"]];
        [self performPerformanceBlock:^{
            
            [self insertUsersInContext:[self getManagedObjectContextOfMainThread:YES].parentContext userCount:[userCount integerValue]];
            
        } desc:@"root context" mainThread:NO];
    }

    [self pushTaskDesc:@"delete all users"];
    NSManagedObjectContext* saveContext = [self getManagedObjectContextOfMainThread:NO];
    [self performPerformanceBlock:^{
        [saveContext performBlockAndWait:^{
            UserDao* dao = [[UserDao alloc] initWithManagedObjectContext:saveContext];
            [dao deleteAllObjects];
            [saveContext save:nil];
        }];
    } desc:@"delete all users" mainThread:NO];
    [self performPerformanceBlock:^{
        [saveContext.parentContext save:nil];
    } desc:@"delete all users" mainThread:YES];
    [self performPerformanceBlock:^{
        [saveContext.parentContext.parentContext save:nil];
    } desc:@"delete all users" mainThread:NO];
    
}

@end
