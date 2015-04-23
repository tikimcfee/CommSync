//
//  CSTaskMediaCreationViewController.m
//  CommSync
//
//  Created by Student on 4/22/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskMediaCreationViewController.h"
#import "CSAudioPlotViewController.h"
#import "UIColor+FlatColors.h"
#import "IonIcons.h"
#import "CSPictureController.h"
#import "CSSessionDataAnalyzer.h"
#import "CSTaskImageCollectionViewCell.h"
#import "UIImage+normalize.h"

#define kTaskImageCollectionViewCell @"TaskImageCollectionViewCell"

@interface CSTaskMediaCreationViewController () 
@property (strong, nonatomic) IBOutlet UIButton *addImageButton;
@property (assign, nonatomic) BOOL imageProcessingComplete;

// Image picker
@property (strong, nonatomic) UIImagePickerController* imagePicker;
@property (strong, nonatomic) IBOutlet UICollectionView *taskImageCollection;
@property (strong, nonatomic) NSMutableArray* taskImages;

// VC for audio recording
@property (weak, nonatomic) CSAudioPlotViewController* audioRecorder;
@property (strong, nonatomic) IBOutlet UIImageView *micImage;

// Realm
@property (strong, nonatomic) CSTaskRealmModel* pendingTask;

@end

@implementation CSTaskMediaCreationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imageProcessingComplete = YES;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeViewAndSave)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.taskImages = [NSMutableArray new];
    
    self.addImageButton.layer.cornerRadius = 5.0;
    
    [self.micImage setImage:[IonIcons imageWithIcon:ion_ios_mic iconColor:[UIColor flatCloudsColor] iconSize:35.0f imageSize:CGSizeMake(50.0, 60.0)]];
    
    [self setupCollectionView];
    
    self.addImageButton.tintColor = [UIColor flatCloudsColor];
    self.addImageButton.backgroundColor = [UIColor flatWetAsphaltColor];
    [self.addImageButton setImage:[IonIcons imageWithIcon:ion_ios_camera size:35.0f color:[UIColor flatCloudsColor]] forState:UIControlStateNormal];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"CSAudioPlotViewController"]) {
        
        self.audioRecorder = (CSAudioPlotViewController*)[segue destinationViewController];
        self.audioRecorder.fileNameSansExtension = self.pendingTask.concatenatedID;
        
    } else if ([segue.identifier isEqualToString:@"enlargedPictureController"]) {
        
        CSPictureController* picture = segue.destinationViewController;
        picture.taskImage = sender;
        
    }
}

- (void) configureWithPendingTask:(CSTaskRealmModel *)task {
    self.pendingTask = task;
}

-(void)setupCollectionView {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:0.0f];
    [flowLayout setMinimumLineSpacing:0.0f];
    [self.taskImageCollection setPagingEnabled:YES];
    [self.taskImageCollection setCollectionViewLayout:flowLayout];
    self.taskImageCollection.backgroundColor = [UIColor clearColor];
    self.taskImageCollection.layer.cornerRadius = 8;
    self.taskImageCollection.clipsToBounds = YES;
}

#pragma mark - Image Picker Delegate
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

- (void) closeViewAndSave {
    
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

    self.pendingTask.TRANSIENT_audioDataURL = self.audioRecorder.fileOutputURL;
    self.pendingTask.tag = @"";
    self.pendingTask.completed = false;
    if(self.pendingTask.TRANSIENT_audioDataURL) {
        CSTaskMediaRealmModel* newMedia = [[CSTaskMediaRealmModel alloc] init];
        newMedia.mediaType = CSTaskMediaType_Audio;
        newMedia.mediaData = [NSData dataWithContentsOfURL:self.pendingTask.TRANSIENT_audioDataURL];
        [self.pendingTask.taskMedia addObject: newMedia];
    }
    
    [[CSRealmFactory taskRealm] beginWriteTransaction];
    [[CSRealmFactory taskRealm] addObject:self.pendingTask];
    [[CSRealmFactory taskRealm] commitWriteTransaction];
    
    [[CSSessionDataAnalyzer sharedInstance:nil] sendMessageToAllPeersForNewTask:self.pendingTask];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
