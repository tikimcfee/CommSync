//
//  CSIncomingTaskRealmModel.h
//  CommSync
//
//  Created by Ivan Lugo on 4/12/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>
#import "CSTaskRealmModel.h"
#import "CSSessionDataAnalyzer.h"
#import "CSTaskProgressTableViewCell.h"

@interface CSIncomingTaskRealmModel : RLMObject

@property NSString* taskObservationString;
@property NSString* trueTaskName;
@property NSString* peerDisplayName;

// Ignore properties

@end
