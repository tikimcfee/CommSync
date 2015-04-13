//
//  CSTaskListUpdateOperation.m
//  CommSync
//
//  Created by Ivan Lugo on 2/20/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskListUpdateOperation.h"
#import "TLIndexPathTools.h"

@interface CSTaskListUpdateOperation ()
@property (assign, atomic) BOOL tableviewDidFinishUpdates;
@end

@implementation CSTaskListUpdateOperation

- (void) main {
    if(!_tableviewToUpdate)
        return;
    
    _indexPathController.delegate = self;
    _tableviewDidFinishUpdates = NO;
    
    _reloadBlock();

    while(!_tableviewDidFinishUpdates)
    {
        [NSThread sleepForTimeInterval:0.5];
    }
}

- (void)controller:(TLIndexPathController *)controller didUpdateDataModel:(TLIndexPathUpdates *)updates
{
    __weak typeof(self) weakSelf = self;
    if(!weakSelf.tableviewIsVisible) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CSTaskListUpdateOperation* strSelf = weakSelf;
            [strSelf.tableviewToUpdate reloadData];
            strSelf.tableviewDidFinishUpdates = YES;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            CSTaskListUpdateOperation* strSelf = weakSelf;
            [updates performBatchUpdatesOnTableView:weakSelf.tableviewToUpdate
                                   withRowAnimation:UITableViewRowAnimationFade
                                         completion:^(BOOL finished) {
                                                 strSelf.tableviewDidFinishUpdates = YES;
                                         }];

        });
    }
}

@end
