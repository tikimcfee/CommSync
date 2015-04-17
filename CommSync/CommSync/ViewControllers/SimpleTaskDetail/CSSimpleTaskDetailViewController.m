//
//  CSSimpleTaskDetailViewController.m
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSSimpleTaskDetailViewController.h"
#import "CSTaskImageCollectionViewCell.h"
#import "UIColor+FlatColors.h"
#import "IonIcons.h"

#define kTaskImageCollectionViewCell @"TaskImageCollectionViewCell"
#define kTextBorderColor flatWetAsphaltColor

#define time 0.2
#define alph 0.75

typedef NS_ENUM(NSInteger, CSSimpleDetailMode)
{
    CSSimpleDetailMode_View = 0,
    CSSimpleDetailMode_Edit
};

@interface CSSimpleTaskDetailViewController ()

@property (strong, nonatomic) AVAudioPlayer* audioPlayer;
@property (strong, nonatomic) NSData* taskAudio;
@property (strong, nonatomic) NSMutableArray* taskImages;
@property (nonatomic, assign) CGRect oldFrameForCollectionView;
@property (nonatomic, assign) CGRect oldFrameForHeaderView;
@property (nonatomic, assign) CSSimpleDetailMode mode;
@property (nonatomic, strong) NSIndexPath* currentTaskImagePath;

// Revision management
@property (strong, nonatomic) CSTaskRevisionRealmModel *currentRevisions;
@property (strong, nonatomic) NSMutableDictionary *unsavedChanges;

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
    
    _dottedPageControl.hidesForSinglePage = YES;
    
    [self setupCollectionView];
    [self setupViewsFromSourceTask];
    
    // Data configuration
    _unsavedChanges = [NSMutableDictionary new];
    _currentRevisions = [CSTaskRevisionRealmModel new];
    
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
    
    _editIconImageView.image = [IonIcons imageWithIcon:ion_edit size:33.0f color:[UIColor flatConcreteColor]];
    _backToListImageView.image = [IonIcons imageWithIcon:ion_ios_list size:33.0f color:[UIColor flatConcreteColor]];
    
    _taskAudio = [_sourceTask getTaskAudio];
    if (!_taskAudio) {
        _audioPlayerContainer.hidden = YES;
        _audioPlayerContainer.userInteractionEnabled = NO;
    } else {
        _audioPlayImageView.image = [IonIcons imageWithIcon:ion_ios_recording size:33.0f color:[UIColor flatConcreteColor]];
    }
}

-(void)setupCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setMinimumLineSpacing:0.0f];
    [self.taskImageCollectionView setPagingEnabled:YES];
    [self.taskImageCollectionView setCollectionViewLayout:flowLayout];
    self.taskImageCollectionView.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat r = _midPriorityButton.frame.size.height / 2;
    _midPriorityButton.layer.cornerRadius = r;
    _lowPriorityButton.layer.cornerRadius = r;
    _highPriorityButton.layer.cornerRadius = r;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(self.taskImages.count > 0) {
        CSTaskImageCollectionViewCell* vis = [[_taskImageCollectionView visibleCells] objectAtIndex:0];
        NSIndexPath* path = [_taskImageCollectionView indexPathForCell:vis];
        
        _currentTaskImagePath = path;
    }
}

#pragma mark - TableView DataSource Delegate

#pragma mark - CollectionView DataSource/Delegate
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
}

- (void)findAndSetTaskChanges {
    
    // title changed
    if (![self.sourceTask.taskTitle isEqualToString:self.taskTitleTextField.text]) {
        [self.unsavedChanges setObject:self.taskTitleTextField.text forKey:[NSNumber numberWithInteger:CSTaskProperty_taskTitle]];
    }
    
    // description changed
    if (![self.sourceTask.taskDescription isEqualToString:self.objectTextView.text]) {
        [self.unsavedChanges setObject:self.objectTextView.text forKey:[NSNumber numberWithInteger:CSTaskProperty_taskDescription]];
    }
    
    // get priority
    CSTaskPriority newPriority;
    
    if (self.priorityBarView.backgroundColor == [UIColor kTaskHighPriorityColor])
        newPriority = CSTaskPriorityHigh;
    
    else if(self.priorityBarView.backgroundColor == [UIColor kTaskMidPriorityColor])
        newPriority = CSTaskPriorityMedium;
    
    else
        newPriority = CSTaskPriorityLow;
    
    // priority changed
    if (self.sourceTask.taskPriority != newPriority) {
        [self.unsavedChanges setObject:[NSNumber numberWithInt:newPriority] forKey:[NSNumber numberWithInteger:CSTaskProperty_taskPriority]];
    }
}

#pragma mark -
#pragma mark Actions and User Controls
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
    if (_mode == CSSimpleDetailMode_View) {
        _taskTitleTextField.userInteractionEnabled = NO;
        _objectTextView.editable = NO;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _taskTitleTextField.backgroundColor = [UIColor clearColor];
                             _objectTextView.backgroundColor = [UIColor clearColor];
                             _priorityButtonsMainView.alpha = 0.0;
                         }
                         completion:nil];
    } else {
        _taskTitleTextField.userInteractionEnabled = YES;
        _objectTextView.editable = YES;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:time
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _taskTitleTextField.backgroundColor = [UIColor flatCloudsColor];
                             _objectTextView.backgroundColor = [UIColor flatCloudsColor];
                             _priorityButtonsMainView.alpha = 1.0;
                         }
                         completion:nil];
    }
    
    [CATransaction begin];
    [self animationForLayer:_taskTitleTextField.layer];
    [self animationForLayer:_objectTextView.layer];
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

- (IBAction) priorityChanged:(id)sender {
    UIColor* toColor;
    NSString* p;
    if (sender == _lowPriorityButton) {
        toColor = [UIColor kTaskLowPriorityColor];
        p = @"Low";
    } else if (sender == _midPriorityButton) {
        toColor = [UIColor kTaskMidPriorityColor];
        p = @"Mid";
    } else if (sender == _highPriorityButton) {
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

- (IBAction)playAudio:(id)sender {
    NSError* error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:[_sourceTask getTaskAudio]
                                                     error:&error];
    [self.audioPlayer play];
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
