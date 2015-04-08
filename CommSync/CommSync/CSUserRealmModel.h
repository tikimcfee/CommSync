//
//  CSUserRealmModel.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/4/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Realm/Realm.h>

@interface CSUserRealmModel : RLMObject <NSCoding>


//@property (strong, nonatomic) NSString* peerID;
@property (strong, nonatomic) NSData* peerID;
@property (strong, nonatomic) NSString* displayName;
@property int unreadMessages;

- (instancetype)initWithMessage:(NSData *)peerID withDisplayName: (NSString*) display;
- (void) addMessage;
- (void) removeMessages;
- (NSString*) getMessageNumber;

@end
