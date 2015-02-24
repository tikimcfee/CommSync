//
//  CSTaskDetailViewController.m
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskDetailViewController.h"
#import "CSTaskTransientObjectStore.h"
#import "CustomHeaderCell.h"
#import "CSCommentRealmModel.h"
#import "CustomFooterCell.h"
#import <Realm/Realm.h>
#import "CSChatTableViewCell.h"
#import "CSTaskCreationViewController.h"
#import "ImageCell.h"
#import "CSPictureViewController.h"
#import "SlackTestViewController.h"

#define kChatTableViewCellIdentifier @"ChatViewCell"

@interface CSTaskDetailViewController ()

@property (strong, nonatomic) AVAudioPlayer* audioPlayer;
@property float width, height;


@end

@implementation CSTaskDetailViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //creates a transient task based off the current source task
    _transientTask = [[CSTaskTransientObjectStore alloc] initWithRealmModel:self.sourceTask];
    //[_top setActive:NO];
    self.navigationBar.title = self.sourceTask.taskTitle;
    
    _height = self.headerView.frame.size.height / 2;
    _width = self.tableView.frame.size.height / 3;
    
    _containerWidth.constant = _width;
    _containerHeight.constant = _height;
    
    
    //scroll to bottom
    [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentSize.height - 180) animated:YES];
    _distanceEdge.constant = 8;
    
    //create delegate and receptors
    [_commentField setDelegate:self];
    
    /**
     *  Register to use custom table view cells
     */
    [self.tableView registerNib:[UINib nibWithNibName:@"CSChatTableViewCell" bundle:nil] forCellReuseIdentifier:kChatTableViewCellIdentifier];
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    _tableView.tableHeaderView = _headerView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [_titleLabel setEnabled:NO];
    
    
    [_top setActive:YES];
    
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
    
    if(![_titleLabel isEnabled]){
        if([_descriptionLabel.text  isEqual: @""]) _descriptionLabel.text = @"NO DESCRIPTION";
        if([self.sourceTask.taskTitle  isEqual: @""]) _titleLabel.text = @"NO TITLE";
    }

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
           _priorityLabel.text = @"Med Priority";
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
    
/*
    CSChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
    CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex:indexPath.row];
    
    if(indexPath.row % 2 == 1)cell.backgroundColor = [UIColor lightGrayColor];
    
    //formates the time string
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:comment.time];
    
    //sets the comments text
    cell.textLabel.text = [NSString stringWithFormat: @"(ID: %@) %@ time %@", comment.UID, comment.text, newDateString];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12]; */
  
    static NSString *cellIdentifier = @"ChatViewCell";
    CSChatTableViewCell *cell = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex:indexPath.row];
    
    if (!cell)
    {
        cell = [[CSChatTableViewCell alloc] init];
    }
    
    //    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", msg.createdBy, msg.messageText];
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
        if (_transientTask.TRANSIENT_taskImages.count > 0) {
            _embed.taskImages = _transientTask.TRANSIENT_taskImages;
            [_embed.tableView reloadData];
            [self.tableView reloadData];
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
        
        
        //if([_titleLabel.text  isEqual: @"No Title"]) _titleLabel.text = @"";
        
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
        [_audioContainer setHidden:YES];
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
- (IBAction)playAudio:(id)sender {
  [_distanceEdge setActive:YES];
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
        _embed.containerHeight = _containerHeight;
        _embed.containerWidth = _containerWidth;
        _embed.distanceEdge = _distanceEdge;
        _embed.top = _top;
        _embed.detail = self.tableView;
        _embed.header = self.headerView;
    }
    
    if ([[segue identifier] isEqualToString:@"commentSegue"]) {
        SlackTestViewController *temp = segue.destinationViewController;
        temp.sourceTask = _sourceTask;
    }
}
@end