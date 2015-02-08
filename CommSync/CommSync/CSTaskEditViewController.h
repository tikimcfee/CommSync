//
//  CSTaskEditViewController.h
//  CommSync
//
//  Created by Student on 2/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSTaskEditViewController : UITableViewController
@property (strong, nonatomic) CSTaskRealmModel *sourceTask;

@end
