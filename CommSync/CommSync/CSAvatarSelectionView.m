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
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    
    //gets the max size that can fit confortably in the frame and evenly spaces them
    int wide = (self.view.frame.size.width / 100);
    int height = (self.view.frame.size.height / 100);
    float widthBuffer = (self.view.frame.size.width - (100 * wide)) / (1 + wide);
    float heightBuffer = (self.view.frame.size.height - (100 * height)) / (1 + height);
//    [collectionViewLayout setSectionInset:UIEdgeInsetsMake( heightBuffer, widthBuffer, heightBuffer, widthBuffer)];
    
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _sessionManager = _app.globalSessionManager;
    array = @[@"Avatar0", @"Avatar1", @"Avatar2", @"Avatar3", @"Avatar4", @"Avatar5", @"Avatar6", @"Avatar7", @"Avatar8", @"Avatar9", @"Avatar10", @"Avatar11", @"Avatar12", @"Avatar13", @"Avatar14", @"Avatar15", @"Avatar16", @"Avatar17", @"Avatar18", @"Avatar19", @"Avatar20", @"Avatar21", @"Avatar22", @"Avatar23", @"Avatar24", @"Avatar25", @"Avatar26", @"Avatar27" ];
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
   return [array count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSAvatarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AvatarCell" forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[CSAvatarCell alloc] init];
    }
    [cell.avatarImage setImage:[UIImage imageNamed:[array objectAtIndex:indexPath.row]]];
    
    [cell.layer setCornerRadius:50.0f];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger temp = indexPath.row;
    [_sessionManager updateAvatar:temp];
    [self.navigationController popViewControllerAnimated:YES];
}
@end

