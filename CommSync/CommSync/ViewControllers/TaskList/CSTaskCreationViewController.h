//
//  CSTaskCreationViewController.h
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"
#import "CSUserSelectionViewController.h"

@interface CSTaskCreationViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, CSAssignUserDelegate>
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;

@end