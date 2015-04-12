//
//  CSUserViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSUserViewController.h"
#import "CSUserDetailView.h"

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
    
    self.app= (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = _app.globalSessionManager;
    


    _navBar.title = ([_sessionManager.unreadMessages count] > 0)? @"Unread Messages" : @"No Unread Messages";
    _connectionCount = [_sessionManager.currentConnectedPeers count];
    
    
    self.userConnectionCount.title = [NSString stringWithFormat:@"%d", (int)_connectionCount];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConnectionCountAndTableView:)
                                                 name:@"PEER_CHANGED_STATE"
                                               object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(checkMessages) userInfo:nil repeats:YES];
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
    
    NSString* userName;
    
    
    if(!_filter){
        userName = [[_sessionManager.currentConnectedPeers allKeys] objectAtIndex:indexPath.row];
    }
    else{
        CSUserRealmModel* user = [CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm][indexPath.row];
        userName = user.displayName;
    }
    
    NSString* connectionStatus = [@"---------" stringByAppendingString:[_sessionManager.currentConnectedPeers valueForKey:userName]? @"Connected" : @"Disconnected"];
    
    
    CSUserRealmModel* user = [CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"displayName = %@", userName][0];
    
    cell.text =  _filter ? [userName stringByAppendingString:connectionStatus]: [userName stringByAppendingString: user.getMessageNumber];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CSUserRealmModel *peer;
    
    if(!_filter){
      MCPeerID *peerName = [[_sessionManager.currentConnectedPeers allValues] objectAtIndex:indexPath.row];
        peer = [CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"displayName = %@", peerName.displayName][0];
    }
    else peer = [CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm][indexPath.row];
    
    [self performSegueWithIdentifier:@"showUserDetail" sender:peer];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!_filter) return [_sessionManager.currentConnectedPeers count];
    return [[CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm] count];
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
        if ([sender isKindOfClass:[CSUserRealmModel class]])
        {
            [vc setPeer:sender];
        }
    }
}

-(void) checkMessages
{
    dispatch_async(_app.realmQueue, ^{
    _navBar.title = ([[CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"unreadMessages > %d",0 ] count] > 0)?  @"Unread Messages" : @"No Unread Messages";
        });
    [self.tableView reloadData];
}

@end
