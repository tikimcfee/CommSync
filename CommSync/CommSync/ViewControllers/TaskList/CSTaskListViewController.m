//
//  CSTaskViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskListViewController.h"
#import "CSTaskDetailViewController.h"
#import "CSTaskTableViewCell.h"
#import "AppDelegate.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"
#define kNewTaskNotification @"kNewTaskNotification"

@interface CSTaskListViewController ()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *userConnectionCount;
@property (strong, nonatomic) CSSessionManager* sessionManager;
@property (strong, nonatomic) CSTaskListManager* taskManager;

@property (strong, nonatomic) RLMRealm* realm;

@end

@implementation CSTaskListViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    self.taskManager = app.globalTaskManager;
    
    // get connection count
    NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count]; // subtract 1 to account for yourself
    
    NSLog(@"%@", _sessionManager.currentSession.connectedPeers);
    
    
    // Realms
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    
    // set connection count
    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(incrementConnectedCount:)
                                                 name:kUserConnectedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNewTask:)
                                                 name:kNewTaskNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(decrementConnectedCount:)
                                                 name:@"lostPeer"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kUserConnectedNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNewTaskNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"lostPeer"
                                                  object:self];
}

- (void)incrementConnectedCount:(NSNotification *)notification
{
    int count = [_userConnectionCount.title intValue];
    count = count + 1;
    
    __weak CSTaskListViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", count];
    });
}

- (void)decrementConnectedCount:(NSNotification *)notification
{
    int count = [_userConnectionCount.title intValue];
    count = (count == 0) ? 0 : count - 1;
    
    __weak CSTaskListViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", count];
    });
}

#pragma mark - UITableView Delegates
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSTaskRealmModel *task = [[CSTaskRealmModel allObjects]objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"showTaskDetail" sender:task];
}

#pragma mark - UITableViewDataSource Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"CSTaskTableItem";
    CSTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[CSTaskTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:simpleTableIdentifier];
    }
    
//    CSTaskRealmModel *task = [_taskManager.currentTaskList objectAtIndex:indexPath.row];
    RLMResults* results = [CSTaskRealmModel allObjects];
    CSTaskRealmModel* task = [results objectAtIndex:indexPath.row];
    
    [cell configureWithSourceTask:task];
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [CSTaskRealmModel allObjects].count;
}

#pragma mark - Task creation view refresh
- (void)didReceiveNewTask:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showTaskDetail"])
    {
        CSTaskDetailViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[CSTaskRealmModel class]])
        {
            [vc setSourceTask:sender];
        }
    }
}


@end
