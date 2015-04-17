//
//  CSSimpleTaskDetailViewController.h
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"
#import <AVFoundation/AVFoundation.h>
#import "CSInsetTextField.h"

@interface CSSimpleTaskDetailViewController : UIViewController <UIScrollViewDelegate,AVAudioPlayerDelegate>

// Views
@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet CSInsetTextField *taskTitleTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *taskImageCollectionView;
@property (weak, nonatomic) IBOutlet UITextView *objectTextView;

@property (strong, nonatomic) IBOutlet UIView *priorityButtonsMainView;
@property (strong, nonatomic) IBOutlet UIView *priorityBarView;
@property (strong, nonatomic) IBOutlet UILabel *priorityTextLabel;

@property (strong, nonatomic) IBOutlet UIView *audioPlayerContainer;
@property (strong, nonatomic) IBOutlet UIImageView *audioPlayImageView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *playAudioRecognizer;
@property (strong, nonatomic) IBOutlet UIImageView *backToListImageView;


// Controls
@property (weak, nonatomic) IBOutlet UIPageControl *dottedPageControl;
@property (weak, nonatomic) IBOutlet UIImageView *editIconImageView;
@property (strong, nonatomic) IBOutlet UIButton *lowPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *midPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *highPriorityButton;


// Models and data
@property (strong, nonatomic) CSTaskRealmModel* sourceTask;

@end
