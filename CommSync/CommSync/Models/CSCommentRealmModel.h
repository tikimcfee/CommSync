//
//  CSCommentRealmModel.h
//  CommSync
//
//  Created by Anna Stavropoulos on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>

@interface CSCommentRealmModel : RLMObject <NSCoding>

@property NSString* text;
@property NSString* UID;
@property NSDate* time;

- (instancetype)initWithMessage:(NSString *)message byUser:(NSString *)username;
@end

RLM_ARRAY_TYPE(CSCommentRealmModel)