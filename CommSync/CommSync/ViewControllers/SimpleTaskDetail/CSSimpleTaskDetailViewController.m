//
//  CSSimpleTaskDetailViewController.m
//  CommSync
//
//  Created by Ivan Lugo on 4/13/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSSimpleTaskDetailViewController.h"
#import "CSTaskImageCollectionViewCell.h"
#define kTaskImageCollectionViewCell @"TaskImageCollectionViewCell"

#define time 0.2
#define alph 0.75

@interface CSSimpleTaskDetailViewController ()

@property (nonatomic) int currentIndex;
@property (strong, nonatomic) NSMutableArray* taskImages;

@end

@implementation CSSimpleTaskDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __weak typeof(self) weakSelf = self;
    [_sourceTask getAllImagesForTaskWithCompletionBlock:^(NSMutableArray* loadedImages) {
        weakSelf.taskImages = loadedImages;
        [weakSelf.taskImageCollectionView reloadData];
    }];
    
    [self setupCollectionView];

    _dottedPageControl.hidesForSinglePage = YES;
    
    [self setupViewsFromSourceTask];
}

- (void) setupViewsFromSourceTask {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    [_objectTextView setText:_sourceTask.taskDescription];
    [_objectTextView sizeToFit];
    [_objectTextView layoutIfNeeded];
}

-(void)setupCollectionView {
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setMinimumLineSpacing:0.0f];
    [self.taskImageCollectionView setPagingEnabled:YES];
    [self.taskImageCollectionView setCollectionViewLayout:flowLayout];
    self.taskImageCollectionView.backgroundColor = [UIColor clearColor];
//    self.taskImageCollectionView.layer.cornerRadius = 8;
//    self.taskImageCollectionView.layer.borderWidth = 1;
//    self.taskImageCollectionView.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//    _moreLeftButton.alpha = 0;
//    if (self.taskImages.count == 0) {
//        _moreRightButton.alpha = 0;
//    } else if (self.taskImages.count >= 1) {
//        _moreRightButton.alpha = alph;
//    }
    
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
    
    _dottedPageControl.currentPage = path.row;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    return self.taskImageCollectionView.frame.size;
}

#pragma mark -
#pragma mark Rotation handling methods

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:
(NSTimeInterval)duration {
    
    // Fade the collectionView out
    [self.taskImageCollectionView setAlpha:0.0f];
    
    // Suppress the layout errors by invalidating the layout
    [self.taskImageCollectionView.collectionViewLayout invalidateLayout];
    
    // Calculate the index of the item that the collectionView is currently displaying
    CGPoint currentOffset = [self.taskImageCollectionView contentOffset];
    self.currentIndex = currentOffset.x / self.taskImageCollectionView.frame.size.width;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    // Force realignment of cell being displayed
    CGSize currentSize = self.taskImageCollectionView.bounds.size;
    float offset = self.currentIndex * currentSize.width;
    [self.taskImageCollectionView setContentOffset:CGPointMake(offset, 0)];
    
    // Fade the collectionView back in
    [UIView animateWithDuration:0.125f animations:^{
        [self.taskImageCollectionView setAlpha:1.0f];
    }];
    
}

@end
