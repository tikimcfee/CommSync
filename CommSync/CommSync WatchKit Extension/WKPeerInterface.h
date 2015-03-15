//
//  WKPeerinterfaceController.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WKPeerInterface : WKInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceTable *peerTable;
@property (copy, nonatomic) NSMutableDictionary *peerList;


- (void)configureTableWithData: (NSDictionary *) peers;
- (void)sendRequest;
@end
