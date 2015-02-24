//
//  SlackTestViewController.m
//  CommSync
//
//  Created by Darin Doria on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "SlackTestViewController.h"
#import "AppDelegate.h"
#import "CSChatMessageRealmModel.h"
#import "CSChatTableViewCell.h"
#import <Realm/Realm.h>

#define kChatTableViewCellIdentifier @"ChatViewCell"

@interface SlackTestViewController ()
// use this realm object to persist data to disk
@property (strong, nonatomic) RLMRealm *chatRealm;
// session manager to send data to connected peers
@property (strong, nonatomic) CSSessionManager *sessionManager;
@end

@implementation SlackTestViewController
{
    RLMNotificationToken *_chatRealmNotification;
    NSString *_currentUser;
}

#pragma mark - Init Methods
- (id)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        // Register a subclass of SLKTextView, if you need any special appearance and/or behavior customisation.
    }
    return self;
}


#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     * Get a reference to the app delegate
     */
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _currentUser = app.userDisplayName;
    
    if(_sourceTask == nil){
        _chatRealm = [RLMRealm realmWithPath:[SlackTestViewController chatMessageRealmDirectory]];
        _chatRealm.autorefresh = YES;
    }
    
    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
    
    /**
     * Get a copy of the session manager
     */
    self.sessionManager = app.globalSessionManager;
    
    /**
     *  Register to use custom table view cells
     */
    [self.tableView registerNib:[UINib nibWithNibName:@"CSChatTableViewCell" bundle:nil] forCellReuseIdentifier:kChatTableViewCellIdentifier];
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    /**
     *  Register for chat realm notifications
     */
    [self registerForChatRealmNotifications];
}

#pragma mark - Override SlackViewController Methods
- (void)didPressRightButton:(id)sender
{
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
    UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
    
   
    [self.tableView beginUpdates];
    
    if(!_sourceTask){
        CSChatMessageRealmModel *message = [[CSChatMessageRealmModel alloc] initWithMessage:[self.textView.text copy] byUser:_currentUser];
    
        [self.chatRealm beginWriteTransaction];
        [self.chatRealm addObject:message];
        [self.chatRealm commitWriteTransaction];
        
        NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
        [self.sessionManager sendDataPacketToPeers:messageData];
    }
    
    else{
        //creates comment
        CSCommentRealmModel *comment = [[CSCommentRealmModel alloc] initWithMessage:[self.textView.text copy] byUser:_currentUser];
        //stores comment and reloads screen to show comment
        [_sourceTask addComment:comment];
    }
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
    [self.tableView endUpdates];

    
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
    
    // Fixes the cell from blinking (because of the transform, when using translucent cells)
    // See https: //github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [super didPressRightButton:sender];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!_sourceTask){
        if (!_chatRealm)
        {
            _chatRealm = [RLMRealm realmWithPath:[SlackTestViewController chatMessageRealmDirectory]];
        }
    
        return [[CSChatMessageRealmModel allObjectsInRealm:_chatRealm] count];
    }
    else{
        return [_sourceTask.comments count];
    }
}

- (CSChatTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellIdentifier = @"ChatViewCell";
    CSChatTableViewCell *cell = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[CSChatTableViewCell alloc] init];
    }
    
    if(!_sourceTask){
        CSChatMessageRealmModel *msg = [self chatObjectAtIndex:indexPath.item];
    
        cell.createdByLabel.text = msg.createdBy;
        cell.messageLabel.text = msg.text;
        cell.transform = self.tableView.transform;
    }
    
    else{
        CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex: ([_sourceTask.comments count] - (indexPath.row  + 1) )];
        cell.createdByLabel.text = comment.UID;
        cell.messageLabel.text = comment.text;
        cell.transform = self.tableView.transform;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

#pragma mark - Helper Methods
+ (NSString *)chatMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/chat.realm"];
}

- (void)registerForChatRealmNotifications
{
    if(!_sourceTask){
        __weak SlackTestViewController *weakSelf = self;
        _chatRealmNotification = [_chatRealm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            
                // Scroll to the bottom so we focus on the latest message
                NSUInteger numberOfRows = [weakSelf.collectionView numberOfItemsInSection:0];
                if (numberOfRows) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRows-1 inSection:0];
                    [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }
            });
        }];
    }
}

- (CSChatMessageRealmModel *)chatObjectAtIndex:(NSUInteger)index
{
    RLMResults *orderedChatMessages = [[CSChatMessageRealmModel allObjectsInRealm:_chatRealm] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    return [orderedChatMessages objectAtIndex:index];
}

@end
