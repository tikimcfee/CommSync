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
@property (strong, nonatomic) NSString* uniqueID;
@property  NSInteger avatar;
@property  NSInteger unreadMessages;
@property  NSInteger unsentMessages;
@property  (strong, nonatomic) NSDate* lastUpdated;

- (instancetype)initWithMessage:(NSData *)peerID withDisplayName: (NSString*) display withID: (NSString*)uniqueID lastChanged: (NSDate*) changeTime;
- (void) addMessage;
- (void) removeMessages;
- (int) getMessageNumber;
- (void)addUnsent;
- (void)removeUnsent;
- (void) updateChangeTime;
- (NSString*) getPicture;
@end
