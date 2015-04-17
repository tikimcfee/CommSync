//
//  CSTaskDetailViewController.m
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskDetailViewController.h"
#import "CustomHeaderCell.h"
#import "CSCommentRealmModel.h"
#import "CustomFooterCell.h"
#import <Realm/Realm.h>
#import "CSChatTableViewCell.h"
#import "CSTaskCreationViewController.h"
#import "ImageCell.h"
#import "CSPictureViewController.h"
#import "SlackTestViewController.h"
#import "CSAudioPlotViewController.h"
#import "UIImage+normalize.h"
#import "CSAssignViewController.h"
#import "CSTaskRevisionRealmModel.h"


#define kChatTableViewCellIdentifier @"ChatViewCell"

@interface CSTaskDetailViewController ()

// VC for audio recording
@property (weak, nonatomic) CSAudioPlotViewController   *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer             *audioPlayer;

// Image picker
@property (strong, nonatomic) UIImagePickerController   *imagePicker;

// Revision management
@property (strong, nonatomic) CSTaskRevisionRealmModel *currentRevisions;
@property (strong, nonatomic) NSMutableDictionary *unsavedChanges;
@property (strong, nonatomic) NSMutableArray* taskImages;
@property (strong, nonatomic) NSData* taskAudio;

@end

@implementation CSTaskDetailViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.title = self.sourceTask.taskTitle;
    
    //sets size of the container based on screen
    _containerWidth.constant = self.tableView.frame.size.height / 3;
    _containerHeight.constant = self.headerView.frame.size.height / 2;
    
    //scroll to bottom
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - 180) animated:YES];
    
    //  Register to use custom table view cells
    [self.tableView registerNib:[UINib nibWithNibName:@"CSChatTableViewCell" bundle:nil]
         forCellReuseIdentifier:kChatTableViewCellIdentifier];
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableHeaderView = _headerView;

    [_titleLabel setEnabled:NO];
    if(![_titleLabel isEnabled]){
        if([_descriptionLabel.text  isEqual: @""]) _descriptionLabel.placeholder = @"NO DESCRIPTION";
        if([self.sourceTask.taskTitle  isEqual: @""]) _titleLabel.placeholder = @"NO TITLE";
    }
    
    // Load task images
    _taskImages = [NSMutableArray new];
    [_sourceTask  getAllImagesForTaskWithCompletionBlock:^void(NSMutableArray* images) {
        _taskImages = images;
        [self setImagesFromTask];
    }];
    
    // Load task audio
    _taskAudio = [_sourceTask getTaskAudio];
    
    // Set table view header contents
    _titleLabel.text = self.sourceTask.taskTitle;
    _descriptionLabel.text = self.sourceTask.taskDescription;
    _priorityLabel.text = self.sourceTask.taskTitle;
    
    [self displayPriority];
    
    self.audioPlayer.delegate = self;
    [self configureAVAudioSession];
    
    // start with a blank set of changes
    self.unsavedChanges = [NSMutableDictionary new];
    self.currentRevisions = [CSTaskRevisionRealmModel new];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.audioPlayer = nil;
}

//as many cells as the number of comments
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if( [_titleLabel isEnabled] ) return 0;
    return [self.sourceTask.comments count];
}

//inserts the comments into the cells one comment per cell
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"ChatViewCell";
    CSChatTableViewCell *cell = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex:indexPath.row];
    
    if (!cell)
    {
        cell = [[CSChatTableViewCell alloc] init];
    }
    

    cell.createdByLabel.text = comment.UID;
    cell.messageLabel.text = comment.text;
    cell.transform = self.tableView.transform;
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - Callbacks and UI State
- (void)setImagesFromTask {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_taskImages > 0) {
            _embed.taskImages = _taskImages;
            [_embed.tableView reloadData];
            [self.tableView reloadData];
       }
    });
    
}


- (IBAction)editMode:(id)sender {
   
    if(![_titleLabel isEnabled]){
        
        [_titleLabel setEnabled:YES];
        [_titleLabel setBackgroundColor: [UIColor lightGrayColor]];
        [_descriptionLabel setEditable:YES];
        [_descriptionLabel setBackgroundColor: [UIColor lightGrayColor]];
        [_editButton setTitle:@"Save"];
        
        [self.tableView reloadData];
        [_footerView setHidden:YES];
        
        [_audioButton setHidden:YES];
        [_audioContainer setHidden:NO];
        
       
        [_greenButton setHidden:NO];
        [_yellowButton setHidden:NO];
        [_redButton setHidden:NO];
        
        [_priorityLabel setHidden:YES];

    }
    
    else{
        RLMRealm* realm = [RLMRealm defaultRealm];
    
        [realm beginWriteTransaction];
        [ _sourceTask setTaskTitle:_titleLabel.text];
        [_sourceTask setTaskDescription:_descriptionLabel.text];
        [_titleLabel setBackgroundColor: [UIColor whiteColor]];
        [_descriptionLabel setBackgroundColor: [ UIColor colorWithRed: .8 green: .8 blue: .8 alpha:1.0]];
        
        if(_redButton.alpha == 1) [_sourceTask setTaskPriority:2];
        else if (_yellowButton.alpha == 1) [_sourceTask setTaskPriority:1];
        else [_sourceTask setTaskPriority:0];

        [_audioRecorder stopRecording];
        
        _sourceTask.TRANSIENT_audioDataURL =   _audioRecorder.fileOutputURL;
        if(_sourceTask.TRANSIENT_audioDataURL) {
            NSData* newAudio = [NSData dataWithContentsOfURL:_sourceTask.TRANSIENT_audioDataURL];
            [_sourceTask addTaskMediaOfType:CSTaskMediaType_Photo
                                   withData:newAudio
                                    toRealm:realm
                               inTransation:NO];
        }
        [realm commitWriteTransaction];
        
        
        
        [_titleLabel setEnabled:NO];
        [_descriptionLabel setEditable:NO];
        [_editButton setTitle:@"Edit"];
        
        [_footerView setHidden:NO];
        
        [self.tableView reloadData];
        [_priorityLabel setHidden:NO];
        [_greenButton setHidden:YES];
        [_yellowButton setHidden:YES];
        [_redButton setHidden:YES];
        
        [_audioButton setHidden:NO];
    }
}

- (void)createTaskRevision {
    
    [self findAndSetTaskChanges];
    
    NSArray *allChanges = [self.unsavedChanges allKeys];
    
    if ([allChanges count] == 0) return;
    
    for (NSNumber *property in allChanges) {
        
        [self.currentRevisions forTask:self.sourceTask
                        reviseProperty:[property integerValue]
                                    to:[self.unsavedChanges objectForKey:property]];
    }
    
    // save revisions
    [self.currentRevisions save:self.sourceTask];
    [self.sourceTask addRevision:self.currentRevisions];
    
    // reset changes
    self.unsavedChanges = [NSMutableDictionary new];
    self.currentRevisions = [CSTaskRevisionRealmModel new];
}

- (void)findAndSetTaskChanges {
    
    // title changed
    if (![self.sourceTask.taskTitle isEqualToString:self.titleLabel.text]) {
        NSDictionary *titleChanges = @{
                                       @"from": self.sourceTask.taskTitle,
                                       @"to": self.titleLabel.text
                                       };
        [self.unsavedChanges setObject:titleChanges forKey:[NSNumber numberWithInteger:CSTaskProperty_taskTitle]];
    }
    
    // description changed
    if (![self.sourceTask.taskDescription isEqualToString:self.descriptionLabel.text]) {
        NSDictionary *descriptionChanges = @{
                                             @"from": self.sourceTask.taskDescription,
                                             @"to": self.descriptionLabel.text
                                             };
        [self.unsavedChanges setObject:descriptionChanges forKey:[NSNumber numberWithInteger:CSTaskProperty_taskDescription]];
    }
    
    // get priority
    CSTaskPriority newPriority;
    if (self.priorityColor.backgroundColor == [UIColor redColor])
        newPriority = CSTaskPriorityHigh;
    
    else if(self.priorityColor.backgroundColor == [UIColor yellowColor])
        newPriority = CSTaskPriorityMedium;
    
    else
        newPriority = CSTaskPriorityLow;
    
    // priority changed
    if (self.sourceTask.taskPriority != newPriority) {
        NSDictionary *descriptionChanges = @{
                                             @"from": [NSNumber numberWithInt:self.sourceTask.taskPriority],
                                             @"to": [NSNumber numberWithInt:newPriority]
                                             };
        [self.unsavedChanges setObject:descriptionChanges forKey:[NSNumber numberWithInteger:CSTaskProperty_taskPriority]];
    }
}

- (IBAction)setRed:(id)sender {
    [_redButton setAlpha:1];
    [_yellowButton setAlpha:.25];
    [_greenButton setAlpha:.25];
     _priorityColor.backgroundColor = [UIColor redColor];
    _priorityLabel.text = @"High Priority";
}

- (IBAction)setGreen:(id)sender {
    [_redButton setAlpha:.25];
    [_yellowButton setAlpha:.25];
    [_greenButton setAlpha:1];
     _priorityColor.backgroundColor = [UIColor greenColor];
    _priorityLabel.text = @"Low Priority";
    
}

- (IBAction)setYellow:(id)sender {
    [_redButton setAlpha:.25];
    [_yellowButton setAlpha:1];
    [_greenButton setAlpha:.25];
     _priorityColor.backgroundColor = [UIColor yellowColor];
    _priorityLabel.text = @"Med Priority";
}
- (IBAction)addPicture:(id)sender {
    
    UIImagePickerController* newPicker = [[UIImagePickerController alloc] init];
    
    _imagePicker = newPicker;
    _imagePicker.allowsEditing = YES;
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePicker.delegate = self;
    _imagePicker.showsCameraControls = YES;
    
    [self presentViewController:newPicker animated:YES completion:nil];
    
    [self.tableView reloadData];
    
}

- (IBAction)playAudio:(id)sender {

    if(!_titleLabel.isEnabled)
    {
        NSError* error;
        
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:_taskAudio error:&error];
        [self.audioPlayer play];
    }
    else{
        
    }
}

- (void) configureAVAudioSession //To play through main iPhone Speakers
{
    //get your app's audioSession singleton object
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    //error handling
    BOOL success;
    NSError* error;
    
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride:
    
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    
    if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set the audioSession override
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                         error:&error];
    if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    
    //activate the audio session
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"AVAudioSession error activating: %@",error);
    else NSLog(@"audioSession active");
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pictureTable"]) {
        _embed = segue.destinationViewController;
        _embed.header = self.headerView;
    }
    
    //both have a sourceTask value, thus we can combine them
    if ([[segue identifier] isEqualToString:@"commentSegue"]) {
        SlackTestViewController *temp = segue.destinationViewController;
        temp.sourceTask = _sourceTask;
    }
    
    if([[segue identifier] isEqualToString:@"tagPickerSegue"])
    {
        CSAssignViewController *temp = segue.destinationViewController;
        temp.sourceTask = _sourceTask;
        temp.taging = true;
    }
    
    if([[segue identifier] isEqualToString:@"assignmentSegue"])
    {
        CSAssignViewController *temp = segue.destinationViewController;
        temp.sourceTask = _sourceTask;
        temp.taging = false;
    }
    
    if([segue.identifier isEqualToString:@"CSAudioPlotViewController2"]) {
        
        //[self sharedInit];
        
        self.audioRecorder = (CSAudioPlotViewController*)[segue destinationViewController];
        self.audioRecorder.fileNameSansExtension = _sourceTask.concatenatedID;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    void (^fixImageIfNeeded)(UIImage*) = ^void(UIImage* image) {
        
        NSLog(@"New size after normalization only is %ld",
              (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:image] length]);
        NSData* thisImage = UIImageJPEGRepresentation(image, 0.0); // make a new JPEG data object with some compressed size
        NSLog(@"New size after JPEG compression is %ld",
              (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:thisImage] length]);

        [_sourceTask addTaskMediaOfType:CSTaskMediaType_Photo
                               withData:thisImage
                                toRealm:[RLMRealm defaultRealm]
                           inTransation:YES];
        
        [_embed.tableView reloadData];
    };
    
    [image normalizedImageWithCompletionBlock:fixImageIfNeeded];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void) displayPriority
{
    //priority label case
    switch (self.sourceTask.taskPriority) {
        case 2:
            _priorityColor.backgroundColor = [UIColor redColor];
            _redButton.alpha = 1;
            _priorityLabel.text = @"High Priority";
            break;
            
        case 1:
            _priorityColor.backgroundColor = [UIColor yellowColor];
            _yellowButton.alpha = 1;
            _priorityLabel.text = @"Med Priority";
            break;
            
            //if green is selected or nothing is selected the task defaults to low priority
        default:
            _priorityColor.backgroundColor = [UIColor greenColor];
            _greenButton.alpha  = 1;
            _priorityLabel.text = @"Low Priority";
            break;
    }
    
}

@end