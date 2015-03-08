//
//  CSUserViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSUserViewController.h"
#import "CSUserDetailView.h"
#import "AppDelegate.h"

@interface CSUserViewController ()
{
    
}
@property NSInteger connectionCount;
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

    _connectionCount = [_sessionManager.currentConnectedPeers count];
    
    
    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)_connectionCount];
    
    
    
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
    NSString* userName;
    
    
    if(!_filter){
        userName = [[_sessionManager.currentConnectedPeers allKeys] objectAtIndex:indexPath.row];
    }
    else{
        userName = [[_sessionManager.peerHistory allKeys] objectAtIndex:indexPath.row];
    }
    
    NSString* connectionStatus = [@"--------------" stringByAppendingString:[_sessionManager.currentConnectedPeers valueForKey:userName]? @"Connected" : @"Disconnected"];
    
    cell.textLabel.text = [userName stringByAppendingString:connectionStatus];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MCPeerID *peer;
    
    if(!_filter) peer = [[_sessionManager.peerHistory allValues] objectAtIndex:indexPath.row];
    else peer = [[_sessionManager.currentConnectedPeers allValues] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"showUserDetail" sender:peer];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!_filter) return [_sessionManager.currentConnectedPeers count];
    else return [_sessionManager.peerHistory count];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)FilterPeers:(id)sender {
    if(!_filter){
        _filter = YES;
        [_filterButton setTitle:@"View Online Peers"];
        
    }
    else{
        _filter = NO;
        [_filterButton setTitle:@"View All Peers"];
    }
    __weak CSUserViewController *weakSelf = self;
    [weakSelf.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showUserDetail"])
    {
        CSUserDetailView *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[MCPeerID class]])
        {
            [vc setPeerID:sender];
        }
    }
    
    if ([[segue identifier] isEqualToString:@"showUserDetail"])
    {
        
    }
}

@end
