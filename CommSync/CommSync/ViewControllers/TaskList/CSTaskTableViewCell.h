//
//  CSTaskTableViewCell.h
//  CommSync
//
//  Created by Darin Doria on 1/22/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTask.h"

@interface CSTaskTableViewCell : UITableViewCell
@property (weak, nonatomic) CSTask *sourceTask;

- (void)configureWithSourceTask:(CSTask *)task;
@end