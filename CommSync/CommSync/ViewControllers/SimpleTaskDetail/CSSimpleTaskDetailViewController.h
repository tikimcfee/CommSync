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
#import "CSCustomTapRecognizer.h"
#import "CSAudioPlotViewController.h"
#import "CSUserSelectionViewController.h"

@interface CSSimpleTaskDetailViewController : UIViewController <UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, CSAudioPlotActionDelegate, CSAssignUserDelegate>

// main views and containers
@property (strong, nonatomic) IBOutlet UITableView *tableview;


// Nav bar controls
@property (weak, nonatomic) IBOutlet UIImageView *editIconImageView;
@property (strong, nonatomic) IBOutlet UIImageView *audioPlayImageView;
@property (strong, nonatomic) IBOutlet UIImageView *assigneeImageView;

// Header : Main Task Details and Images
@property (weak, nonatomic) IBOutlet CSInsetTextField *taskTitleTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *taskImageCollectionView;
@property (weak, nonatomic) IBOutlet UITextView *objectTextView;
@property (weak, nonatomic) IBOutlet UIPageControl *dottedPageControl;

// Header : Priority and Completion
@property (strong, nonatomic) IBOutlet UIView *priorityButtonsMainView;
@property (strong, nonatomic) IBOutlet UIView *priorityBarView;
@property (strong, nonatomic) IBOutlet UILabel *priorityTextLabel;
@property (strong, nonatomic) IBOutlet UIButton *lowPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *midPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *highPriorityButton;
@property (strong, nonatomic) IBOutlet UIImageView *checkIconImageView;

// Bottom Sticky Button
@property (strong, nonatomic) IBOutlet UIView *bottomActionButton;
@property (strong, nonatomic) IBOutlet UILabel *bottomActionString;

// Gesture Recognizers
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *completeTaskRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *playAudioRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *backToListRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *editingRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *assigneeRecognizer;

// Models and data
@property (strong, nonatomic) CSTaskRealmModel* sourceTask;

@end

#pragma mark - Lazy and simple table view cell implementations
@interface CSRestOfCommentsTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel* label;
@end