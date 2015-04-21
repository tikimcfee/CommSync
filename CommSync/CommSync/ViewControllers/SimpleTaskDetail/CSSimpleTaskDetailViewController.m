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

#define kTaskImageCollectionViewCell @"TaskImageCollectionViewCell"
#define kChatTableViewCellIdentifier @"ChatViewCell"
#define kTextBorderColor flatWetAsphaltColor

#define time 0.2
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
@property (strong, nonatomic) UIImagePickerController* imagePicker;

@property (strong, nonatomic) NSData* taskAudio;
@property (strong, nonatomic) NSMutableArray* taskImages;
@property (nonatomic, assign) CGRect oldFrameForCollectionView;
@property (nonatomic, assign) CGRect oldFrameForHeaderView;
@property (nonatomic, assign) CSSimpleDetailMode mode;
@property (nonatomic, strong) NSIndexPath* currentTaskImagePath;

@property (nonatomic, strong) UIImage* taskIncompleteImage;
@property (nonatomic, strong) UIImage* taskCompleteImage;

// Revision management
@property (strong, nonatomic) CSTaskRevisionRealmModel *currentRevisions;
@property (strong, nonatomic) NSMutableDictionary *unsavedChanges;
@property (nonatomic, assign) CSTaskPriority newPriority;

// State
@property (assign, nonatomic) BOOL firstLayoutComplete;

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
    
    _taskTitleTextField.text = _sourceTask.taskTitle;
    _taskTitleTextField.userInteractionEnabled = NO;

    _priorityButtonsMainView.alpha = 0.0;
    _priorityButtonsMainView.userInteractionEnabled = NO;
    
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
    
    _editIconImageView.image = [IonIcons imageWithIcon:ion_edit size:33.0f color:[UIColor flatConcreteColor]];
    _backToListImageView.image = [IonIcons imageWithIcon:ion_ios_list size:33.0f color:[UIColor flatConcreteColor]];
    _taskIncompleteImage = [IonIcons imageWithIcon:ion_ios_checkmark_outline size:64.0f color:c];
    _taskCompleteImage = [IonIcons imageWithIcon:ion_ios_checkmark size:64.0f color:[UIColor flatEmeraldColor]];
    _checkIconImageView.image = _taskIncompleteImage;
    _editIconImageView.userInteractionEnabled = YES;
    _backToListImageView.userInteractionEnabled = YES;
    _checkIconImageView.userInteractionEnabled = YES;
    
    _taskAudio = [_sourceTask getTaskAudio];
    if (!_taskAudio) {
        _audioPlayImageView.hidden = YES;
        _audioPlayImageView.userInteractionEnabled = NO;
    } else {
        _audioPlayImageView.image = [IonIcons imageWithIcon:ion_ios_recording size:33.0f color:[UIColor flatConcreteColor]];
        _audioPlayImageView.userInteractionEnabled = YES;
    }
    
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
    
//    _playAudioRecognizer.frameToDetect = _audioPlayImageView.frame;
//    _playAudioRecognizer.tapDelegate = self;
//    _backToListRecognizer.frameToDetect = _backToListImageView.frame;
//    _backToListRecognizer.tapDelegate = self;
//    _editingRecognizer.frameToDetect = _editIconImageView.frame;
//    _editingRecognizer.tapDelegate = self;
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
    }
    return UITableViewAutomaticDimension;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sourceTask.comments.count > 4 ? 5 : self.sourceTask.comments.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ChatViewCell";
    static NSString *allCommentsIdentifier = @"allCommentsCell";
    UITableViewCell* cell;
    if(indexPath.row == 4) {
        cell = [tableView dequeueReusableCellWithIdentifier:allCommentsIdentifier];
        CSRestOfCommentsTableViewCell* cellRef = (CSRestOfCommentsTableViewCell*)cell;
        NSString* plural = _sourceTask.comments.count > 5 ? @"s" : @"";
        cellRef.label.text = [NSString stringWithFormat:@"View %d more comment%@",
                              _sourceTask.comments.count - 4,
                              plural];
    } else {
        CSChatTableViewCell *cellRef = (CSChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell = cellRef;
        CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex:indexPath.row];
        
        cellRef.createdByLabel.text = comment.UID;
        cellRef.messageLabel.text = comment.text;
        cellRef.transform = self.tableview.transform;
    }
    return cell;
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
    
    // reset changes
    self.unsavedChanges = [NSMutableDictionary new];
    self.currentRevisions = [CSTaskRevisionRealmModel new];
    self.newPriority = CSTaskPriorityUnset;
}

- (void)findAndSetTaskChanges {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    // title changed
    if (![self.sourceTask.taskTitle isEqualToString:self.taskTitleTextField.text]) {
        [self.unsavedChanges setObject:self.taskTitleTextField.text forKey:[NSNumber numberWithInteger:CSTaskProperty_taskTitle]];
        self.sourceTask.taskTitle = self.taskTitleTextField.text;
    }
    
    // description changed
    if (![self.sourceTask.taskDescription isEqualToString:self.objectTextView.text]) {
        [self.unsavedChanges setObject:self.objectTextView.text forKey:[NSNumber numberWithInteger:CSTaskProperty_taskDescription]];
        self.sourceTask.taskDescription = self.objectTextView.text;
    }
    
    // priority changed
    if (_newPriority != CSTaskPriorityUnset && self.sourceTask.taskPriority != _newPriority) {
        [self.unsavedChanges setObject:[NSNumber numberWithInt:_newPriority] forKey:[NSNumber numberWithInteger:CSTaskProperty_taskPriority]];
        self.sourceTask.taskPriority = _newPriority;
    }
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
}

#pragma mark -
#pragma mark Actions and User Controls
- (IBAction)completeTask:(id)sender {
    //
    BOOL target = _sourceTask.completed ? NO : YES;
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    _sourceTask.completed = target;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [self animateImages];

}

- (void)animateImages
{
    UIImage *image = _sourceTask.completed ? _taskCompleteImage : _taskIncompleteImage;
    
    [UIView transitionWithView:self.checkIconImageView
                      duration:1.0f // animation duration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.checkIconImageView.image = image; // change to other image
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
        bottomButtonText = @"Add Comment";
        
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _taskTitleTextField.backgroundColor = [UIColor clearColor];
                             _objectTextView.backgroundColor = [UIColor clearColor];
                             _priorityButtonsMainView.alpha = 0.0;
                             _bottomActionButton.backgroundColor = [[UIColor flatPeterRiverColor] colorWithAlphaComponent:0.8];
                         }
                         completion:nil];
    } else {
        _taskTitleTextField.userInteractionEnabled = YES;
        _objectTextView.editable = YES;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        bottomButtonText = @"Add Photo";
        
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                            _taskTitleTextField.backgroundColor = [UIColor flatCloudsColor];
                            _objectTextView.backgroundColor = [UIColor flatCloudsColor];
                            _priorityButtonsMainView.alpha = 1.0;
                            _bottomActionButton.backgroundColor = [[UIColor flatCarrotColor] colorWithAlphaComponent:0.8];
                         }
                         completion:nil];
    }
    
    [CATransaction begin];
    
    // add/remove editable borders
    [self animationForLayer:_taskTitleTextField.layer];
    [self animationForLayer:_objectTextView.layer];
    
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

    __weak typeof(self) weakSelf = self;
    void (^fixImageIfNeeded)(UIImage*) = ^void(UIImage* image) {
        

        NSLog(@"New size after normalization only is %ld",
              (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:image] length]);
        NSData* thisImage = UIImageJPEGRepresentation(image, 0.0); // make a new JPEG data object with some compressed size
        NSLog(@"New size after JPEG compression is %ld",
              (unsigned long)[[NSKeyedArchiver archivedDataWithRootObject:thisImage] length]);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.sourceTask addTaskMediaOfType:CSTaskMediaType_Photo
                                           withData:thisImage
                                            toRealm:[RLMRealm defaultRealm]
                                       inTransation:YES];
        });
        
        [weakSelf.sourceTask getAllImagesForTaskWithCompletionBlock:^(NSMutableArray* loadedImages) {
            weakSelf.taskImages = loadedImages;
            [weakSelf.taskImageCollectionView reloadData];
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
    NSError* error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[_sourceTask getTaskAudio]
                                                     error:&error];
    [self.audioPlayer play];
}

#pragma mark - Segues
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString: @"commentSegue"]) {
        CSChatViewController *temp = segue.destinationViewController;
        temp.sourceTask = _sourceTask;
    } else if ([segue.identifier isEqualToString:@"enlargedPictureController"]) {
        CSPictureController* picture = segue.destinationViewController;
        picture.taskImage = sender;
    }
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
