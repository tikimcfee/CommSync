//
//  UserSelectionView.m
//  CommSync
//
//  Created by Anna Stavropoulos on 4/17/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "UserSelectionView.h"
#import "AppDelegate.h"
#import "CSUserCollectionCell.h"
#import "CSUserRealmModel.h"

@interface UserSelectionView ()
@property (strong, nonatomic) AppDelegate *app;
@property (strong, nonatomic) CSSessionManager* sessionManager;
@end

@implementation UserSelectionView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.app= (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.sessionManager = _app.globalSessionManager;
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    
    //gets the max size that can fit confortably in the frame and evenly spaces them
    int wide = (self.view.frame.size.width / 100);
    int height = (self.view.frame.size.height / 100);
    float widthBuffer = (self.view.frame.size.width - (100 * wide)) / (1 + wide);
    float heightBuffer = (self.view.frame.size.height - (100 * height)) / (1 + height);
    [collectionViewLayout setSectionInset:UIEdgeInsetsMake( heightBuffer, widthBuffer, heightBuffer, widthBuffer)];
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
  return  [[CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm] count] - 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSUserCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserCell" forIndexPath:indexPath];
 
    CSUserRealmModel* user = [CSUserRealmModel objectsInRealm:_sessionManager.peerHistoryRealm where:@"displayName != %@", _sessionManager.myPeerID.displayName][indexPath.row];
    cell.avatarImage.image = [UIImage imageNamed:user.getPicture];
    cell.displayLabel.text = user.displayName;
    [cell.avatarImage.layer setCornerRadius:35.0f];
    cell.avatarImage.layer.masksToBounds = YES;
    //cell.backgroundColor = ([_sessionManager.currentConnectedPeers valueForKey:userName])? [UIColor greenColor]: [UIColor redColor];
    
    return cell;
}
@end
