//
//  CSTaskTableViewCell.h
//  CommSync
//
//  Created by Darin Doria on 1/22/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"

@interface CSTaskTableViewCell : UITableViewCell
@property (strong, nonatomic) CSTaskRealmModel *sourceTask;

- (void)configureWithSourceTask:(CSTaskRealmModel *)task;
@end