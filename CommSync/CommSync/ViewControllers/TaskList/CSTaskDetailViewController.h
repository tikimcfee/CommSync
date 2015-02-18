//
//  CSTaskDetailViewController.h
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"
#import "CSTaskTransientObjectStore.h"

#import <AVFoundation/AVFoundation.h>

@interface CSTaskDetailViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioPlayerDelegate>
{
    
}

//task objects
@property (strong, nonatomic) CSTaskRealmModel           *sourceTask;
@property (strong, nonatomic) CSTaskTransientObjectStore *transientTask;

//Header Items

@property (weak, nonatomic) IBOutlet UITextField *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priorityLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *priorityColor;

//Footer Items
@property (weak, nonatomic) IBOutlet UITextField *commentField;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBar;
@property (weak, nonatomic) IBOutlet UIView *footerView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConst;



@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIButton *greenButton;
@property (weak, nonatomic) IBOutlet UIButton *yellowButton;
@property (weak, nonatomic) IBOutlet UIButton *redButton;


@property (weak, nonatomic) IBOutlet UIButton *audioButton;

- (IBAction)    playAudio:(id)sender;
- (IBAction)    setRed:(id)sender;
- (IBAction)    setGreen:(id)sender;
- (IBAction)    addComment:(id)sender;
- (IBAction)    setYellow:(id)sender;
- (IBAction)    editMode:(id)sender;
- (void)        setImagesFromTask;
- (void)        keyboardWillHide:(NSNotification *) sender;
- (void)        keyboardDidShow:(NSNotification *) sender;

@end
