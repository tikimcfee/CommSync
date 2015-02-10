//
//  CSTaskDetailViewController.h
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSTaskDetailViewController : UITableViewController
{
    
}

//Header Items
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priorityLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *priorityColor;

//Footer Items
@property (weak, nonatomic) IBOutlet UITextField *commentField;
- (IBAction)addComment:(id)sender;


@property (strong, nonatomic) CSTaskRealmModel *sourceTask;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;
- (IBAction)resfresh:(id)sender;

- (IBAction)editTask:(id)sender;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
@end
