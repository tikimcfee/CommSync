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

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _sessionManager = _app.globalSessionManager;
    array = @[ @"Avatar0", @"Avatar1", @"Avatar2" ];
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
    cell.backgroundColor = [UIColor redColor];
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

