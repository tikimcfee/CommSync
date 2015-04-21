//
//  SlackTestViewController.h
//  CommSync
//
//  Created by Darin Doria on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "SLKTextViewController.h"
#import "CSTaskRealmModel.h"
#import "CSCommentRealmModel.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "CSUserRealmModel.h"

@interface SlackTestViewController : SLKTextViewController

@property (strong, nonatomic) CSTaskRealmModel *sourceTask;
@property (strong, nonatomic) CSUserRealmModel *peerID;

@end
