//
//  CSPictureViewController.h
//  CommSync
//
//  Created by Anna Stavropoulos on 2/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSPictureViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray* taskImages;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *distanceEdge;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *top;
@property float pictureWidth;

@end
