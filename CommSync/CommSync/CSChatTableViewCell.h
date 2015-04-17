//
//  CSChatTableViewCell.h
//  CommSync
//
//  Created by Darin Doria on 2/23/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSChatTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *createdByLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIImageView *avatarImage;
@end
