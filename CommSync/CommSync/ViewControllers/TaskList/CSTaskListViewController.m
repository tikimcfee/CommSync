//
//  CSTaskViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskListViewController.h"
#import "CSSimpleTaskDetailViewController.h"
#import "CSTaskTableViewCell.h"
#import "CSTaskProgressTableViewCell.h"
#import "CSSessionDataAnalyzer.h"
#import "CSIncomingTaskRealmModel.h"
#import "CSTaskListUpdateOperation.h"
#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import "UINavigationBar+CommSyncStyle.h"
#import "UITabBar+CommSyncStyle.h"
#import "UIColor+FlatColors.h"
#import "IonIcons.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"
#define kNewTaskNotification @"kNewTaskNotification"

typedef NS_ENUM(NSInteger, CSTaskListMode) {
    CSTaskListMode_Open = 0,
    CSTaskListMode_Completed
};

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

// Filtering controls
@property (nonatomic, assign) NSInteger completionToggleIndex;

@property (assign, nonatomic) BOOL willRefreshFromIncomingTask;
@property (strong, nonatomic) NSMutableArray* incomingTasks;
@property (copy, nonatomic) void (^incomingTaskCallback)();
@property (copy, nonatomic) void (^reloadModels)();

@end

@implementation CSTaskListViewController

//static CGFloat TIME_TO_UPDATE = -1;

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    void (^realmNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        weakSelf.incomingTaskCallback();
    };
    
    void (^incomingTaskNotificationBlock)(NSString*, RLMRealm*) = ^void(NSString* note, RLMRealm* rlm) {
        weakSelf.incomingTaskCallback();
    };
    
    // Realms
    _realm = [RLMRealm defaultRealm];
    _realm.autorefresh = YES;
    _incomingTasksRealm = [CSRealmFactory incomingTaskRealm];
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
        RLMRealm* incomingRealm = [CSRealmFactory incomingTaskRealm];
        RLMResults* incoming = [CSIncomingTaskRealmModel allObjectsInRealm:incomingRealm];
        NSMutableArray* tasks = [NSMutableArray new];
        for (CSIncomingTaskRealmModel* task in incoming) {
            [tasks addObject:task.taskObservationString];
        }
        
        RLMRealm* tasksRealm = [RLMRealm defaultRealm];
        NSNumber* completed = weakSelf.completionToggleIndex == 1 ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
        NSPredicate* predicate = (weakSelf.user)?[NSPredicate predicateWithFormat:@"assignedID = %@ AND completed == %@",weakSelf.user, completed]:[NSPredicate predicateWithFormat:@"completed == %@", completed];
        RLMResults* filteredTask = [CSTaskRealmModel objectsInRealm:tasksRealm withPredicate:predicate];
        for (CSTaskRealmModel* task in filteredTask) {
//            [tasks addObject:task.concatenatedID];
            NSString* toAdd = [NSString stringWithFormat:@"%@%@",
                               task.concatenatedID, (task.isDirty == YES ? @".edited":@"")];
            [tasks addObject:toAdd];
        }
        
        TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: tasks];
        weakSelf.indexPathController.dataModel = tasksDataModel;
    };
    
    _incomingTaskCallback = ^void()
    {
        NSTimeInterval time = 0.5;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
    
    [self.tableView setSeparatorColor:[UIColor flatMidnightBlueColor]];
    
    // setup navigation controller style
    [self.navigationController.navigationBar setupCommSyncStyle];
    
    // setup tab bar controller style
    [self.tabBarController.tabBar setupCommSyncStyle];
    
    // toggle callback
    [_completionToggleControl addTarget:self
                                 action:@selector(toggleToNewMode:)
                       forControlEvents:UIControlEventValueChanged];
    _completionToggleIndex = 0;
}

- (void)setupInitialTaskDataModels {
    NSMutableArray* tasks = [NSMutableArray new];
    RLMRealm* tasksRealm = [RLMRealm defaultRealm];
    RLMResults* allTasks = (_user)?[CSTaskRealmModel objectsInRealm:tasksRealm where:@"assignedID = %@",_user] : [CSTaskRealmModel allObjectsInRealm:tasksRealm];
    for (CSTaskRealmModel* task in allTasks) {
        [tasks addObject:task.concatenatedID];
    }
    
    TLIndexPathDataModel* tasksDataModel = [[TLIndexPathDataModel alloc] initWithItems: tasks];
    self.indexPathController = [[TLIndexPathController alloc] initWithDataModel:tasksDataModel];
    self.indexPathController.delegate = self;
}

- (void)registerForNotifications {
    
}

- (void)toggleToNewMode:(id)sender {
    if(_completionToggleControl.selectedSegmentIndex != _completionToggleIndex) {
        _completionToggleIndex = _completionToggleControl.selectedSegmentIndex;
        self.incomingTaskCallback();
    }
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

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Force your tableview margins (this may be a bad idea)
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
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
        CSIncomingTaskRealmModel* model = [CSIncomingTaskRealmModel objectInRealm:[CSRealmFactory incomingTaskRealm]
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
    
    CSIncomingTaskRealmModel* model = [CSIncomingTaskRealmModel objectInRealm:[CSRealmFactory incomingTaskRealm]
                                                                forPrimaryKey:selected];
    if(model) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CSTaskRealmModel *task = (_user)?[CSTaskRealmModel objectsInRealm:[RLMRealm defaultRealm] where:@"assignedID = %@",_user][indexPath.row]:[CSTaskRealmModel objectForPrimaryKey:[self.indexPathController.dataModel itemAtIndexPath:indexPath]];
    [self performSegueWithIdentifier:@"showTaskDetail" sender:task];

}

#pragma mark - UITableViewDataSource Delegates
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* selected;
    @synchronized(_indexPathController.dataModel) {
        selected = [_indexPathController.dataModel itemAtIndexPath:indexPath];
    }
    
    selected = [[selected componentsSeparatedByString:@".edited"] objectAtIndex:0];
    
    CSIncomingTaskRealmModel* incomingTask = [CSIncomingTaskRealmModel objectInRealm:[CSRealmFactory incomingTaskRealm] forPrimaryKey:selected];
    CSTaskRealmModel* task = (_user)?[CSTaskRealmModel objectsInRealm:[RLMRealm defaultRealm] where:@"assignedID = %@",_user][indexPath.row]:[CSTaskRealmModel objectForPrimaryKey:selected];
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
        CSSimpleTaskDetailViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[CSTaskRealmModel class]])
        {
            [vc setSourceTask:sender];
        }
    }
}


//// The number of columns of data
//- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
//{
//    return 1;
//}
// The number of rows of data
//- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
//{
//    return [_tags count];
//}
//
//// The data to return for the row and component (column) that's being passed in
//- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return _tags[row];
//}
//
//
//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
//{
//    if(row == 0) _tag = nil;
//    else if (row == 1) _tag = @"";
//    else _tag = _tags[row];
//    
//    [self setupInitialTaskDataModels];
//    [self.tableView reloadData];
//}
//
//- (IBAction)completionFilter:(id)sender {
//    _completed = !_completed;
//    
//    if(_completed) [_completedLabel setText:@"Completed"];
//    else [_completedLabel setText:@"In Progress"];
//    [self setupInitialTaskDataModels];
//    [self.tableView reloadData];
//}

//-(void) setTagFilter{
//    
//    if(!_tags){
//        
//         for( CSTaskRealmModel *temp in [CSTaskRealmModel allObjectsInRealm:[RLMRealm defaultRealm]])
//        {
//            [_sessionManager addTag: temp.tag];
//        }
//    }
//        _tags = [[NSMutableArray alloc] init];
//        
//        [_tags addObject:@"All Tasks"];
//        [_tags addObject:@"Untagged Tasks"];
//        [_tags addObjectsFromArray:_sessionManager.allTags.allKeys];
//}
@end
