//
//  CSTaskRow.h
//  CommSync
//
//  Created by Anna Stavropoulos on 3/14/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface CSTaskRow : NSObject
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *taskName;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *colorLabel;


@end
