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
#import "CSIncomingTaskRealmModel.h"
#import "CSTaskListUpdateOperation.h"
#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import "UINavigationBar+CommSyncStyle.h"
#import "UITabBar+CommSyncStyle.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"
#define kNewTaskNotification @"kNewTaskNotification"

@interface CSTaskListViewController () <TLIndexPathControllerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *userConnectionCount;
@property (strong, nonatomic) CSSessionManager* sessionManager;

// Realm data persistence and UI ties
//@property (strong, nonatomic) NSString* incomingTaskRealmPath;
@property (strong, nonatomic) RLMRealm* incomingTasksRealm;
@property (strong, nonatomic) RLMRealm* defaultTasksRealm;

@property (strong, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) RLMNotificationToken* updateUIToken;
@property (strong, nonatomic) RLMNotificationToken* incomingUpdateToken;

// New incoming and non-complete task transfers
@property (nonatomic, assign) BOOL controllerIsVisible;
@property (strong, nonatomic) TLIndexPathController* indexPathController;
@property (strong, nonatomic) NSOperationQueue* tableviewUpdateQueue;

@property (assign, nonatomic) BOOL willRefreshFromIncomingTask;
@property (strong, nonatomic) NSMutableArray* incomingTasks;
@property (copy, nonatomic) void (^incomingTaskCallback)();
@property (copy, nonatomic) void (^reloadModels)();

@end

@implementation CSTaskListViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    void (^realmNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            _incomingTaskCallback();
        });
    };
    
    void (^incomingTaskNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            _incomingTaskCallback();
        });
    };
    
    // Realms
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    _incomingTasksRealm = [RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]];
    _incomingTasksRealm.autorefresh = YES;
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    
    _updateUIToken = [_realm addNotificationBlock:realmNotificationBlock];
    _incomingUpdateToken = [_incomingTasksRealm addNotificationBlock:incomingTaskNotificationBlock];
    
    // Notification registrations
    [self registerForNotifications];
    
    // Execution blocks and callbacks
    _reloadModels = ^void()
    {
        RLMRealm* incomingRealm = [RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]];
        RLMResults* incoming = [CSIncomingTaskRealmModel allObjectsInRealm:incomingRealm];
        NSMutableArray* tasks = [NSMutableArray new];
        for (CSIncomingTaskRealmModel* task in incoming) {
//            if (![weakSelf.indexPathController.dataModel containsItem:task.taskObservationString]) {
                [tasks addObject:task.taskObservationString];
//            }
        }
        
        RLMRealm* tasksRealm = [RLMRealm defaultRealm];
        RLMResults* allTasks = [CSTaskRealmModel allObjectsInRealm:tasksRealm];
        for (CSTaskRealmModel* task in allTasks) {
//            if (![weakSelf.indexPathController.dataModel containsItem:task.concatenatedID]) {
                [tasks addObject:task.concatenatedID];
//            }
        }
        
        TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: tasks];
        weakSelf.indexPathController.dataModel = tasksDataModel;
    };
    
    _incomingTaskCallback = ^void()
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            CSTaskListUpdateOperation* newUpdate = [CSTaskListUpdateOperation new];
            
            newUpdate.tableviewToUpdate = weakSelf.tableView;
            newUpdate.tableviewIsVisible = weakSelf.controllerIsVisible;
            newUpdate.reloadBlock = weakSelf.reloadModels;
            newUpdate.indexPathController = weakSelf.indexPathController;
        
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
    
    // setup navigation controller style
    [self.navigationController.navigationBar setupCommSyncStyle];
    
    // setup tab bar controller style
    [self.tabBarController.tabBar setupCommSyncStyle];
}

- (void)setupInitialTaskDataModels {
    NSMutableArray* tasks = [NSMutableArray new];
    RLMRealm* tasksRealm = [RLMRealm defaultRealm];
    RLMResults* allTasks = [CSTaskRealmModel allObjectsInRealm:tasksRealm];
    for (CSTaskRealmModel* task in allTasks) {
        [tasks addObject:task.concatenatedID];
    }
    
    TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: tasks];
    self.indexPathController = [[TLIndexPathController alloc] initWithDataModel:tasksDataModel];
    self.indexPathController.delegate = self;
}

- (void)registerForNotifications {
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[RLMRealm defaultRealm] removeNotification:_updateUIToken];
    [[RLMRealm defaultRealm] removeNotification:_incomingUpdateToken];
}

#pragma mark - UITableView Delegates
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(_indexPathController.dataModel) {
        NSString* selected = [_indexPathController.dataModel itemAtIndexPath:indexPath];
        CSIncomingTaskRealmModel* model = [CSIncomingTaskRealmModel objectInRealm:[RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]]
                                                                    forPrimaryKey:selected];
        if(model) {
            return NO;
        }
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* selected;
    @synchronized(_indexPathController.dataModel) {
        selected = [_indexPathController.dataModel itemAtIndexPath:indexPath];
    }
    
    CSIncomingTaskRealmModel* model = [CSIncomingTaskRealmModel objectInRealm:[RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]]
                                                                forPrimaryKey:selected];
    if(model) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CSTaskRealmModel *task = [CSTaskRealmModel objectForPrimaryKey:[self.indexPathController.dataModel itemAtIndexPath:indexPath]];
    [self performSegueWithIdentifier:@"showTaskDetail" sender:task];

}

#pragma mark - UITableViewDataSource Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* selected;
    @synchronized(_indexPathController.dataModel) {
        selected = [_indexPathController.dataModel itemAtIndexPath:indexPath];
    }
    
    CSIncomingTaskRealmModel* incomingTask = [CSIncomingTaskRealmModel objectInRealm:[RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]]
                                                                       forPrimaryKey:selected];
    CSTaskRealmModel* task = [CSTaskRealmModel objectForPrimaryKey:selected];
    if(incomingTask) {
        // return an incoming task view
        CSTaskProgressTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CSTaskProgressTableViewCell"];
        [cell configureWithIdentifier:selected];
        cell.progressCompletionBlock = _incomingTaskCallback;
        return cell;
    } else if (task) {
        CSTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CSTaskTableItem"];
        [cell configureWithSourceTask:task];
        return cell;
    }

    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.indexPathController.dataModel numberOfRowsInSection:section];
}

#pragma mark - Task creation view refresh

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
