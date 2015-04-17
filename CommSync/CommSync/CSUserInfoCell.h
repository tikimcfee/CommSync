//
//  CSUserInfoCell.h
//  CommSync
//
//  Created by Student on 4/15/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSUserInfoCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *avatarIcon;
@property (strong, nonatomic) IBOutlet UILabel *userLabel;
@property (strong, nonatomic) IBOutlet UIView *availableStatus;
@property (strong, nonatomic) IBOutlet UIImageView *envelopePic;
@property (strong, nonatomic) IBOutlet UILabel *unreadNumber;

@end
