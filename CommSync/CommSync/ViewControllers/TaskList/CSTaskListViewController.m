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

// Realm data persistence and UI ties
@property (strong, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) RLMNotificationToken* updateUIToken;

@end

@implementation CSTaskListViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    
    __weak typeof(self) weakSelf = self;
    void (^realmNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    };
    
    _updateUIToken = [[RLMRealm defaultRealm] addNotificationBlock:realmNotificationBlock];
    
    [super viewDidLoad];
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    
    // get connection count
    NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count]; // subtract 1 to account for yourself
    
    NSLog(@"%@", _sessionManager.currentSession.connectedPeers);
    
    
    // Realms
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    
    // set connection count
    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
    
    // Notification registrations
    [self registerForNotifications];
}

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNewTask:)
                                                 name:kNewTaskNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConnectionCountAndTableView:)
                                                 name:@"PEER_CHANGED_STATE"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newTaskStreamStarted:)
                                                 name:kCSDidStartReceivingResourceWithName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newTaskStreamUpdated:)
                                                 name:kCSReceivingProgressNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newTaskStreamFinished:)
                                                 name:kCSDidFinishReceivingResourceWithName
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
                                                    name:kCSDidStartReceivingResourceWithName
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSDidFinishReceivingResourceWithName
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSReceivingProgressNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"lostPeer"
                                                  object:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PEER_CHANGED_STATE"
                                                  object:nil];

    [[RLMRealm defaultRealm] removeNotification:_updateUIToken];
}

- (void)updateConnectionCountAndTableView:(NSNotification *)notification
{
    __weak CSTaskListViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count];
        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
        [weakSelf.tableView reloadData];
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

- (void)newTaskStreamStarted:(NSNotification*)notification {
    
}

- (void)newTaskStreamUpdated:(NSNotification*)notification {
    
}

- (void)newTaskStreamFinished:(NSNotification*)notification {
    
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
