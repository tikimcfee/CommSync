//
//  SlackTestViewController.m
//  CommSync
//
//  Created by Darin Doria on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSChatViewController.h"
#import "AppDelegate.h"
#import "CSChatMessageRealmModel.h"
#import "CSUserRealmModel.h"
#import "CSChatTableViewCell.h"
#import "UINavigationBar+CommSyncStyle.h"
#import "UIColor+FlatColors.h"
#import <Realm/Realm.h>

#define kChatTableViewCellIdentifier @"ChatViewCell"

@interface CSChatViewController ()
// use this realm object to persist data to disk
@property (strong, nonatomic) RLMRealm *chatRealm;
@property (strong, nonatomic) RLMRealm *privateMessageRealm;
// session manager to send data to connected peers
@property (strong, nonatomic) CSSessionManager *sessionManager;
@property (strong, nonatomic) NSPredicate *pred;
@end

@implementation CSChatViewController
{
    RLMNotificationToken *_chatRealmNotification;
    RLMNotificationToken *_privateMessageRealmNotification;
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    __weak CSChatViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.tableView reloadData];
    });
}

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     * Get a reference to the app delegate
     */
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    _currentUser = _sessionManager.myUniqueID;
    if(_sourceTask == nil){
        if(!_peerID) {
            _chatRealm = [RLMRealm realmWithPath:[CSChatViewController chatMessageRealmDirectory]];
            _chatRealm.autorefresh = YES;
        }
        else{
            _privateMessageRealm = [RLMRealm realmWithPath:[CSChatViewController privateMessageRealmDirectory]];
            _privateMessageRealm.autorefresh = YES;
            _pred = [NSPredicate predicateWithFormat:@"createdBy = %@ AND recipient = %@ OR createdBy = %@ AND recipient = %@", _peerID.uniqueID, _sessionManager.myUniqueID, _sessionManager.myUniqueID, _peerID.uniqueID ];
        }
    }
    
    else{
        
        _privateMessageRealm = [RLMRealm realmWithPath:[CSChatViewController privateMessageRealmDirectory]];
        _privateMessageRealm.autorefresh = YES;
        _pred = [NSPredicate predicateWithFormat:@"recipient = %@", _sourceTask.UUID];

    }
    
    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
   
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
    
    /*
     *  Remove cell view separator
     */
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    /*
     *  Set navigation bar style
     */
    [self.navigationController.navigationBar setupCommSyncStyle];
    
    if (!_sourceTask && _peerID) {
        UINavigationBar *bar = [UINavigationBar new];
        [bar setFrame:CGRectMake(0, 0, self.view.frame.size.width, 32)];
        [bar setupCommSyncStyle];
        
        UILabel *barLabel = [UILabel new];
        [barLabel setFrame:CGRectMake(self.view.frame.size.width/2- 45.0, 8, 150.0, 20.0)];
        [barLabel setText: @"Private Chat"];
        [barLabel setTextColor:[UIColor whiteColor]];
        
        [bar addSubview:barLabel];
        [self.view addSubview:bar];
    }
    
    if(_peerID){
        //reset private messages
        [self.sessionManager.peerHistoryRealm beginWriteTransaction];
        [self.peerID removeMessages];
        [self.sessionManager.peerHistoryRealm commitWriteTransaction];
    }
}

#pragma mark - Override SlackViewController Methods
- (void)didPressRightButton:(id)sender
{
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
    UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
    
    [self.tableView beginUpdates];
    
    if(!_sourceTask){
        CSChatMessageRealmModel *message = [[CSChatMessageRealmModel alloc] initWithMessage:[self.textView.text copy] byUser:_currentUser toUser:(_peerID)? _peerID.uniqueID : @"ALL"];
        
        if (_peerID){
            [_privateMessageRealm beginWriteTransaction];
            [_privateMessageRealm addObject:message];
            [_privateMessageRealm commitWriteTransaction];
            
            //the user is not currently connected so add it to unsent message
//            if(![_sessionManager.currentConnectedPeers valueForKey:_peerID.uniqueID])
//            {
//                [_sessionManager.peerHistoryRealm beginWriteTransaction];
//                [_peerID addUnsent];
//                [_sessionManager.peerHistoryRealm commitWriteTransaction];
//            }
//            else {
                NSDictionary *dataToSend = @{@"PrivateMessage"  :   message};
                NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
                //If we are directly connected send them the message
              /*  if ([_sessionManager synchronizedPeerRetrievalForDisplayName:_peerID.displayName])
                {
                    //the user is connected to the target so we can send it directly
                    [_sessionManager sendSingleDataPacket:messageData toSinglePeer: [_sessionManager.currentConnectedPeers valueForKey:_peerID.uniqueID]];
                }*/
                //otherwise send it to everyone in hopes it finds the recipient
               // else
                [self.sessionManager sendDataPacketToPeers:messageData];
          //  }
        }
            
        else{
            [_chatRealm beginWriteTransaction];
            [_chatRealm addObject:message];
            [_chatRealm commitWriteTransaction];
            NSDictionary *dataToSend = @{@"ChatMessage"  :   message};
            NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
            [self.sessionManager sendDataPacketToPeers:messageData];
        }
    }
    
    else{
//        //creates comment
//        CSCommentRealmModel *comment = [[CSCommentRealmModel alloc] initWithMessage:[self.textView.text copy] byUser:_currentUser];
//        //stores comment and reloads screen to show comment
//        [_sourceTask addComment:comment];
        CSChatMessageRealmModel *message = [[CSChatMessageRealmModel alloc] initWithMessage:[self.textView.text copy] byUser:_sessionManager.myUniqueID toUser:_sourceTask.UUID];
        [_privateMessageRealm beginWriteTransaction];
        [_privateMessageRealm addObject:message];
        [_privateMessageRealm commitWriteTransaction];
        NSDictionary *dataToSend = @{@"PrivateMessage"  :   message};
        NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:dataToSend];
        [self.sessionManager sendDataPacketToPeers:messageData];
        
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
    //if(!_sourceTask){
    
        
        if (!_chatRealm)
        {
            _chatRealm = [RLMRealm realmWithPath:[CSChatViewController chatMessageRealmDirectory]];
            
        }
        if(!_privateMessageRealm) _privateMessageRealm = [RLMRealm realmWithPath:[CSChatViewController privateMessageRealmDirectory]];
    
    if(_sourceTask) return [[CSChatMessageRealmModel objectsInRealm:_privateMessageRealm withPredicate:_pred] count] ;
        if(!_peerID)return [[CSChatMessageRealmModel allObjectsInRealm:_chatRealm] count];
        
       
        return [[CSChatMessageRealmModel objectsInRealm:_privateMessageRealm withPredicate:_pred] count] ;
        
   // }
   // else{
     //   return [_sourceTask.comments count];
    //}
}

- (CSChatTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"h:mm a"];

    static NSString *cellIdentifier = @"ChatViewCell";
    CSChatTableViewCell *cell = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[CSChatTableViewCell alloc] init];
    }
    
   // if(!_sourceTask){
        
        CSChatMessageRealmModel *msg = [self chatObjectAtIndex:indexPath.item];

        cell.messageLabel.text = msg.messageText;
        cell.transform = self.tableView.transform;
    
        CSUserRealmModel *person = [CSUserRealmModel objectInRealm:_sessionManager.peerHistoryRealm forPrimaryKey:msg.createdBy];
        cell.createdByLabel.text = person.displayName;
        cell.createdAtLabel.text = [format stringFromDate:msg.createdAt];
        NSString *image = [person getPicture];
        [cell.avatarImage setImage:[UIImage imageNamed:image]];
        cell.avatarImage.layer.cornerRadius = cell.avatarImage.frame.size.width / 2;
        
        if ([msg.createdBy isEqualToString:_sessionManager.myUniqueID]) {
            cell.backgroundColor = [[UIColor flatConcreteColor] colorWithAlphaComponent:0.4f];
        }
        else{
            cell.backgroundColor = [UIColor whiteColor];
        }
  //  }
    /*
    else{
        CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex: ([_sourceTask.comments count] - (indexPath.row  + 1) )];
        CSUserRealmModel *person = [CSUserRealmModel objectInRealm:_sessionManager.peerHistoryRealm forPrimaryKey:comment.UID];
        cell.createdByLabel.text = person.displayName;
        cell.messageLabel.text = comment.text;
        cell.createdAtLabel.text = [format stringFromDate:comment.time];
        cell.transform = self.tableView.transform;
        
    } */
    
    return cell;
}

#pragma mark - UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - Helper Methods
+ (NSString *)chatMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/chat.realm"];
}

+ (NSString *)privateMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/privateMessage.realm"];
}

- (void)registerForChatRealmNotifications
{
    if(!_sourceTask){
        
        __weak CSChatViewController *weakSelf = self;
        if(!_peerID){
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
        else{
            
            __weak CSChatViewController *weakSelf = self;
            _privateMessageRealmNotification = [_privateMessageRealm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                    
                    // Scroll to the bottom so we focus on the latest message
                    NSUInteger numberOfRows = [weakSelf.collectionView numberOfItemsInSection:0];
                    if (numberOfRows) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:numberOfRows-1 inSection:0];
                        [weakSelf.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    }
                    //reset private messages
                    [weakSelf.sessionManager.peerHistoryRealm beginWriteTransaction];
                    [weakSelf.peerID removeMessages];
                    [weakSelf.sessionManager.peerHistoryRealm commitWriteTransaction];
                });
            }];
        }
    }
    else{
    __weak CSChatViewController *weakSelf = self;
    _privateMessageRealmNotification = [_privateMessageRealm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        
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
    RLMResults *orderedChatMessages;
    if(_sourceTask)
    {
        orderedChatMessages = [[CSChatMessageRealmModel objectsInRealm:_privateMessageRealm withPredicate:_pred] sortedResultsUsingProperty:@"createdAt" ascending:NO];
        return [orderedChatMessages objectAtIndex:index];
    }
    orderedChatMessages = (!_peerID)? [[CSChatMessageRealmModel allObjectsInRealm:_chatRealm] sortedResultsUsingProperty:@"createdAt" ascending:NO] : [[CSChatMessageRealmModel objectsInRealm:_privateMessageRealm withPredicate:_pred] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    return [orderedChatMessages objectAtIndex:index];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
