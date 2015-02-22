//
//  CSMessageRealmModel.h
//  CommSync
//
//  Created by Darin Doria on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>

@interface CSChatMessageRealmModel : RLMObject <NSCoding>

@property NSString *text;
@property NSString *createdAt;
@property NSString *createdBy;

@end
