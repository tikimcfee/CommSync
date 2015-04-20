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
#import "CSTaskRealmModel.h"
#import "CSCommentRealmModel.h"
#import "AppDelegate.h"
#import "CSSessionManager.h"

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
@property (assign, nonatomic) BOOL imageProcessingComplete;

// VC for audio recording
@property (weak, nonatomic) CSAudioPlotViewController* audioRecorder;

// Realm
@property (weak, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) CSTaskRealmModel* pendingTask;

//manager
@property (strong, nonatomic) CSSessionManager *sessionManager;

@end


@implementation CSTaskCreationViewController

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _sessionManager = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).globalSessionManager;
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
    
    self.pendingTask = [[CSTaskRealmModel alloc] init];
    _pendingTask.UUID = U;
    _pendingTask.assignedID = @"";
    _pendingTask.deviceID = D;
    _pendingTask.concatenatedID = [NSString stringWithFormat:@"%@%@", U, D];
    
    self.descriptionTextField.placeholder = @"Enter description here...";
    _imageProcessingComplete = YES;
}


#pragma mark - IBActions
- (IBAction)addImageToTask:(id)sender {
    
    UIImagePickerController* newPicker = [[UIImagePickerController alloc] init];
    
    self.imagePicker = newPicker;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.delegate = self;
    self.imagePicker.showsCameraControls = YES;
    
    self.imageProcessingComplete = NO;
    
    [self presentViewController:newPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    void (^fixImageIfNeeded)(UIImage*) = ^void(UIImage* image) {
        CSTaskMediaRealmModel* newMedia = [[CSTaskMediaRealmModel alloc] init];
        newMedia.mediaType = CSTaskMediaType_Photo;
        
        NSLog(@"New size after normalization only is %ld", (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:image] length]);
        NSData* thisImage = UIImageJPEGRepresentation(image, 0.0); // make a new JPEG data object with some compressed size
        NSLog(@"New size after JPEG compression is %ld", (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:thisImage] length]);
        newMedia.mediaData = thisImage;
        
        [self.pendingTask.taskMedia addObject: newMedia];
        self.imageProcessingComplete = YES;
    };
    
    [image normalizedImageWithCompletionBlock:fixImageIfNeeded];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imageProcessingComplete = YES;
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
    if(_imageProcessingComplete == NO) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Woah there!"
                                                                      message:@"You're fast - give us a sec to finish saving this for you!"
                                                               preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* accept = [UIAlertAction actionWithTitle:@"Got it."
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [alert dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        
        [alert addAction:accept];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if(_audioRecorder.isRecording) {
        [_audioRecorder stopRecording];
    }
    
    self.pendingTask.taskTitle = self.titleTextField.text;
    self.pendingTask.taskDescription = self.descriptionTextField.text;
    self.pendingTask.TRANSIENT_audioDataURL = self.audioRecorder.fileOutputURL;
    self.pendingTask.assignedID = @"Unassigned";
    self.pendingTask.tag = @"";
    self.pendingTask.completed = false;
    if(self.pendingTask.TRANSIENT_audioDataURL) {
        CSTaskMediaRealmModel* newMedia = [[CSTaskMediaRealmModel alloc] init];
        newMedia.mediaType = CSTaskMediaType_Audio;
        newMedia.mediaData = [NSData dataWithContentsOfURL:self.pendingTask.TRANSIENT_audioDataURL];
        [self.pendingTask.taskMedia addObject: newMedia];
    }
    
    [_sessionManager addTag:self.pendingTask.tag];
    
    [_realm beginWriteTransaction];
    [_realm addObject:self.pendingTask];
    [_realm commitWriteTransaction];
    
    [[CSSessionDataAnalyzer sharedInstance:nil] sendMessageToAllPeersForNewTask:self.pendingTask];
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
