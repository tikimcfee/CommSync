//
//  CSPeerHistoryRealmModel.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>

@interface CSPeerHistoryRealmModel : RLMObject


@property (strong, nonatomic) NSString* peerID;
@property (strong, nonatomic) NSString* dispalyID;

- (instancetype)initWithMessage:(NSString *)peerID byUser:(NSString *)displayName;

@end
