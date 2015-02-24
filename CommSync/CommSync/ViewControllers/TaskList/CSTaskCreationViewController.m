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
    
    UIColor* backgroundColorToSet = nil;
    if (sender == self.lowPriorityButton)
    {
        self.pendingTask.taskPriority = CSTaskPriorityLow;
        backgroundColorToSet = [self blendColor:[UIColor whiteColor]
                                      WithColor:self.lowPriorityButton.backgroundColor
                                          alpha:0.5];
    }
    else if (sender == self.mediumPriorityButton)
    {
        self.pendingTask.taskPriority = CSTaskPriorityMedium;
        backgroundColorToSet = [self blendColor:[UIColor whiteColor]
                                      WithColor:self.mediumPriorityButton.backgroundColor
                                          alpha:0.5];
    }
    else
    {
        self.pendingTask.taskPriority = CSTaskPriorityHigh;
        backgroundColorToSet = [self blendColor:[UIColor whiteColor]
                                      WithColor:self.highPriorityButton.backgroundColor
                                          alpha:0.5];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = backgroundColorToSet;
    }];
}

- (UIColor*)blendColor:(UIColor*)color1 WithColor:(UIColor*)color2 alpha:(CGFloat)alpha2
{
    alpha2 = MIN( 1.0, MAX( 0.0, alpha2 ) );
    CGFloat beta = 1.0 - alpha2;
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    CGFloat red     = r1 * beta + r2 * alpha2;
    CGFloat green   = g1 * beta + g2 * alpha2;
    CGFloat blue    = b1 * beta + b2 * alpha2;
    CGFloat alpha   = a1 * beta + a2 * alpha2;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
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
