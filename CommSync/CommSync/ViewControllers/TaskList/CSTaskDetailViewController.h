//
//  CSTaskDetailViewController.h
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSTaskDetailViewController : UIViewController
{
    IBOutlet UITableView *tableView;
}
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) CSTaskRealmModel *sourceTask;
@property (weak, nonatomic) IBOutlet UILabel *IDLabel;


@end
