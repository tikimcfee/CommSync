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

#define time 0.2
#define alph 0.75

typedef NS_ENUM(NSInteger, CSSimpleDetailMode)
{
    CSSimpleDetailMode_View = 0,
    CSSimpleDetailMode_Edit
};

@interface CSSimpleTaskDetailViewController ()

@property (strong, nonatomic) AVAudioPlayer* audioPlayer;
@property (strong, nonatomic) NSURL* taskAudioURL;
@property (strong, nonatomic) NSMutableArray* taskImages;
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
        weakSelf.taskImages = loadedImages;
        [weakSelf.taskImageCollectionView reloadData];
    }];
    
    _dottedPageControl.hidesForSinglePage = YES;
    
    [self setupCollectionView];
    [self setupViewsFromSourceTask];
    
    // Data configuration
    _unsavedChanges = [NSMutableDictionary new];
    _currentRevisions = [CSTaskRevisionRealmModel new];
    
    _taskAudioURL = [_sourceTask temporarilyPersistTaskAudioToDisk];
    if (!_taskAudioURL) {
        _audioPlayerContainer.hidden = YES;
        _audioPlayerContainer.userInteractionEnabled = NO;
    }
}

- (void) setupViewsFromSourceTask {
    [_objectTextView setText:_sourceTask.taskDescription];
    _objectTextView.editable = NO;
    _objectTextView.textContainer.lineFragmentPadding = 0;
    _objectTextView.textContainerInset = UIEdgeInsetsZero;
    
    _taskTitleTextField.userInteractionEnabled = NO;
    _editIconImageView.userInteractionEnabled = YES;

    _priorityButtonsMainView.alpha = 0.0;
    _priorityButtonsMainView.userInteractionEnabled = NO;
    
    UIColor* c;
    if (_sourceTask.taskPriority == CSTaskPriorityHigh) {
        c = [UIColor kTaskHighPriorityColor];
    } else if (_sourceTask.taskPriority == CSTaskPriorityMedium) {
        c = [UIColor kTaskMidPriorityColor];
    } else {
        c = [UIColor kTaskLowPriorityColor];
    }
    _priorityBarView.backgroundColor = c;
    _priorityTextLabel.textColor = c;
    
    self.editIconImageView.tintColor = [UIColor flatBelizeHoleColor];
    UIImage* image = self.editIconImageView.image;
    self.editIconImageView.image = nil;
    self.editIconImageView.image = image;
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
- (IBAction)beginEditing:(id)sender {
    if(_mode == CSSimpleDetailMode_View) {
        _mode = CSSimpleDetailMode_Edit;
        [self toggleDetailsMode];
        
    } else {
        _mode = CSSimpleDetailMode_View;
        [self toggleDetailsMode];
        [self createTaskRevision];
        // check if changes were made...
        // save changes in revisions
    }
}

- (void) toggleDetailsMode {
    if (_mode == CSSimpleDetailMode_View) {
        _taskTitleTextField.userInteractionEnabled = NO;
        _objectTextView.editable = NO;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:0.5 animations:^{
            _taskTitleTextField.backgroundColor = [UIColor clearColor];
            _objectTextView.backgroundColor = [UIColor clearColor];
            _priorityButtonsMainView.alpha = 0.0;
        }];
    } else {
        _taskTitleTextField.userInteractionEnabled = YES;
        _objectTextView.editable = YES;
        _priorityButtonsMainView.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:0.5 animations:^{
            _taskTitleTextField.backgroundColor = [UIColor flatCloudsColor];
            _objectTextView.backgroundColor = [UIColor flatCloudsColor];
            _priorityButtonsMainView.alpha = 1.0;
        }];
    }
}

- (IBAction) priorityChanged:(id)sender {
    if (sender == _lowPriorityButton) {
        
    } else if (sender == _midPriorityButton) {
        
    } else if (sender == _highPriorityButton) {
        
    }
    
    
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
