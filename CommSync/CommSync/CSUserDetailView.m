//
//  CSUserDetailView.m
//  CommSync
//
//  Created by Anna Stavropoulos on 3/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSUserDetailView.h"
#import "CSChatViewController.h"
#import "CSTaskListViewController.h"
#import "AppDelegate.h"

@interface CSUserDetailView ()
@property (strong, nonatomic) CSSessionManager* sessionManager;
@end

@implementation CSUserDetailView

- (void)viewDidLoad {
    _topHeight = _topConstraint.constant;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
 
    [super viewDidLoad];
        // Do any additional setup after loading the view.
    _nameLabel.text = _peerID.displayName;
    
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = d.globalSessionManager;
    
    NSString *image = [_peer getPicture];
    [self.userAvatarImage setImage:[UIImage imageNamed:image]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"personalChatSegue"])
    {
        NSLog(_peer.displayName);
        CSChatViewController *vc = [segue destinationViewController];
        [vc setPeerID:_peer];
    }
    
    if ([[segue identifier] isEqualToString:@"personalListSegue"])
    {
        CSTaskListViewController *vc = [segue destinationViewController];
        
        [vc setUser:_peerID.displayName];
    }
    
    
}

//the keyboard shows up
- (void)keyboardDidShow:(NSNotification *)sender {
    _taskLabel.hidden = true;
    _taskContainer.hidden = true;
    _messageLabel.hidden = true;
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    //animate view moving uop
    [self.view layoutIfNeeded];
    _heightConstraint.constant = newFrame.size.height - 50;
    _topConstraint.constant = 0;
    [UIView animateWithDuration:0.2 animations:^{[self.view layoutIfNeeded];}];
}

- (void)keyboardWillHide:(NSNotification *)sender {
    _taskLabel.hidden = false;
    _taskContainer.hidden = false;
    _messageLabel.hidden = false;
    _topConstraint.constant = _topHeight;
    //animate view moving down
    [self.view layoutIfNeeded];
    _heightConstraint.constant = 0;
    [UIView animateWithDuration:0.2 animations:^{[self.view layoutIfNeeded];}];
}
@end
