//
//  CSUserDetailView.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface CSUserDetailView : UIViewController
@property (strong, nonatomic) MCPeerID* peerID;
@property (strong, nonatomic) NSString* displayName;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (weak, nonatomic) IBOutlet UIView *taskContainer;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet UIView *messageContainer;
@property int topHeight;
@end
