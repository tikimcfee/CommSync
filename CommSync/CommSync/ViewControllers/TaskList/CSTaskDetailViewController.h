//
//  CSTaskDetailViewController.h
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSTaskDetailViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    
}

//Header Items
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priorityLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *priorityColor;

//Footer Items
@property (weak, nonatomic) IBOutlet UITextField *commentField;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *footerView;

@property (strong, nonatomic) CSTaskRealmModel *sourceTask;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConst;

- (IBAction)addComment:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *headerView;
- (IBAction)editTask:(id)sender;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;

-(void)keyboardWillHide:(NSNotification *) sender;
-(void)keyboardDidShow:(NSNotification *) sender;


@end
