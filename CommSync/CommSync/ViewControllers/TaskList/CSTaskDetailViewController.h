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
#import "CSPictureViewController.h"
#import "SZTextView.h"
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"

@interface CSTaskDetailViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioPlayerDelegate, UITextFieldDelegate>
{
    
}
@property (weak, nonatomic) IBOutlet UIView *plot;

//task objects
@property (strong, nonatomic) CSTaskRealmModel               *sourceTask;
@property (strong, nonatomic) CSTaskTransientObjectStore     *transientTask;
@property (weak, nonatomic) IBOutlet CSPictureViewController *embed;
//Header Items

@property (weak, nonatomic) IBOutlet UITextField        *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel            *priorityLabel;
@property (weak, nonatomic) IBOutlet SZTextView         *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel            *priorityColor;


@property (weak, nonatomic) IBOutlet UINavigationItem   *navigationBar;
@property (weak, nonatomic) IBOutlet UIView             *footerView;
@property (weak, nonatomic) IBOutlet UITableView        *tableView;
@property (weak, nonatomic) IBOutlet UIView             *headerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem    *editButton;
@property (weak, nonatomic) IBOutlet UIButton           *greenButton;
@property (weak, nonatomic) IBOutlet UIButton           *yellowButton;
@property (weak, nonatomic) IBOutlet UIButton           *redButton;

@property (weak, nonatomic) IBOutlet UIButton           *audioButton;
@property (weak, nonatomic) IBOutlet UIView             *audioContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerWidth;
@property (strong, nonatomic) AppDelegate* app;
- (IBAction)    playAudio:(id)sender;
- (IBAction)    setRed:(id)sender;
- (IBAction)    setGreen:(id)sender;
- (IBAction)    setYellow:(id)sender;
- (IBAction)    editMode:(id)sender;
- (IBAction)    addPicture:(id)sender;
- (IBAction)    completeTask:(id)sender;
- (void)        setImagesFromTask;

@end
