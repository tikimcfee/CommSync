//
//  CSUserDetailView.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface CSUserDetailView : UIViewController
@property (strong, nonatomic) MCPeerID* peerID;
@property (strong, nonatomic) NSString* displayName;
@end
