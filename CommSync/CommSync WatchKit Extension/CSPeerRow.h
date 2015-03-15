//
//  CSPeerRow.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface CSPeerRow : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *userLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *statusLabel;

@end
