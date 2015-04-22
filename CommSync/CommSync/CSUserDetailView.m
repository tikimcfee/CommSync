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
#import "UINavigationBar+CommSyncStyle.h"

@interface CSUserDetailView ()
@property (strong, nonatomic) CSSessionManager* sessionManager;
@end

@implementation CSUserDetailView

- (void)viewDidLoad {
    [super viewDidLoad];
    _topHeight = _topConstraint.constant;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
        // Do any additional setup after loading the view.
    _nameLabel.text = _peerID.displayName;
    _height.constant = self.view.frame.size.height * .49;
    
    AppDelegate* d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = d.globalSessionManager;
    
    NSString *image = [_peer getPicture];
    [self.userAvatarImage setImage:[UIImage imageNamed:image]];
    
    UINavigationBar *bar = [UINavigationBar new];
    [bar setFrame:CGRectMake(0, 0, self.view.frame.size.width, 32)];
    [bar setupCommSyncStyle];
    
    UILabel *barLabel = [UILabel new];
    [barLabel setFrame:CGRectMake(self.view.frame.size.width/2- 45.0, 8, 150.0, 20.0)];
    [barLabel setText: @"Assigned Tasks"];
    [barLabel setTextColor:[UIColor whiteColor]];
    
    [bar addSubview:barLabel];
    [self.view addSubview:bar];
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
        NSLog(@"%@", _peer.displayName);
        CSChatViewController *vc = [segue destinationViewController];
        [vc setPeerID:_peer];
    }
    
    if ([[segue identifier] isEqualToString:@"personalListSegue"])
    {
        CSTaskListViewController *vc = [segue destinationViewController];
        NSLog(_peer.uniqueID);
        [vc setUser:_peer.uniqueID];
    }
    
    
}

//the keyboard shows up
- (void)keyboardWillShow:(NSNotification *)sender {
    _taskLabel.hidden = true;
    _taskContainer.hidden = true;
    _messageLabel.hidden = true;
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    //animate view moving uop
    [self.view layoutIfNeeded];
    _topConstraint.constant = 0;
    _heightConstraint.constant = newFrame.size.height - 90;
    [UIView animateWithDuration:0.3 animations:^{[self.view layoutIfNeeded];}];
}

- (void)keyboardWillHide:(NSNotification *)sender {
    _taskLabel.hidden = false;
    _taskContainer.hidden = false;
    _messageLabel.hidden = false;
    _topConstraint.constant = _topHeight;
    //animate view moving down
    [self.view layoutIfNeeded];
    _heightConstraint.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{[self.view layoutIfNeeded];}];
}
@end
