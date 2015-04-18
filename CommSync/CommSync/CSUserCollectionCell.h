//
//  CSUserCollection.h
//  CommSync
//
//  Created by Anna Stavropoulos on 4/17/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSUserCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mailImage;
@property (weak, nonatomic) IBOutlet UILabel *unreadNumber;
@property (weak, nonatomic) IBOutlet UIView *innerView;
@end
