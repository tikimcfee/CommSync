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
#import "CSSessionDataAnalyzer.h"
#import "CSTaskListUpdateOperation.h"
#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>

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
@property (nonatomic, assign) BOOL controllerIsVisible;
@property (strong, nonatomic) TLIndexPathController* indexPathController;
@property (strong, nonatomic) NSOperationQueue* tableviewUpdateQueue;

@property (assign, nonatomic) BOOL willRefreshFromIncomingTask;
@property (strong, nonatomic) NSMutableArray* incomingTasks;
@property (copy, nonatomic) void (^incomingTaskCallback)(CSTaskProgressTableViewCell*, TLIndexPathUpdates* precomputedUpdates);
@property (copy, nonatomic) void (^reloadModels)(CSTaskProgressTableViewCell* sourceData);

@end

@implementation CSTaskListViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    
    __weak typeof(self) weakSelf = self;
    void (^realmNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                _incomingTaskCallback(nil, nil);
        });
    };
    
    _updateUIToken = [[RLMRealm defaultRealm] addNotificationBlock:realmNotificationBlock];
    [super viewDidLoad];
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    
    
    // Realms
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    
    // Notification registrations
    [self registerForNotifications];
    
    // Execution blocks and callbacks
    _reloadModels = ^void(CSTaskProgressTableViewCell* sourceData)
    {
        @synchronized (weakSelf.incomingTasks) {
            if(sourceData)
                [weakSelf.incomingTasks removeObject:sourceData];
        }
        
        NSMutableArray* newDataModel = [CSTaskRealmModel getTransientTaskList:weakSelf.user withTag:weakSelf.tag completionStatus:weakSelf.completed];
        @synchronized (weakSelf.incomingTasks) {
            [newDataModel addObjectsFromArray:weakSelf.incomingTasks];
        }

        [weakSelf setTagFilter];
    
        
        TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: newDataModel];
        weakSelf.indexPathController.dataModel = tasksDataModel;
    };
    
    _incomingTaskCallback = ^void(CSTaskProgressTableViewCell* sourceData, TLIndexPathUpdates* precomputedUpdates)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            CSTaskListUpdateOperation* newUpdate = [CSTaskListUpdateOperation new];
            
            newUpdate.updatesToPerform = precomputedUpdates;
            newUpdate.sourceDataToRemove = sourceData;
            newUpdate.tableviewToUpdate = weakSelf.tableView;
            newUpdate.tableviewIsVisible = weakSelf.controllerIsVisible;
            newUpdate.reloadBlock = weakSelf.reloadModels;
            newUpdate.indexPathController = weakSelf.indexPathController;
            newUpdate.name = [NSString stringWithFormat:@"%@-%td", sourceData.sourceTask, weakSelf.tableviewUpdateQueue.operationCount];
        
            [weakSelf.tableviewUpdateQueue addOperation:newUpdate];
        });
    };
    
    // Initialize variables
    self.incomingTasks = [NSMutableArray new];
    self.tableviewUpdateQueue = [NSOperationQueue new];
    self.tableviewUpdateQueue.maxConcurrentOperationCount = 1;
    [self setupInitialTaskDataModels];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    
    [self setTagFilter];
}

- (void)setupInitialTaskDataModels {
    NSMutableArray* tasks = [CSTaskRealmModel getTransientTaskList:_user withTag:_tag completionStatus:_completed];
    
    TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: tasks];

    
    self.indexPathController = [[TLIndexPathController alloc] initWithDataModel:tasksDataModel];
    self.indexPathController.delegate = self;
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _controllerIsVisible = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _controllerIsVisible = YES;
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
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(_indexPathController.dataModel) {
        if([ [_indexPathController.dataModel itemAtIndexPath:indexPath]
            isKindOfClass:[CSTaskProgressTableViewCell class]]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(_indexPathController.dataModel) {
        if([ [_indexPathController.dataModel itemAtIndexPath:indexPath]
            isKindOfClass:[CSTaskProgressTableViewCell class]]) {
            return;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CSTaskRealmModel *task;
    
    if(!_tag && !_user) task = [[CSTaskRealmModel objectsWhere:@"completed = %d",_completed]objectAtIndex:indexPath.row];
    else if(!_user) task = [[CSTaskRealmModel objectsWhere:@"tag = %@ AND completed = %d", _tag, _completed]objectAtIndex:indexPath.row];
    else task = [[CSTaskRealmModel objectsWhere:@"assignedID = %@ AND completed = %d", _user, _completed]objectAtIndex:indexPath.row];

    [self performSegueWithIdentifier:@"showTaskDetail" sender:task];

}

#pragma mark - UITableViewDataSource Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id dataSource = [self.indexPathController.dataModel itemAtIndexPath:indexPath];
    
    if ([dataSource isKindOfClass:[CSTaskRealmModel class]]) {
        CSTaskRealmModel* ref = (CSTaskRealmModel*)dataSource;
        
        static NSString *simpleTableIdentifier = @"CSTaskTableItem";
        CSTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        
        [cell configureWithSourceTask:ref];
        
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
    [_tagFilter reloadAllComponents];
}

- (void)newTaskStreamStarted:(NSNotification*)notification {
    
    NSDictionary* info = notification.userInfo;
    CSNewTaskResourceInformationContainer* container = [info valueForKey:kCSNewTaskResourceInformationContainer];
    
    static NSString *simpleTableIdentifier = @"CSTaskProgressTableViewCell";
    CSTaskProgressTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    [cell configureWithSourceInformation:container];
    cell.progressCompletionBlock = _incomingTaskCallback;

    @synchronized (_incomingTasks) {
        [_incomingTasks addObject:cell];
    }
   
    _incomingTaskCallback(nil, nil);
}

- (void)newTaskStreamUpdated:(NSNotification*)notification {

}

- (void)newTaskStreamFinished:(NSNotification*)notification {
//    _incomingTaskCallback(nil, nil);
}

#pragma mark - TLIndexPathControllerDelegate

- (void)controller:(TLIndexPathController *)controller didUpdateDataModel:(TLIndexPathUpdates *)updates
{
//    _incomingTaskCallback(nil, updates);
    __weak typeof(self) weakSelf = self;
    if(!self.controllerIsVisible) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [updates performBatchUpdatesOnTableView:weakSelf.tableView
                                   withRowAnimation:UITableViewRowAnimationFade
                                         completion:^(BOOL finished) {
//                                             weakSelf.tableviewDidFinishUpdates = YES;
                                         }];
            
        });
    }
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


// The number of columns of data
- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_tags count];
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _tags[row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(row == 0) _tag = nil;
    else if (row == 1) _tag = @"";
    else _tag = _tags[row];
    
    [self setupInitialTaskDataModels];
    [self.tableView reloadData];
}

- (IBAction)completionFilter:(id)sender {
    _completed = !_completed;
    
    if(_completed) [_completedLabel setText:@"Completed"];
    else [_completedLabel setText:@"In Progress"];
    [self setupInitialTaskDataModels];
    [self.tableView reloadData];
}

-(void) setTagFilter{
    
    if(!_tags){
        
         for( CSTaskRealmModel *temp in [CSTaskRealmModel allObjectsInRealm:[RLMRealm defaultRealm]])
        {
            [_sessionManager addTag: temp.tag];
        }
    }
        _tags = [[NSMutableArray alloc] init];
        
        [_tags addObject:@"All Tasks"];
        [_tags addObject:@"Untagged Tasks"];
        [_tags addObjectsFromArray:_sessionManager.allTags.allKeys];
}
@end
