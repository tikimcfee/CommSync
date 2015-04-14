//
//  CSSimpleTaskDetailViewController.h
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSSimpleTaskDetailViewController : UIViewController

// Views and controls
@property (weak, nonatomic) IBOutlet UITextField *taskTitleTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *taskImageCollectionView;
@property (weak, nonatomic) IBOutlet UITextView *objectTextView;

// Models and data
@property (strong, nonatomic) CSTaskRealmModel* sourceTask;

@end
