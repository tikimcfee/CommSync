//
//  CSRealmFactory.h
//  CommSync
//
//  Created by CommSync on 4/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface CSRealmFactory : NSObject

+ (RLMRealm*)peerHistoryRealm;
+ (RLMRealm*)chatMessageRealm;
+ (RLMRealm*)privateMessageRealm;
+ (RLMRealm*)taskRealm;
+ (RLMRealm*)incomingTaskRealm;

@end
