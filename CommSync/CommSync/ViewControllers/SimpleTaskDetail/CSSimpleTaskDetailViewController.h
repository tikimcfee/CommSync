//
//  CSSimpleTaskDetailViewController.h
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"

@interface CSSimpleTaskDetailViewController : UIViewController <UIScrollViewDelegate>

// Views and controls
@property (weak, nonatomic) IBOutlet UITextField *taskTitleTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *taskImageCollectionView;

@property (weak, nonatomic) IBOutlet UITextView *objectTextView;

@property (weak, nonatomic) IBOutlet UIPageControl *dottedPageControl;

// Models and data
@property (strong, nonatomic) CSTaskRealmModel* sourceTask;

@end
