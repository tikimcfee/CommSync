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
#import "CSTaskProgressTableViewCell.h"
#import "CSTaskTransientObjectStore.h"
#import "CSSessionDataAnalyzer.h"
#import "AppDelegate.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"
#define kNewTaskNotification @"kNewTaskNotification"

@interface CSTaskListViewController () <TLIndexPathControllerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *userConnectionCount;
@property (strong, nonatomic) CSSessionManager* sessionManager;

// Realm data persistence and UI ties
@property (strong, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) RLMNotificationToken* updateUIToken;

// New incoming and non-complete task transfers
@property (strong, nonatomic) TLIndexPathController* indexPathController;
@property (assign, nonatomic) BOOL willRefreshFromIncomingTask;
@property (strong, nonatomic) NSMutableArray* incomingTasks;
@property (copy, nonatomic) void (^incomingTaskCallback)(CSTaskProgressTableViewCell*);

@end

@implementation CSTaskListViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    
    __weak typeof(self) weakSelf = self;
    void (^realmNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if(!weakSelf.willRefreshFromIncomingTask)
                [weakSelf reloadDataModels];
        });
    };
    
    _updateUIToken = [[RLMRealm defaultRealm] addNotificationBlock:realmNotificationBlock];
    
    [super viewDidLoad];
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    
    // get connection count
//    NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count]; // subtract 1 to account for yourself
//    NSLog(@"%@", _sessionManager.currentSession.connectedPeers);
    
    
    // Realms
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    
    // set connection count
//    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
    
    // Notification registrations
    [self registerForNotifications];
    
    // Incoming task execution block
    _incomingTaskCallback = ^void(CSTaskProgressTableViewCell* sourceData)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [weakSelf.incomingTasks removeObject:sourceData];
            [weakSelf reloadDataModels];
        });
    };;
    
    // Initialize storage
    self.incomingTasks = [NSMutableArray new];
    [self setupInitialTaskDataModels];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)setupInitialTaskDataModels {
    
    NSMutableArray* tasks = [CSTaskRealmModel getTransientTaskList];
    
    TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: tasks];
//    _mainTasksDataModel = tasksDataModel;
    
    self.indexPathController = [[TLIndexPathController alloc] initWithDataModel:tasksDataModel];
    self.indexPathController.delegate = self;
}

- (void)reloadDataModels {
    NSMutableArray* newDataModel = [CSTaskRealmModel getTransientTaskList];
    [newDataModel addObjectsFromArray:_incomingTasks];
    
    TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: newDataModel];
    _indexPathController.dataModel = tasksDataModel;
    if(self.willRefreshFromIncomingTask)
        self.willRefreshFromIncomingTask = NO;
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
    [super viewWillAppear:animated];
//    [self.tableView reloadData];
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
//    __weak CSTaskListViewController *weakSelf = self;
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count];
//        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
//        [weakSelf.tableView reloadData];
//    });
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
    id dataSource = [self.indexPathController.dataModel itemAtIndexPath:indexPath];
    
    if ([dataSource isKindOfClass:[CSTaskTransientObjectStore class]]) {
        CSTaskTransientObjectStore* ref = (CSTaskTransientObjectStore*)dataSource;
        
        static NSString *simpleTableIdentifier = @"CSTaskTableItem";
        CSTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        [cell configureWithSourceTask:ref.BACKING_DATABASE_MODEL];
        
        return cell;
    }
    
    else if([dataSource isKindOfClass:[CSTaskProgressTableViewCell class]]) {
        
        return dataSource;
    }
    
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.indexPathController.dataModel numberOfRowsInSection:section];
}

#pragma mark - Task creation view refresh
- (void)didReceiveNewTask:(NSNotification*)notification
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.tableView reloadData];
//    });
}

- (void)newTaskStreamStarted:(NSNotification*)notification {
    
    NSDictionary* info = notification.userInfo;
    CSNewTaskResourceInformationContainer* container = [info valueForKey:kCSNewTaskResourceInformationContainer];
    
    NSMutableArray* newArray = [NSMutableArray arrayWithArray:self.indexPathController.items];
    
    static NSString *simpleTableIdentifier = @"CSTaskProgressTableViewCell";
    CSTaskProgressTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    [cell configureWithSourceInformation:container];
    cell.progressCompletionBlock = _incomingTaskCallback;
    
    [newArray addObject:cell];
    [_incomingTasks addObject:cell];
    
    TLIndexPathDataModel* newModel = [[TLIndexPathDataModel alloc] initWithItems:newArray];
    self.indexPathController.dataModel = newModel;
    
     _willRefreshFromIncomingTask = YES;
}

- (void)newTaskStreamUpdated:(NSNotification*)notification {
//    NSDictionary* info = notification.userInfo;
//    NSString* name = ((MCPeerID*)[info valueForKey:@"peerID"]).displayName;
}

- (void)newTaskStreamFinished:(NSNotification*)notification {
//    NSDictionary* info = notification.userInfo;
//    NSURL* location = (NSURL*)[info valueForKey:@"localURL"];
//    
//    NSData* taskData = [NSData dataWithContentsOfURL:location];
//    id newTask = [NSKeyedUnarchiver unarchiveObjectWithData:taskData];
//    
//    if([newTask isKindOfClass:[CSTaskTransientObjectStore class]])
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
////            CSTaskRealmModel* newModel = [[CSTaskRealmModel alloc] init];
////            [(CSTaskTransientObjectStore*)newTask setAndPersistPropertiesOfNewTaskObject:newModel inRealm:_realm withTransaction:YES];
//        });
//    }
//
//    [_incomingTasks removeObjectAtIndex:<#(NSUInteger)#>];
}

#pragma mark - TLIndexPathControllerDelegate

- (void)controller:(TLIndexPathController *)controller didUpdateDataModel:(TLIndexPathUpdates *)updates
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [updates performBatchUpdatesOnTableView:self.tableView withRowAnimation:UITableViewRowAnimationFade];
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
