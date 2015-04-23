//
//  UserSelectionView.m
//  CommSync
//
//  Created by Anna Stavropoulos on 4/17/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSUserSelectionViewController.h"
#import "AppDelegate.h"
#import "CSUserCollectionCell.h"
#import "CSUserRealmModel.h"
#import "UINavigationBar+CommSyncStyle.h"
#import <Foundation/Foundation.h>

@interface CSUserSelectionViewController ()
@property (strong, nonatomic) AppDelegate *app;
@property (strong, nonatomic) CSSessionManager* sessionManager;
@end

@implementation CSUserSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.app= (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    [_navigationBar setupCommSyncStyle];
    //gets the max size that can fit confortably in the frame and evenly spaces them
    float maxHeight = self.view.frame.size.height - _navigationBar.frame.size.height;
    float maxWidth = self.view.frame.size.width;
    int wide = (maxWidth / 100);
    int height = (maxHeight / 100);
    float widthBuffer = (maxWidth - (100 * wide)) / (1 + wide);
    float heightBuffer = (maxHeight - (100 * height)) / (1 + height);
    [collectionViewLayout setSectionInset:UIEdgeInsetsMake( heightBuffer / 2 + _navigationBar.frame.size.height, widthBuffer, heightBuffer / 2, widthBuffer)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[CSUserRealmModel allObjectsInRealm:[CSRealmFactory peerHistoryRealm] ] count]  + 1;
  
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSUserCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserCell" forIndexPath:indexPath];
    
    if(indexPath.row == 0){
        cell.avatarImage.image = [UIImage imageNamed:@"Avatar -1"];
        cell.displayLabel.text = @"Unassigned";
        [cell.avatarImage.layer setCornerRadius:(cell.avatarImage.frame.size.width / 2)];
        cell.avatarImage.layer.masksToBounds = YES;
        return cell;
    }
    
    CSUserRealmModel* user = [CSUserRealmModel allObjectsInRealm:[CSRealmFactory peerHistoryRealm]][indexPath.row - 1];
    
    cell.avatarImage.image = [UIImage imageNamed:user.getPicture];
    cell.displayLabel.text = user.displayName;
    [cell.avatarImage.layer setCornerRadius:(cell.avatarImage.frame.size.width / 2)];
    cell.avatarImage.layer.masksToBounds = YES;
    //cell.backgroundColor = ([_sessionManager.currentConnectedPeers valueForKey:userName])? [UIColor greenColor]: [UIColor redColor];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0 ) [self.saveDelegate assignUser:nil];
    
    else{
        CSUserRealmModel* person = [CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm][indexPath.row - 1];
        [self.saveDelegate assignUser:person.uniqueID];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Status Bar
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (IBAction)Cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end