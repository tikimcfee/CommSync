//
//  UserSelectionView.h
//  CommSync
//
//  Created by Anna Stavropoulos on 4/17/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSUserRealmModel.h"

@protocol CSAssignUserDelegate <NSObject>

- (void) assignUser:( NSString* )personID;

@end

@interface CSUserSelectionViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) id <CSAssignUserDelegate> saveDelegate;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
- (IBAction)Cancel:(id)sender;

@end
