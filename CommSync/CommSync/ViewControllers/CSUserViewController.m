//
//  CSUserViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSUserViewController.h"
#import "AppDelegate.h"

@interface CSUserViewController ()
{
    
}
@property (strong, nonatomic) CSSessionManager* sessionManager;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *userConnectionCount;

@end

@implementation CSUserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"Loaded user view!");
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = d.globalSessionManager;
    NSInteger connectionCount = [_sessionManager.currentConnectedPeers count];
    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConnectionCountAndTableView:)
                                                 name:@"PEER_CHANGED_STATE"
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"PEER_CHANGED_STATE"
                                                  object:nil];
}

- (void)updateConnectionCountAndTableView:(NSNotification *)notification
{
    __weak CSUserViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger connectionCount = [_sessionManager.currentConnectedPeers count];
        weakSelf.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)connectionCount];
        [weakSelf.tableView reloadData];
    });
}


#pragma mark - UITableViewDataSource Delegates
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
//    }
    
    NSString* userName = [[_sessionManager.currentConnectedPeers allKeys] objectAtIndex:indexPath.row];
    cell.textLabel.text = userName;
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sessionManager.currentConnectedPeers count];
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
