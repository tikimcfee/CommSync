//
//  CSTaskCreationViewController.m
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//


#import "CSTaskCreationViewController.h"

// Data models
#import <Realm/Realm.h>
#import "CSTaskTransientObjectStore.h"
#import "CSTaskRealmModel.h"
#import "CSCommentRealmModel.h"

// Categories
#import "UIImage+normalize.h"

// UI
#import "SZTextView.h"
#import "CSAudioPlotViewController.h"

// Data transmission
#import "CSSessionDataAnalyzer.h"

@interface CSTaskCreationViewController()

// Main view
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet SZTextView *descriptionTextField;
@property (strong, nonatomic) IBOutlet UIButton *lowPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *mediumPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *highPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *addTaskImageButton;

// Image picker
@property (strong, nonatomic) UIImagePickerController* imagePicker;

// VC for audio recording
@property (weak, nonatomic) CSAudioPlotViewController* audioRecorder;

// Realm
@property (weak, nonatomic) RLMRealm* realm;
//@property (strong, nonatomic) CSTaskRealmModel *pendingTask;
@property (strong, nonatomic) CSTaskTransientObjectStore* pendingTask;

@end


@implementation CSTaskCreationViewController

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"CSAudioPlotViewController"]) {

        [self sharedInit];
        
        self.audioRecorder = (CSAudioPlotViewController*)[segue destinationViewController];
        self.audioRecorder.fileNameSansExtension = self.pendingTask.concatenatedID;
    }
}

- (void)sharedInit
{
    NSString* U = [NSString stringWithFormat:@"%c%c%c%c%c",
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65,
                   arc4random_uniform(25)+65];
    NSString* D = [NSString stringWithFormat:@"%c%c%c%c%c",
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97,
                   arc4random_uniform(25)+97];
    
    _realm = [RLMRealm defaultRealm];
    
    self.pendingTask = [[CSTaskTransientObjectStore alloc] init];
    _pendingTask.UUID = U;
    _pendingTask.deviceID = D;
    _pendingTask.concatenatedID = [NSString stringWithFormat:@"%@%@", U, D];
    
    self.descriptionTextField.placeholder = @"Enter description here...";

}


#pragma mark - IBActions
- (IBAction)addImageToTask:(id)sender {
    
    UIImagePickerController* newPicker = [[UIImagePickerController alloc] init];
    
    self.imagePicker = newPicker;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.delegate = self;
    self.imagePicker.showsCameraControls = YES;
    
    [self presentViewController:newPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    void (^fixImageIfNeeded)(UIImage*) = ^void(UIImage* image) {
        if(!self.pendingTask.TRANSIENT_taskImages) {
            self.pendingTask.TRANSIENT_taskImages = [NSMutableArray new];
        }
        
        [self.pendingTask.TRANSIENT_taskImages addObject:image];
    };
    
    [image normalizedImageWithCompletionBlock:fixImageIfNeeded];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)priorityButtonTapped:(id)sender {
    
    if (sender == self.lowPriorityButton)
    {
        self.pendingTask.taskPriority = CSTaskPriorityLow;
    }
    else if (sender == self.mediumPriorityButton)
    {
        self.pendingTask.taskPriority = CSTaskPriorityMedium;
    }
    else
    {
        self.pendingTask.taskPriority = CSTaskPriorityHigh;
    }
}

- (IBAction)tapGesture:(id)sender {
    [_titleTextField resignFirstResponder];
    [_descriptionTextField resignFirstResponder];
}

- (IBAction)closeViewWithoutSaving:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)closeViewAndSave:(id)sender {

    self.pendingTask.taskTitle = self.titleTextField.text;
    self.pendingTask.taskDescription = self.descriptionTextField.text;
    self.pendingTask.TRANSIENT_audioDataURL = self.audioRecorder.fileOutputURL;
    if(!self.pendingTask.taskAudio && self.pendingTask.TRANSIENT_audioDataURL) {
        self.pendingTask.taskAudio = [NSData dataWithContentsOfURL:self.pendingTask.TRANSIENT_audioDataURL];
    } else {
        self.pendingTask.taskAudio = nil;
    }
    
    self.pendingTask.taskAudio = self.pendingTask.taskAudio ? self.pendingTask.taskAudio : [NSData dataWithContentsOfURL:self.pendingTask.TRANSIENT_audioDataURL];
    
    CSTaskRealmModel* newTask = [[CSTaskRealmModel alloc] init];
    [self.pendingTask setAndPersistPropertiesOfNewTaskObject:newTask inRealm:_realm];
    
    [[CSSessionDataAnalyzer sharedInstance:nil] sendMessageToAllPeersForNewTask:self.pendingTask];

    [self dismissViewControllerAnimated:YES completion:nil];
}



- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
