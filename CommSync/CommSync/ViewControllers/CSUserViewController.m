//
//  CSUserViewController.m
//  CommSync
//
//  Created by CommSync on 11/5/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSUserViewController.h"
#import "CSUserDetailView.h"
#import "CSUserInfoCell.h"
#import "UINavigationBar+CommSyncStyle.h"

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
    
    [self.navigationController.navigationBar setupCommSyncStyle];
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
    static NSString *simpleTableIdentifier = @"UserCell";
    
    CSUserInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    CSUserRealmModel* user;
    
    NSString* userName;
    NSString* uniqueID;
    
    if(!_filter){
        uniqueID = [[_sessionManager.currentConnectedPeers allKeys] objectAtIndex:indexPath.row];
        user = [CSUserRealmModel objectInRealm:_sessionManager.peerHistoryRealm forPrimaryKey:uniqueID];
    }
    else{
        user = [CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"uniqueID != %@", _sessionManager.myUniqueID][indexPath.row];
        uniqueID = user.uniqueID;
    }
    
    userName = user.displayName;
    cell.availableStatus.backgroundColor = ([_sessionManager.currentConnectedPeers valueForKey:uniqueID])? [UIColor greenColor]: [UIColor redColor];
    
    cell.userLabel.text = userName;
    [cell.avatarIcon setImage:[UIImage imageNamed:user.getPicture]];
    
    if([user getMessageNumber] == 0){
        [cell.envelopePic setImage:[UIImage imageNamed:@"emptyEnvelope"]];
        [cell.unreadNumber setHidden:TRUE];
    }
    else{
        [cell.envelopePic setImage:[UIImage imageNamed:@"envelope"]];
        [cell.unreadNumber setHidden:FALSE];
        cell.unreadNumber.text = ([user getMessageNumber] <= 9)? [NSString stringWithFormat:@"%d", [user getMessageNumber]] : @"9+";
        cell.unreadNumber.layer.cornerRadius = cell.unreadNumber.frame.size.width / 2;
        cell.unreadNumber.layer.masksToBounds = YES;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CSUserRealmModel *peer;
    
    if(!_filter){
        NSString *peerID = [[_sessionManager.currentConnectedPeers allKeys] objectAtIndex:indexPath.row];
        peer = [CSUserRealmModel objectInRealm:_sessionManager.peerHistoryRealm forPrimaryKey:peerID];
    }
    else peer = [CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"uniqueID != %@", _sessionManager.myUniqueID][indexPath.row];
    [self performSegueWithIdentifier:@"showUserDetail" sender:peer];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!_filter) return [_sessionManager.currentConnectedPeers count];
    return [[CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm] count] - 1;
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
            CSUserRealmModel* temp = sender;
            [vc setPeer:sender];
        }
    }
}

-(void) checkMessages
{
    if(!self)
    {
        return;
    }
    dispatch_sync(_sessionManager.peerHistoryQueue, ^{
    _navBar.title = ([[CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"unreadMessages > %d",0 ] count] > 0)?  @"Unread Messages" : @"No Unread Messages";
    });
    [self.tableView reloadData];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
