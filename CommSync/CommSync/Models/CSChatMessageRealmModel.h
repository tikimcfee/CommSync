//
//  CSMessageRealmModel.h
//  CommSync
//
//  Created by Darin Doria on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>

@interface CSChatMessageRealmModel : RLMObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *messageText;
@property (nonatomic, strong, readonly) NSDate *createdAt;
@property (nonatomic, strong, readonly) NSString *createdBy;
@property (nonatomic, strong, readonly) NSString* recipient;


- (instancetype)initWithMessage:(NSString *)message byUser:(NSString *)username toUser: (NSString*)recipient;

@end
