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
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSUserCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserCell" forIndexPath:indexPath];
 
    CSUserRealmModel* user = [CSUserRealmModel allObjectsInRealm:_sessionManager.peerHistoryRealm][indexPath.row];

    cell.avatarImage.image = [UIImage imageNamed:user.getPicture];
    cell.displayLabel.text = user.displayName;
    [cell.avatarImage.layer setCornerRadius:35.0f];
    cell.avatarImage.layer.masksToBounds = YES;
    //cell.backgroundColor = ([_sessionManager.currentConnectedPeers valueForKey:userName])? [UIColor greenColor]: [UIColor redColor];
    
    return cell;
}
@end
