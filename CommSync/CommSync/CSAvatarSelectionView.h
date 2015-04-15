//
//  CSAvatarSelectionView.h
//  CommSync
//
//  Created by Student on 4/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSAvatarSelectionView : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end
