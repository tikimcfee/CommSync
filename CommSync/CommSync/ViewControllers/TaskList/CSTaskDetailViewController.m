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
#import "CSTaskCreationViewController.h"
#import "ImageCell.h"
#import "CSPictureViewController.h"

@interface CSTaskDetailViewController ()

@property (strong, nonatomic) AVAudioPlayer* audioPlayer;
@property int activePic;

@end

@implementation CSTaskDetailViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //creates a transient task based off the current source task
    _transientTask = [[CSTaskTransientObjectStore alloc] initWithRealmModel:self.sourceTask];

    self.navigationBar.title = self.sourceTask.taskTitle;
    _activePic = -1;
    //scroll to bottom
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - 180) animated:YES];
   
    //create delegate and receptors
    [_commentField setDelegate:self];
    
    _tableView.tableHeaderView = _headerView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [_titleLabel setEnabled:NO];
    
    self.audioPlayer.delegate = self;
    
    [_transientTask  getAllImagesForTaskWithCompletionBlock:^void(BOOL didFinish) {
        if(didFinish) {
            [self setImagesFromTask];
        }
    }];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    self.audioPlayer = nil;
}


//initiate the header
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //creates the header
    CustomHeaderCell* headerCell = [[CustomHeaderCell alloc] init];
    
    //sets the items
    _titleLabel.text = self.sourceTask.taskTitle;
    _descriptionLabel.text = self.sourceTask.taskDescription;
    _priorityLabel.text = self.sourceTask.taskTitle;
    
    
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
           _priorityLabel.text = @"Standard Priority";
            break;
        
        //if green is selected or nothing is selected the task defaults to low priority
        default:
           _priorityColor.backgroundColor = [UIColor greenColor];
            _greenButton.alpha  = 1;
           _priorityLabel.text = @"Low Priority";
            break;
    }
    
    return headerCell;
}



//as many cells as the number of comments
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if( [_titleLabel isEnabled] ) return 0;
    return [self.sourceTask.comments count];
}

//inserts the comments into the cells one comment per cell
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
    CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex:indexPath.row];
    
    //formates the time string
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:comment.time];
    
    //sets the comments text
    cell.textLabel.text = [NSString stringWithFormat: @"(ID: %@) %@ time %@", comment.UID, comment.text, newDateString];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - Callbacks and UI State
- (void)setImagesFromTask {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_transientTask.TRANSIENT_taskImages.count > 0) {
            _embed.taskImages = _transientTask.TRANSIENT_taskImages;
            [_embed.tableView reloadData];
       }
    });
    
}


- (IBAction)addComment:(id)sender {
    if([_commentField.text  isEqual: @""]) return;
    
    //creates comment
    CSCommentRealmModel *comment = [CSCommentRealmModel new];
    comment.UID = @"Temp ID";
    comment.text = _commentField.text;
    comment.time = [NSDate date];
    
    //stores comment and reloads screen to show comment
    [_commentField setText:nil];
    [_sourceTask addComment:comment];
    [self.tableView reloadData];
    
    //scrolls table to new comment
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - self.tableView.bounds.size.height) animated:YES];
    [_commentField resignFirstResponder];

}


//dismisses keyboared when enter is hit
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_commentField resignFirstResponder];
    return YES;
}


//the keyboard shows up
- (void)keyboardDidShow:(NSNotification *)sender {
    if(_titleLabel.isEnabled) return;
    //get the size of the keyboard
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    
    //animate view moving uop
    [self.view layoutIfNeeded];
    _heightConst.constant = newFrame.size.height;
    [UIView animateWithDuration:0.2 animations:^{[self.view layoutIfNeeded];}];
}

- (IBAction)editMode:(id)sender {
    
    if(![_titleLabel isEnabled]){
        
        [_titleLabel setEnabled:YES];
        [_titleLabel setBackgroundColor: [UIColor lightGrayColor]];
        [_descriptionLabel setEditable:YES];
        [_descriptionLabel setBackgroundColor: [UIColor lightGrayColor]];
        [_editButton setTitle:@"Save"];
        [_audioButton setBackgroundColor:[UIColor redColor]];
        [_audioButton setTitle:@"Record Audio" forState:UIControlStateNormal];
        [_priorityColor setHidden:YES];
        [self.tableView reloadData];
        [_footerView setHidden:YES];
        
        [_greenButton setHidden:NO];
        [_yellowButton setHidden:NO];
        [_redButton setHidden:NO];
        
    }
    
    else{
        RLMRealm* realm = [RLMRealm defaultRealm];
    
    
        [realm beginWriteTransaction];
        [ _sourceTask setTaskTitle:_titleLabel.text];
        [_sourceTask setTaskDescription:_descriptionLabel.text];
        [_titleLabel setBackgroundColor: [UIColor whiteColor]];
        [_descriptionLabel setBackgroundColor: [UIColor whiteColor]];
        [_audioButton setBackgroundColor:[UIColor greenColor]];
        [_audioButton setTitle:@"Play" forState:UIControlStateNormal];
         
        
        
        if(_redButton.alpha == 1) [_sourceTask setTaskPriority:2];
        else if (_yellowButton.alpha == 1) [_sourceTask setTaskPriority:1];
        else [_sourceTask setTaskPriority:0];

        [realm commitWriteTransaction];
        
        [_titleLabel setEnabled:NO];
        [_descriptionLabel setEditable:NO];
        [_editButton setTitle:@"Edit"];
        
        [_footerView setHidden:NO];
        
        [self.tableView reloadData];
        [_greenButton setHidden:YES];
        [_yellowButton setHidden:YES];
        [_redButton setHidden:YES];
        [_priorityColor setHidden:NO];
    }
}

- (void)keyboardWillHide:(NSNotification *)sender {
    if(_titleLabel.isEnabled) return;
    //animate view moving down
    [self.view layoutIfNeeded];
    _heightConst.constant = 50;
    [UIView animateWithDuration:0.2 animations:^{[self.view layoutIfNeeded];}];
}

- (IBAction)setRed:(id)sender {
    [_redButton setAlpha:1];
    [_yellowButton setAlpha:.25];
    [_greenButton setAlpha:.25];
}

- (IBAction)setGreen:(id)sender {
    [_redButton setAlpha:.25];
    [_yellowButton setAlpha:.25];
    [_greenButton setAlpha:1];
}

- (IBAction)setYellow:(id)sender {
    [_redButton setAlpha:.25];
    [_yellowButton setAlpha:1];
    [_greenButton setAlpha:.25];
}
- (IBAction)playAudio:(id)sender {
  
    if(!_titleLabel.isEnabled)
    {
        
        NSData* audioData = self.sourceTask.taskAudio;
        NSError* error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&error];
        [self.audioPlayer play];
    }
    else{
        
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pictureTable"]) {
        _embed = segue.destinationViewController;
    }
}
@end