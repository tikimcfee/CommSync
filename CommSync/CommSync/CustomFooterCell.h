//
//  CustomFooterCell.h
//  CommSync
//
//  Created by Student on 2/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSTaskRealmModel.h"
#import "CSCommentRealmModel.h"

@interface CustomFooterCell : UIView
@property (weak, nonatomic) IBOutlet UITextField *commentField;
@property (strong, nonatomic) CSTaskRealmModel *sourceTask;
@property (weak, nonatomic) RLMRealm* realm;

- (IBAction)addComment:(id)sender;

@end
