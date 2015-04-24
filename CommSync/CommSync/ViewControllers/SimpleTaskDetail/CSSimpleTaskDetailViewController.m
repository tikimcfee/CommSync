//
//  CSSimpleTaskDetailViewController.m
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSSimpleTaskDetailViewController.h"
#import "CSTaskImageCollectionViewCell.h"
#import "CSChatTableViewCell.h"
#import "UIColor+FlatColors.h"
#import "IonIcons.h"
#import "CSChatViewController.h"
#import "UIImage+normalize.h"
#import "CSPictureController.h"
#import "CSUserRealmModel.h"
#import "CSSessionManager.h"
#import "CSSessionDataAnalyzer.h"
#import "CSRealmFactory.h"

#define kTaskImageCollectionViewCell @"TaskImageCollectionViewCell"
#define kChatTableViewCellIdentifier @"ChatViewCell"
#define kTextBorderColor flatOrangeColor

#define time 0.3
#define alph 0.75
// Check background color : #AFF494

/**
    REQUIRED IMPLEMENTATION FOR EMPTY CLASSES!
 */
@implementation CSRestOfCommentsTableViewCell
@end
/**
    REQUIRED IMPLEMENTATION FOR EMPTY CLASSES!
 */

typedef NS_ENUM(NSInteger, CSSimpleDetailMode)
{
    CSSimpleDetailMode_View = 0,
    CSSimpleDetailMode_Edit
};

@interface CSSimpleTaskDetailViewController ()

// Backing controls
@property (strong, nonatomic) AVAudioPlayer* audioPlayer;
@property (weak, nonatomic) CSAudioPlotViewController* audioRecorder;
@property (strong, nonatomic) UIImagePickerController* imagePicker;

@property (strong, nonatomic) NSData* taskAudio;
@property (strong, nonatomic) NSMutableArray* taskImages;
@property (nonatomic, assign) CGRect oldFrameForCollectionView;
@property (nonatomic, assign) CGRect oldFrameForHeaderView;
@property (nonatomic, assign) CSSimpleDetailMode mode;
@property (nonatomic, strong) NSIndexPath* currentTaskImagePath;

@property (nonatomic, strong) UIImage* taskAudioNormal;
@property (nonatomic, strong) UIImage* taskAudioNaN;
@property (nonatomic, strong) UIImage* taskAudioEditing;

// Revision management
@property (strong, nonatomic) CSTaskRevisionRealmModel *currentRevisions;
@property (strong, nonatomic) NSMutableDictionary *unsavedChanges;
@property (assign, nonatomic) BOOL taskCompleted;
@property (assign, nonatomic) CSTaskPriority newPriority;
@property (strong, nonatomic) NSString* userSelectedAssignedUser;

// State
@property (assign, nonatomic) BOOL firstLayoutComplete;
@property (weak, nonatomic) CSUserSelectionViewController* userSelection;

@property (strong, nonatomic) NSPredicate *pred;
@end

@implementation CSSimpleTaskDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self sharedInit];
}


- (void) sharedInit {
    // View setup
    _mode = CSSimpleDetailMode_View;
    
    __weak typeof(self) weakSelf = self;
    [_sourceTask getAllImagesForTaskWithCompletionBlock:^(NSMutableArray* loadedImages) {
        if(loadedImages.count == 0) {
            [weakSelf removeTaskImageCollectionView];
        } else {
            weakSelf.taskImages = loadedImages;
            [weakSelf.taskImageCollectionView reloadData];
        }
    }];
    
    [self setupCollectionView];
    [self setupViewsFromSourceTask];
    
    // Data configuration
    _unsavedChanges = [NSMutableDictionary new];
    _currentRevisions = [CSTaskRevisionRealmModel new];
    
    // Cell Returns
    [self.tableview registerNib:[UINib nibWithNibName:@"CSChatTableViewCell" bundle:nil]
         forCellReuseIdentifier:kChatTableViewCellIdentifier];
    
    self.firstLayoutComplete = NO;
    self.newPriority = CSTaskPriorityUnset;
    
    _pred = [NSPredicate predicateWithFormat:@"recipient = %@", _sourceTask.UUID];
    
}

- (void) removeTaskImageCollectionView {
    UIView* header = self.tableview.tableHeaderView;
    _oldFrameForHeaderView = header.frame;
    CGRect frame = CGRectMake(CGRectGetMinX(header.frame),
                              CGRectGetMinY(header.frame),
                              CGRectGetWidth(header.frame),
                              CGRectGetHeight(header.frame) - _taskImageCollectionView.frame.size.height);;
    header.frame = frame;
    _oldFrameForCollectionView = self.taskImageCollectionView.frame;
    self.taskImageCollectionView.frame = CGRectZero;
    [self.tableview setTableHeaderView:header];
}

//  The code below will reset the header view to its old calculated size
- (void) repairTaskImageCollectionView {
    self.tableview.tableHeaderView.frame = _oldFrameForHeaderView;
    self.taskImageCollectionView.frame = _oldFrameForCollectionView;
    [self.tableview setTableHeaderView:self.tableview.tableHeaderView];
}

- (void) setupViewsFromSourceTask {
    [_objectTextView setText:_sourceTask.taskDescription];
    _objectTextView.editable = NO;
    _objectTextView.textContainer.lineFragmentPadding = 0;
    _objectTextView.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4);
    _objectTextView.layer.cornerRadius = 4;
    
    _taskTitleTextField.text = _sourceTask.taskTitle;
    _taskTitleTextField.userInteractionEnabled = NO;
    _taskTitleTextField.layer.cornerRadius = 4;
    
    _priorityButtonsMainView.alpha = 0.0;
    _priorityButtonsMainView.userInteractionEnabled = NO;
    _lowPriorityButton.backgroundColor = [UIColor kTaskLowPriorityColor];
    _midPriorityButton.backgroundColor = [UIColor kTaskMidPriorityColor];
    _highPriorityButton.backgroundColor = [UIColor kTaskHighPriorityColor];
    
    _checkIconImageView.alpha = 0;
    _checkIconImageView.userInteractionEnabled = NO;
    _taskCompleted = self.sourceTask.completed;
    
    
    _bottomActionButton.backgroundColor = [[UIColor flatPeterRiverColor] colorWithAlphaComponent:0.8];
    
    UIColor* c;
    NSString* s;
    if (_sourceTask.taskPriority == CSTaskPriorityHigh) {
        c = [UIColor kTaskHighPriorityColor];
        s = @"High";
    } else if (_sourceTask.taskPriority == CSTaskPriorityMedium) {
        c = [UIColor kTaskMidPriorityColor];
        s = @"Mid";
    } else {
        c = [UIColor kTaskLowPriorityColor];
        s = @"Low";
    }
    
    _priorityBarView.backgroundColor = c;
    _priorityTextLabel.textColor = c;
    _priorityTextLabel.text = [NSString stringWithFormat:@"%@ Priority", s];
    
    _dottedPageControl.hidesForSinglePage = YES;
    
    _editIconImageView.image = [IonIcons imageWithIcon:ion_edit size:33.0f color:[UIColor whiteColor]];
    _editIconImageView.userInteractionEnabled = YES;
    
    CSUserRealmModel* assignedUser = [CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm] forPrimaryKey:self.sourceTask.assignedID];
    if (assignedUser) {
        _assigneeImageView.image = [UIImage imageNamed:[assignedUser getPicture]];
    } else {
        _assigneeImageView.image = [UIImage imageNamed:@"Avatar -1"];
    }
    _assigneeImageView.userInteractionEnabled = YES;
    
    
    // Get and set audio images for later reuse in editing modes
    _taskAudio = [_sourceTask getTaskAudio];
    _taskAudioNaN = [IonIcons imageWithIcon:ion_ios_recording
                                       size:33.0f
                                      color:[[UIColor flatCloudsColor]
                                             colorWithAlphaComponent:0.5]];
    _taskAudioNormal = [IonIcons imageWithIcon:ion_ios_recording
                                          size:33.0f
                                         color:[UIColor whiteColor]];
    if (!_taskAudio) {
        _audioPlayImageView.image = _taskAudioNaN;
    } else {
        _audioPlayImageView.image = _taskAudioNormal;
    }
    
    _audioPlayImageView.userInteractionEnabled = YES;
    _tableview.estimatedRowHeight = 44.0f;
    _tableview.rowHeight = UITableViewAutomaticDimension;
    
    [self animateImages];
}

-(void)setupCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setMinimumLineSpacing:0.0f];
    [self.taskImageCollectionView setPagingEnabled:YES];
    [self.taskImageCollectionView setCollectionViewLayout:flowLayout];
    self.taskImageCollectionView.backgroundColor = [UIColor clearColor];
    self.taskImageCollectionView.layer.cornerRadius = 8;
    self.taskImageCollectionView.clipsToBounds = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableview reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(self.taskImages.count > 0) {
        CSTaskImageCollectionViewCell* vis = [[_taskImageCollectionView visibleCells] objectAtIndex:0];
        NSIndexPath* path = [_taskImageCollectionView indexPathForCell:vis];
        
        _currentTaskImagePath = path;
    }
    
    CGFloat r = _midPriorityButton.frame.size.height / 2;
    _midPriorityButton.layer.cornerRadius = r;
    _lowPriorityButton.layer.cornerRadius = r;
    _highPriorityButton.layer.cornerRadius = r;
    
    _tableview.contentSize = CGSizeMake(_tableview.contentSize.width,
                                        _tableview.contentSize.height + 44);
}

#pragma mark - TableView DataSource + Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 4 && self.sourceTask.comments.count > 4) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self performSegueWithIdentifier:@"commentSegue" sender:self];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 4 && self.sourceTask.comments.count > 4 ? YES : NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 4 && self.sourceTask.comments.count > 4) {
        return 88;
    } else if (indexPath.row == 0 && self.sourceTask.comments.count == 0) {
        return 132;
    }
    return UITableViewAutomaticDimension;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    if(self.sourceTask.comments.count == 0) {
//        return 1;
//    } else if(self.sourceTask.comments.count > 4) {
//        return 5;
//    } else {
//        return self.sourceTask.comments.count;
//    }
    //int number = [CSChatMessageRealmModel ]
    
    if( [[CSChatMessageRealmModel objectsInRealm:[CSRealmFactory privateMessageRealm] withPredicate:_pred] count] > 5) return 5;
    else  return [[CSChatMessageRealmModel objectsInRealm:[CSRealmFactory privateMessageRealm] withPredicate:_pred] count];
    
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    static NSString *cellIdentifier = @"ChatViewCell";
//    static NSString *allCommentsIdentifier = @"allCommentsCell";
//    static NSString *noCommentsIdentifier = @"noCommentsCell";
//    UITableViewCell* cell;
//    if (self.sourceTask.comments.count == 0) {
//        cell = [tableView dequeueReusableCellWithIdentifier:noCommentsIdentifier];
//    } else if(indexPath.row == 4) {
//        cell = [tableView dequeueReusableCellWithIdentifier:allCommentsIdentifier];
//        CSRestOfCommentsTableViewCell* cellRef = (CSRestOfCommentsTableViewCell*)cell;
//        NSString* plural = _sourceTask.comments.count > 5 ? @"s" : @"";
//        cellRef.label.text = [NSString stringWithFormat:@"View %lu more comment%@",
//                              (long)_sourceTask.comments.count - 4,
//                              plural];
//    } else {
//        CSChatTableViewCell *cellRef = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
//        cell = cellRef;
//        RLMResults* comments = [self.sourceTask.comments sortedResultsUsingProperty:@"time" ascending:NO];
//        CSCommentRealmModel *comment = [comments objectAtIndex:indexPath.row];
//        
//        CSUserRealmModel* user = [CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm]
//                                                   forPrimaryKey:comment.UID];
//        NSString* createdBy = user ? user.displayName : @"Unknown";
//        cellRef.createdByLabel.text = createdBy;
//        cellRef.messageLabel.text = comment.text;
//        cellRef.transform = self.tableview.transform;
//    }
//    return cell;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"h:mm a"];
    
    static NSString *cellIdentifier = @"ChatViewCell";
    CSChatTableViewCell *cell = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[CSChatTableViewCell alloc] init];
    }
    
    // if(!_sourceTask){
    
    CSChatMessageRealmModel *msg = [self chatObjectAtIndex:indexPath.item];
    
    cell.messageLabel.text = msg.messageText;
    cell.transform = self.tableview.transform;
    
    CSUserRealmModel *person = [CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm] forPrimaryKey:msg.createdBy];
    cell.createdByLabel.text = person.displayName;
    cell.createdAtLabel.text = [format stringFromDate:msg.createdAt];
    NSString *image = [person getPicture];
    [cell.avatarImage setImage:[UIImage imageNamed:image]];
    cell.avatarImage.layer.cornerRadius = cell.avatarImage.frame.size.width / 2;
    
  
    return cell;
}

- (CSChatMessageRealmModel *)chatObjectAtIndex:(NSUInteger)index
{
    RLMResults *orderedChatMessages = [[CSChatMessageRealmModel objectsInRealm:[CSRealmFactory privateMessageRealm] withPredicate:_pred] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    return [orderedChatMessages objectAtIndex:index];
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
    
    _dottedPageControl.numberOfPages = self.taskImages.count;
    _dottedPageControl.currentPage = 0;
    
    return self.taskImages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    CSTaskImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTaskImageCollectionViewCell forIndexPath:indexPath];
    
    cell.taskImageView.layer.cornerRadius = 8;
    cell.taskImageView.clipsToBounds = YES;
    
    [cell configureCellWithImage:[_taskImages objectAtIndex:indexPath.row]];
    
    return cell;
}

-(void)collectionView:(UICollectionView*)collectionView
      didEndDisplayingCell:(UICollectionViewCell *)cell
   forItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSTaskImageCollectionViewCell* vis = [[_taskImageCollectionView visibleCells] objectAtIndex:0];
    NSIndexPath* path = [_taskImageCollectionView indexPathForCell:vis];
    
    _currentTaskImagePath = path;
    _dottedPageControl.currentPage = path.row;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    return self.taskImageCollectionView.frame.size;
}

#pragma mark - Revision management
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
    
    // apply edits
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.sourceTask.taskTitle = self.taskTitleTextField.text;
    self.sourceTask.taskDescription = self.objectTextView.text;
    self.sourceTask.taskPriority = self.newPriority == CSTaskPriorityUnset ? self.sourceTask.taskPriority : self.newPriority;
    self.sourceTask.completed = self.taskCompleted;
    self.sourceTask.assignedID = !self.userSelectedAssignedUser ?  self.sourceTask.assignedID : self.userSelectedAssignedUser;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    // send new task *with revisions* to all peers
    CSTaskRealmModel* inMemory = [CSTaskRealmModel taskModelWithModel:self.sourceTask];
    [[CSSessionDataAnalyzer sharedInstance:nil] sendTaskRevisionsToAllPeerForTask:inMemory];
    
    
    // reset changes
    self.unsavedChanges = [NSMutableDictionary new];
    self.currentRevisions = [CSTaskRevisionRealmModel new];
    self.newPriority = CSTaskPriorityUnset;
    self.sourceTask.addedAudioIDs = [NSMutableArray new];
    self.sourceTask.addedImagesMediaModelIDs = [NSMutableArray new];
    self.userSelectedAssignedUser = nil;
}

- (void)findAndSetTaskChanges {
//    [[RLMRealm defaultRealm] beginWriteTransaction];
    // title changed
    if (![self.sourceTask.taskTitle isEqualToString:self.taskTitleTextField.text]) {
        [self.unsavedChanges setObject:self.taskTitleTextField.text forKey:[NSNumber numberWithInteger:CSTaskProperty_taskTitle]];
    }
    
    // description changed
    if (![self.sourceTask.taskDescription isEqualToString:self.objectTextView.text]) {
        [self.unsavedChanges setObject:self.objectTextView.text forKey:[NSNumber numberWithInteger:CSTaskProperty_taskDescription]];
    }
    
    // priority changed
    if (_newPriority != CSTaskPriorityUnset && self.sourceTask.taskPriority != _newPriority) {
        [self.unsavedChanges setObject:[NSNumber numberWithInteger:_newPriority] forKey:[NSNumber numberWithInteger:CSTaskProperty_taskPriority]];
    }
    
    // added images
    if (self.sourceTask.addedImagesMediaModelIDs && self.sourceTask.addedImagesMediaModelIDs.count != 0) {
        [self.unsavedChanges setObject:self.sourceTask.addedImagesMediaModelIDs forKey:[NSNumber numberWithInteger:CSTaskProperty_taskImages_ADD]];
    }
    
    // changed audio
    if (self.sourceTask.addedAudioIDs && self.sourceTask.addedAudioIDs.count != 0) {
        [self.unsavedChanges setObject:self.sourceTask.addedAudioIDs forKey:[NSNumber numberWithInteger:CSTaskProperty_taskAudio_CHANGE]];
    }
    
    // changed assigned user
    if (self.userSelectedAssignedUser) {
        [self.unsavedChanges setObject:self.userSelectedAssignedUser forKey:[NSNumber numberWithInteger:CSTaskProperty_assignedID]];
    }
    
    // completed task
    if (self.taskCompleted == YES && self.sourceTask.completed == NO) {
        [self.unsavedChanges setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithInteger:CSTaskProperty_completed]];
    } else if(self.taskCompleted == NO && self.sourceTask.completed == YES){
        [self.unsavedChanges setObject:[NSNumber numberWithBool:NO] forKey:[NSNumber numberWithInteger:CSTaskProperty_completed]];
    }

//    [[RLMRealm defaultRealm] commitWriteTransaction];
}

#pragma mark -
#pragma mark Actions and User Controls
- (IBAction)reassignTask:(id)sender {
    [self performSegueWithIdentifier:@"userSelectionSegue" sender:self];
}


- (IBAction)completeTask:(id)sender {
    _taskCompleted = !_taskCompleted;
    [self animateImages];
}

- (void)animateImages
{
    NSString *name = _taskCompleted ? ion_ios_checkmark : ion_ios_checkmark_outline;

    CSTaskPriority thisPriority = _newPriority == CSTaskPriorityUnset ? _sourceTask.taskPriority : _newPriority;
    
    UIColor* c;
    if (_taskCompleted) {
        c = [UIColor flatEmeraldColor];
    } else if (thisPriority == CSTaskPriorityHigh) {
        c = [UIColor kTaskHighPriorityColor];
    } else if (thisPriority == CSTaskPriorityMedium) {
        c = [UIColor kTaskMidPriorityColor];
    } else {
        c = [UIColor kTaskLowPriorityColor];
    }
    
    [UIView transitionWithView:self.checkIconImageView
                      duration:time
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.checkIconImageView.image = [IonIcons imageWithIcon:name size:64.0f color:c];
                    } completion:^(BOOL finished) {
                    }];
}

- (IBAction)backToList:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)beginEditing:(id)sender {
    if(_mode == CSSimpleDetailMode_View) {
        _mode = CSSimpleDetailMode_Edit;
        [self toggleDetailsMode];
        
    } else {
        _mode = CSSimpleDetailMode_View;
        [self toggleDetailsMode];
        [self createTaskRevision];
    }
}

- (void) toggleDetailsMode {
    
    NSString* bottomButtonText;
    if (_mode == CSSimpleDetailMode_View) {
        _taskTitleTextField.userInteractionEnabled = NO;
        _objectTextView.editable = NO;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        _checkIconImageView.userInteractionEnabled = NO;
        bottomButtonText = @"Add Comment";
        
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _taskTitleTextField.backgroundColor = [UIColor clearColor];
                             _objectTextView.backgroundColor = [UIColor clearColor];
                             _priorityButtonsMainView.alpha = 0.0;
                             _checkIconImageView.alpha = 0.0;
                             _bottomActionButton.backgroundColor = [[UIColor flatPeterRiverColor] colorWithAlphaComponent:0.8];
                         }
                         completion:nil];
    } else {
        _taskTitleTextField.userInteractionEnabled = YES;
        _objectTextView.editable = YES;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        _checkIconImageView.userInteractionEnabled = YES;
        bottomButtonText = @"Add Photo";
        
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                            _taskTitleTextField.backgroundColor = [UIColor flatCloudsColor];
                            _objectTextView.backgroundColor = [UIColor flatCloudsColor];
                            _priorityButtonsMainView.alpha = 1.0;
                             _checkIconImageView.alpha = 1.0;
                            _bottomActionButton.backgroundColor = [[UIColor flatCarrotColor] colorWithAlphaComponent:0.8];
                         }
                         completion:nil];
    }
    
    [CATransaction begin];
    
    // add/remove editable borders
    [self animationForLayer:_taskTitleTextField.layer];
    [self animationForLayer:_objectTextView.layer];
    [self animationForLayer:_audioPlayImageView.layer];
    [self animationForLayer:_assigneeImageView.layer];
    
    // change button text
    CATransition *textChange = [CATransition animation];
    textChange.duration = time;
    textChange.type = kCATransitionFade;
    textChange.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_bottomActionString.layer addAnimation:textChange forKey:@"changeTextTransition"];
    _bottomActionString.text = bottomButtonText;
    
    [CATransaction commit];
}

- (CAAnimationGroup*)animationForLayer:(CALayer*)layer {
    UIColor* toColor;
    CGFloat width;
    if(_mode == CSSimpleDetailMode_Edit) {
        toColor = [UIColor kTextBorderColor];
        width = 2;
    } else {
        toColor = [UIColor clearColor];
        width = 0;
    }
    
    
    CABasicAnimation* color = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    color.fromValue = (id)layer.borderColor;
    color.toValue = (id)toColor.CGColor;
    layer.borderColor = toColor.CGColor;
    
    CABasicAnimation* borderWidth = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    borderWidth.fromValue = [NSNumber numberWithFloat:layer.borderWidth];
    borderWidth.toValue = [NSNumber numberWithFloat:width];
    layer.borderWidth = width;
    
    CAAnimationGroup* both = [CAAnimationGroup animation];
    both.duration = time;
    both.animations = @[color, borderWidth];
    both.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [layer addAnimation:both forKey:@"color and width"];
    return both;
}

- (IBAction)bottomActionButtonTapped:(id)sender {
    if(_mode == CSSimpleDetailMode_Edit)
    {
        // add a new image to task
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
            UIImagePickerController* newPicker = [[UIImagePickerController alloc] init];
            
            weakSelf.imagePicker = newPicker;
            weakSelf.imagePicker.allowsEditing = YES;
            weakSelf.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            weakSelf.imagePicker.delegate = self;
            weakSelf.imagePicker.showsCameraControls = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf presentViewController:newPicker animated:YES completion:nil];
            });
        });
    }
    else {
        [self performSegueWithIdentifier:@"commentSegue" sender:self];
    }
}


- (IBAction) priorityChanged:(id)sender {
    UIColor* toColor;
    NSString* p;
    if (sender == _lowPriorityButton) {
        _newPriority = CSTaskPriorityLow;
        toColor = [UIColor kTaskLowPriorityColor];
        p = @"Low";
    } else if (sender == _midPriorityButton) {
        _newPriority = CSTaskPriorityMedium;
        toColor = [UIColor kTaskMidPriorityColor];
        p = @"Mid";
    } else if (sender == _highPriorityButton) {
        _newPriority = CSTaskPriorityHigh;
        toColor = [UIColor kTaskHighPriorityColor];
        p = @"High";
    }
    
    [UIView animateWithDuration:time
                          delay:0
                         options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _priorityTextLabel.textColor = toColor;
                         _priorityBarView.backgroundColor = toColor;
                     }
                     completion:nil];
    
    if (self.taskCompleted == NO) {
        [UIView transitionWithView:self.checkIconImageView
                          duration:time
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                                self.checkIconImageView.image = [IonIcons imageWithIcon:ion_ios_checkmark_outline size:64.0f color:toColor];
                        } completion:nil];
    }

    
    CATransition *textChange = [CATransition animation];
    textChange.duration = time;
    textChange.type = kCATransitionFade;
    textChange.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_priorityTextLabel.layer addAnimation:textChange forKey:@"changeTextTransition"];
    
    _priorityTextLabel.text = [NSString stringWithFormat:@"%@ Priority", p];
}

#pragma mark -- Image Picker
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSString* UUID = self.sourceTask.concatenatedID;
    
    __weak typeof(self) weakSelf = self;
    void (^fixImageIfNeeded)(UIImage*) = ^void(UIImage* image) {
        NSLog(@"New size after normalization only is %ld",
              (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:image] length]);
        NSData* thisImage = UIImageJPEGRepresentation(image, 0.0); // make a new JPEG data object with some compressed size
        NSLog(@"New size after JPEG compression is %ld",
              (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:thisImage] length]);
        
        CSTaskRealmModel* memory = [CSTaskRealmModel objectForPrimaryKey:UUID];
        CSTaskMediaRealmModel* newMedia = [memory addTaskMediaOfType:CSTaskMediaType_Photo
                          withData:thisImage
                           toRealm:[RLMRealm defaultRealm]
                      inTransation:YES];
        
        if(!self.sourceTask.addedImagesMediaModelIDs) {
            self.sourceTask.addedImagesMediaModelIDs = [NSMutableArray new];
        }
        [self.sourceTask.addedImagesMediaModelIDs addObject:newMedia.uniqueMediaID];
        
        [weakSelf.sourceTask getAllImagesForTaskWithCompletionBlock:^(NSMutableArray* loadedImages) {
            if (weakSelf.taskImages.count == 0) {
                [weakSelf repairTaskImageCollectionView];
            }
            weakSelf.taskImages = loadedImages;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.taskImageCollectionView reloadData];
            });
        }];
    };
    
    [image normalizedImageWithCompletionBlock:fixImageIfNeeded];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark -- END Image Picker
- (IBAction)playAudio:(id)sender {
    [self configureAVAudioSession];
    
    if (_mode == CSSimpleDetailMode_View && self.taskAudio) {
        NSError* error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[_sourceTask getTaskAudio]
                                                         error:&error];
        [self.audioPlayer play];
    } else if (_mode == CSSimpleDetailMode_Edit){
        [self performSegueWithIdentifier:@"CSAudioPlotViewController" sender:nil];
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

#pragma mark - Segues
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString: @"commentSegue"]) {
        CSChatViewController *temp = segue.destinationViewController;
        temp.sourceTask = _sourceTask;
        temp.navigationItem.title = @"Comments";
    } else if ([segue.identifier isEqualToString:@"enlargedPictureController"]) {
        CSPictureController* picture = segue.destinationViewController;
        picture.taskImage = sender;
    } else if ([segue.identifier isEqualToString:@"CSAudioPlotViewController"]){
        // VC for audio recording
        self.audioRecorder = (CSAudioPlotViewController*)[segue destinationViewController];
        self.audioRecorder.fileNameSansExtension = self.sourceTask.concatenatedID;
        self.audioRecorder.showShowSaveAndClose = YES;
        self.audioRecorder.saveDelegate = self;
    } else if ([segue.identifier isEqualToString:@"userSelectionSegue"]){
        self.userSelection = segue.destinationViewController;
        self.userSelection.saveDelegate = self;
    }
}

- (void) assignUser:( NSString* )personID {
    if (personID && ![self.sourceTask.assignedID isEqualToString:personID]) {
        self.userSelectedAssignedUser = personID;
        CSUserRealmModel* assignedUser = [CSUserRealmModel objectInRealm:[CSRealmFactory peerHistoryRealm] forPrimaryKey:personID];
        self.assigneeImageView.image = [UIImage imageNamed:[assignedUser getPicture]];
    }
    
//    [self.userSelection dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) saveAudio {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.sourceTask.TRANSIENT_audioDataURL = self.audioRecorder.fileOutputURL;
    if(self.sourceTask.TRANSIENT_audioDataURL) {
        CSTaskMediaRealmModel* oldMedia = [_sourceTask getTaskAudioModel];
        if (oldMedia) {
            oldMedia.isOld = YES;
        }
        
        CSTaskMediaRealmModel* newMedia = [[CSTaskMediaRealmModel alloc] init];
        newMedia.mediaType = CSTaskMediaType_Audio;
        newMedia.mediaData = [NSData dataWithContentsOfURL:self.sourceTask.TRANSIENT_audioDataURL];

        if (self.taskAudio == nil) {
            [UIView transitionWithView:self.audioPlayImageView
                              duration:time // animation duration
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.audioPlayImageView.image = _taskAudioNormal; // change to other image
                            } completion:^(BOOL finished) {
                            }];
        }
        
        _taskAudio = newMedia.mediaData;
        [self.sourceTask.taskMedia addObject: newMedia];
        if(!self.sourceTask.addedAudioIDs) {
            self.sourceTask.addedAudioIDs = [NSMutableArray new];
        }
        [self.sourceTask.addedAudioIDs addObject:newMedia.uniqueMediaID];
        
    }
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    return YES;
}

//#pragma mark -
//#pragma mark Rotation handling methods
//
//-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:
//(NSTimeInterval)duration {
//    
//    // Fade the collectionView out
//    [self.taskImageCollectionView setAlpha:0.0f];
//    
//    // Suppress the layout errors by invalidating the layout
//    [self.taskImageCollectionView.collectionViewLayout invalidateLayout];
//    
//    // Calculate the index of the item that the collectionView is currently displaying
//    CGPoint currentOffset = [self.taskImageCollectionView contentOffset];
//    self.currentIndex = currentOffset.x / self.taskImageCollectionView.frame.size.width;
//}
//
//-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    
//    // Force realignment of cell being displayed
//    CGSize currentSize = self.taskImageCollectionView.bounds.size;
//    float offset = self.currentIndex * currentSize.width;
//    [self.taskImageCollectionView setContentOffset:CGPointMake(offset, 0)];
//    
//    // Fade the collectionView back in
//    [UIView animateWithDuration:0.125f animations:^{
//        [self.taskImageCollectionView setAlpha:1.0f];
//    }];
//    
//}

@end
