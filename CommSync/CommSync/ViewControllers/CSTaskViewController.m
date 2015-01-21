//
//  CSTaskViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskViewController.h"
#import "AppDelegate.h"

#define kUserNotConnectedNotification @"Not Connected"
#define kUserConnectedNotification @"Connected"
#define kUserConnectingNotification @"Is Connecting"
#define kNewTaskNotification @"Connected"

@interface CSTaskViewController ()
{
    NSArray *tableData;

}
@property (strong, nonatomic) IBOutlet UIBarButtonItem *userConnectionCount;
@property (strong, nonatomic) CSSessionManager* sessionManager;
@property (strong, nonatomic) CSTaskListManager* taskManager;

@end

@implementation CSTaskViewController


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    tableData = [NSArray arrayWithObjects:@"Egg Benedict", @"Mushroom Risotto", @"Full Breakfast", @"Hamburger", @"Ham and Egg Sandwich", @"Creme Brelee", @"White Chocolate Donut", @"Starbucks Coffee", @"Vegetable Curry", @"Instant Noodle with Egg", @"Noodle with BBQ Pork", @"Japanese Noodle with Pork", @"Green Tea", @"Thai Shrimp Cake", @"Angry Birds Cake", @"Ham and Cheese Panini", nil];
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    self.taskManager = app.globalTaskManager;
    
    // get connection count
    NSInteger connectionCount = [_sessionManager.currentSession.connectedPeers count]; // subtract 1 to account for yourself
    
    NSLog(@"%@", _sessionManager.currentSession.connectedPeers);
    
    
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
    
    __weak CSTaskViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", count];
    });
}

- (void)decrementConnectedCount:(NSNotification *)notification
{
    int count = [_userConnectionCount.title intValue];
    count = (count == 0) ? 0 : count - 1;
    
    __weak CSTaskViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", count];
    });
}

#pragma mark - UITableViewDataSource Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    
    CSTask *task = [_taskManager.currentTaskList objectAtIndex:indexPath.row];
    
    cell.textLabel.text = task.taskTitle != nil ? task.taskTitle : task.concatenatedID;
    
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [_taskManager.currentTaskList count];
}

#pragma mark - Task creation view refresh
- (void)didReceiveNewTask:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
