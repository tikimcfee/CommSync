//
//  CSTaskProgressTableViewCell.h
//  CommSync
//
//  Created by CommSync on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"
#import "M13ProgressViewRing.h"

@interface CSTaskProgressTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet M13ProgressViewRing *progressRingView;
@property (strong, nonatomic) IBOutlet UILabel *taskStatusLabel;
@property (strong, nonatomic) NSDictionary *sourceTask;

- (void)configureWithSourceInformation:(NSDictionary *)task;

@end
