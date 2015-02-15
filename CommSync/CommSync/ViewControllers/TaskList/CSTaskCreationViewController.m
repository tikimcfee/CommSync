//
//  CSTaskCreationViewController.m
//  CommSync
//
//  Created by Darin Doria on 11/6/14.
//  Copyright (c) 2014 AppsByDLI. All rights reserved.
//

#import "CSTaskCreationViewController.h"
#import "CSTaskRealmModel.h"
#import "AppDelegate.h"
#import "UIImage+normalize.h"
#import "CSCommentRealmModel.h"

#import "SZTextView.h"

#import "CSAudioPlotViewController.h"

#import <Realm/Realm.h>

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

@property (weak, nonatomic) RLMRealm* realm;
@property (strong, nonatomic) CSTaskRealmModel *pendingTask;
@end


@implementation CSTaskCreationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    _pendingTask.deviceID = D;
    _pendingTask.concatenatedID = [NSString stringWithFormat:@"%@%@", U, D];
    self.descriptionTextField.placeholder = @"Enter description here...";
}


#pragma mark - IBActions
- (IBAction)addImageToTask:(id)sender {
    
    UIImagePickerController* newPicker = [[UIImagePickerController alloc] init];
    self.imagePicker = newPicker;
    self.imagePicker.allowsEditing = NO;
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
//        [self.pendingTask resetImageDataForTask];
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
        
        NSData* audio = [NSData dataWithContentsOfURL:self.audioRecorder.fileOutputURL];
        NSLog(@"Audio length turned out to be : %ldkb", audio.length / 1024);
    
        NSMutableArray* tempArrayOfImages = [NSMutableArray arrayWithCapacity:self.pendingTask.TRANSIENT_taskImages.count];
            for(UIImage* image in self.pendingTask.TRANSIENT_taskImages) { // for every TRANSIENT UIImage we have on this task
                NSData* thisImage = UIImageJPEGRepresentation(image, 0.3); // make a new JPEG data object with some compressed size
                [tempArrayOfImages addObject:thisImage]; // add it to our container
            }
    
        NSData* archivedImages = [NSKeyedArchiver archivedDataWithRootObject:tempArrayOfImages]; // archive the data ...
        self.pendingTask.taskImages_NSDataArray_JPEG = archivedImages; // and set the images of this task to the new archive
    
        [_realm beginWriteTransaction];
        [_realm addObject:self.pendingTask];
        [_realm commitWriteTransaction];
    
    
    
    AppDelegate *d = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [d.globalSessionManager sendDataPacketToPeers:[NSKeyedArchiver archivedDataWithRootObject:self.pendingTask]];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"CSAudioPlotViewController"]) {
        self.audioRecorder = (CSAudioPlotViewController*)[segue destinationViewController];
        self.audioRecorder.fileNameSansExtension = self.pendingTask.concatenatedID;
    }
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
