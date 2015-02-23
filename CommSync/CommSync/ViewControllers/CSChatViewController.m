//
//  CSChatViewController.m
//  CommSync
//
//  Created by Darin Doria on 2/11/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSChatViewController.h"
#import "CSChatMessageRealmModel.h"
#import "AppDelegate.h"

@interface CSChatViewController ()
@property (strong, nonatomic) IBOutlet UIView *messageToolbar;
@property (strong, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (strong, nonatomic) IBOutlet UITextField *messageTextField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomLayoutConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomLayoutConstraint;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) CSSessionManager* sessionManager;


// Realm data persistence and UI ties
@property (strong, nonatomic) RLMRealm *chatRealm;
@end

@implementation CSChatViewController
{
    RLMNotificationToken* _chatRealmNotification;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // get global managers
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = app.globalSessionManager;
    
    _sendMessageButton.enabled = NO;
    
    // Setup chat realm
    _chatRealm = [RLMRealm realmWithPath:[CSChatViewController chatMessageRealmDirectory]];
    _chatRealm.autorefresh = YES;
    
    [self registerForChatRealmNotifications];
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[RLMRealm defaultRealm] removeNotification:_chatRealmNotification];
}

#pragma mark - Private Class Methods
- (void)registerForChatRealmNotifications
{
    __weak CSChatViewController *weakSelf = self;
    _chatRealmNotification = [_chatRealm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            
            // Scroll to the bottom so we focus on the latest message
            NSUInteger numberOfRows = [weakSelf.tableView numberOfRowsInSection:0];
            if (numberOfRows) {
                [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(numberOfRows - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        });
    }];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(KeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

- (IBAction)sendMessageAction:(id)sender
{
    // get message contents
    NSString *messageContent = _messageTextField.text;
    NSString *me = [[UIDevice currentDevice] name];
    
    // create chat message object
    CSChatMessageRealmModel *m = [[CSChatMessageRealmModel alloc] initWithMessage:messageContent byUser:me];
    
    // write message to local storage
    [_chatRealm beginWriteTransaction];
    [_chatRealm addObject:m];
    [_chatRealm commitWriteTransaction];
    
    // clear text field
    [_messageTextField setText:@""];
    
    // encode message object as NSData
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:m];
    
    // send data to everyone in session
    [_sessionManager sendDataPacketToPeers:messageData];
    
    // Update the table view
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:([CSChatMessageRealmModel allObjectsInRealm:_chatRealm].count - 1) inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
    
    // Scroll to the bottom so we focus on the latest message
    NSUInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(numberOfRows - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    // disable send button
    _sendMessageButton.enabled = NO;
}


#pragma mark - UITableViewDataSource Methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:simpleTableIdentifier];
    }
    
    RLMResults *orderedChatMessages = [[CSChatMessageRealmModel allObjectsInRealm:_chatRealm] sortedResultsUsingProperty:@"createdAt" ascending:YES];
    
    CSChatMessageRealmModel *message = [orderedChatMessages objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", message.createdBy, message.text];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [CSChatMessageRealmModel allObjectsInRealm:_chatRealm].count;
}


#pragma mark - UITextfieldDelegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_messageTextField resignFirstResponder];
    return YES;
}

// Override to dynamically enable/disable the send button based on user typing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger length = self.messageTextField.text.length - range.length + string.length;
    if (length > 0)
        self.sendMessageButton.enabled = YES;
    else
        self.sendMessageButton.enabled = NO;

    return YES;
}


#pragma mark - Keyboard Notifications
- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    NSLog(@"Keyboard will show");
    [self moveToolBarUp:YES forKeyboardNotification:notification];
}

- (void)KeyboardWillHideNotification:(NSNotification *)notification
{
    NSLog(@"Keyboard will hide show");
    [self moveToolBarUp:NO forKeyboardNotification:notification];
}

#pragma mark - Animation Helper
// Helper method for moving the toolbar frame based on user action
- (void)moveToolBarUp:(BOOL)up forKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSInteger animDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    

    if (up)
    {
        CGRect keyboardEndFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect keyboardFrame = [[UIApplication sharedApplication].keyWindow convertRect:keyboardEndFrame fromView:self.view];

        CGSize keyboardSize = keyboardFrame.size;
        CGRect activeRect = [self.view convertRect:_messageTextField.frame fromView:self.view];
        CGRect rect = self.view.bounds;
        rect.size.height -= (keyboardSize.height);
        
        CGPoint origin = activeRect.origin;
        origin.y -= _tableView.contentOffset.y;
        
        if (!CGRectContainsPoint(rect, origin))
        {
            CGPoint scrollPoint = CGPointMake(0.0,CGRectGetMaxY(activeRect)-(rect.size.height));
            [_tableView setContentOffset:scrollPoint animated:YES];
        }
        
        //animate view moving uop
        [self.view layoutIfNeeded];
        _toolbarBottomLayoutConstraint.constant = keyboardSize.height-50.0f;

        [UIView animateWithDuration:animDuration animations:^{
            [self.view layoutIfNeeded];
        }];

        
    } else {
        [self.view layoutIfNeeded];
        _toolbarBottomLayoutConstraint.constant = 0;
        [UIView animateWithDuration:animDuration animations:^{
            [self.view layoutIfNeeded];
        }];
    }
 
}

#pragma mark - Realm Helper Method
+ (NSString *)chatMessageRealmDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:@"/chat.realm"];
}

@end






