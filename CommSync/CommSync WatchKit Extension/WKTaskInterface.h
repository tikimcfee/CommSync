//
//  WKTaskInterface.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>


@interface WKTaskInterface : WKInterfaceController
- (void)sendRequest;
- (void)configureTableWithData: (NSDictionary *) peers;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *taskTable;

@end
