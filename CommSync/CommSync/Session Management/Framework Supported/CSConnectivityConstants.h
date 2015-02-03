//
//  CSConnectivityConstants.h
//  CommSync
//
//  Created by CommSync on 2/2/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Network information
#define kAPPLICATIONNETWORKNAME @"CommSyncP2P_DLI"

// Notification constants
#define kPeerChangedStateNotification @"PEER_CHANGED_STATE"

// Sent data types
#define kIncomingDataTypeSingleTaskModel 1
#define kIncomingDataTypeMultipleTaskModels 2
#define kIncomingDataTypeStandardText 3
#define kIncomingDataTypeImageMedia 4
#define kIncomingDataTypeAudioMedia 5
#define kIncomingDataTypeVideoMedia 6


@protocol CSConnectivityConstants <NSObject>

@end