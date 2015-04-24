//
//  CSAvatarSelectionView.m
//  CommSync
//
//  Created by Student on 4/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSAvatarSelectionView.h"
#import "CSAvatarCell.h"
#import "AppDelegate.h"
#import "CSUserRealmModel.h"
#import "CSSessionManager.h"

@implementation CSAvatarSelectionView {
    NSArray *array;
    CSSessionManager *_sessionManager;
    AppDelegate *_app;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
  
    //gets the max size that can fit confortably in the frame and evenly spaces them
    int wide = (self.view.frame.size.width / 100) ;
    int height = (self.view.frame.size.height / 100);
    float widthBuffer = (self.view.frame.size.width - (100 * wide)) / (1 + wide);
    float heightBuffer = (self.view.frame.size.height -  (100 * height)) / (1 + height);
    [collectionViewLayout setSectionInset:UIEdgeInsetsMake( heightBuffer /2, widthBuffer, heightBuffer / 2, widthBuffer)];
    collectionViewLayout.minimumInteritemSpacing = widthBuffer;
    collectionViewLayout.minimumLineSpacing = heightBuffer;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _sessionManager = _app.globalSessionManager;
}


-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
   return 12;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSAvatarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AvatarCell" forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[CSAvatarCell alloc] init];
    }
    NSNumber* stringName = [NSNumber numberWithLong:indexPath.row + 1];
    NSString* avatar = [NSString stringWithFormat:@"Avatar %d",[stringName intValue]];
    [cell.avatarImage setImage:[UIImage imageNamed:avatar]];
    
    [cell.layer setCornerRadius:50.0f];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger temp = indexPath.row + 1;
    [_sessionManager updateAvatar:temp];
    [self.navigationController popViewControllerAnimated:YES];
}
@end

