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
#import "CSPictureController.h"
#import "IonIcons.h"
#import "UIColor+FlatColors.h"
#import "UINavigationBar+CommSyncStyle.h"
#import "CSTaskImageCollectionViewCell.h"

// Data transmission
#import "CSSessionDataAnalyzer.h"


#define kTaskImageCollectionViewCell @"TaskImageCollectionViewCell"

@interface CSTaskCreationViewController() 

// Main view
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet SZTextView *descriptionTextField;

@property (strong, nonatomic) IBOutlet UIButton *lowPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *mediumPriorityButton;
@property (strong, nonatomic) IBOutlet UIButton *highPriorityButton;

@property (strong, nonatomic) IBOutlet UIButton *addTaskImageButton;

// Image picker
@property (strong, nonatomic) UIImagePickerController* imagePicker;
@property (assign, nonatomic) BOOL imageProcessingComplete;
@property (strong, nonatomic) IBOutlet UICollectionView *taskImageCollection;
@property (strong, nonatomic) NSMutableArray* taskImages;


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
    
    self.taskImageCollection.dataSource = self;
    self.taskImageCollection.delegate = self;
    self.taskImages = [NSMutableArray new];
    
    self.view.backgroundColor = [UIColor flatCloudsColor];
    self.descriptionTextField.backgroundColor = [UIColor flatCloudsColor];
    
    self.addTaskImageButton.layer.cornerRadius = 22.0f;
    self.addTaskImageButton.backgroundColor = [UIColor flatWetAsphaltColor];
    [self.addTaskImageButton setImage:[IonIcons imageWithIcon:ion_ios_camera size:35.0f color:[UIColor flatCloudsColor]] forState:UIControlStateNormal];
    
    [self.navigationBar setupCommSyncStyle];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"CSAudioPlotViewController"]) {

        [self sharedInit];
        
        self.audioRecorder = (CSAudioPlotViewController*)[segue destinationViewController];
        self.audioRecorder.fileNameSansExtension = self.pendingTask.concatenatedID;
    } else if ([segue.identifier isEqualToString:@"enlargedPictureController"]) {
        CSPictureController* picture = segue.destinationViewController;
        picture.taskImage = sender;
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
    
    [self.taskImages addObject:image];
    [self.taskImageCollection reloadData];
    
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
    self.pendingTask.assignedID = @"";
    self.pendingTask.tag = @"";
    self.pendingTask.completed = false;
    if(self.pendingTask.TRANSIENT_audioDataURL) {
        CSTaskMediaRealmModel* newMedia = [[CSTaskMediaRealmModel alloc] init];
        newMedia.mediaType = CSTaskMediaType_Audio;
        newMedia.mediaData = [NSData dataWithContentsOfURL:self.pendingTask.TRANSIENT_audioDataURL];
        [self.pendingTask.taskMedia addObject: newMedia];
    }
    
//    [_sessionManager addTag:self.pendingTask.tag];
    
    [_realm beginWriteTransaction];
    [_realm addObject:self.pendingTask];
    [_realm commitWriteTransaction];
    
    [[CSSessionDataAnalyzer sharedInstance:nil] sendMessageToAllPeersForNewTask:self.pendingTask];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CollectionView DataSource/Delegate
- (BOOL)collectionView:(UICollectionView*)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    CSTaskImageCollectionViewCell* selected = (CSTaskImageCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    [self performSegueWithIdentifier:@"enlargedPictureController" sender: selected.taskImageView.image];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
//    _dottedPageControl.numberOfPages = self.taskImages.count;
//    _dottedPageControl.currentPage = 0;
    
    return self.taskImages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CSTaskImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTaskImageCollectionViewCell forIndexPath:indexPath];
    
    cell.taskImageView.layer.cornerRadius = 8;
    cell.taskImageView.clipsToBounds = YES;
    
    [cell configureCellWithImage:[self.taskImages objectAtIndex:indexPath.row]];
    
    return cell;
}

-(void)collectionView:(UICollectionView*)collectionView
 didEndDisplayingCell:(UICollectionViewCell *)cell
   forItemAtIndexPath:(NSIndexPath *)indexPath
{
//    CSTaskImageCollectionViewCell* vis = [[self.taskImageCollection visibleCells] objectAtIndex:0];
//    NSIndexPath* path = [self.taskImageCollection indexPathForCell:vis];
    
//    _currentTaskImagePath = path;
//    _dottedPageControl.currentPage = path.row;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return self.taskImageCollection.frame.size;
}

#pragma mark - Status Bar
- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
