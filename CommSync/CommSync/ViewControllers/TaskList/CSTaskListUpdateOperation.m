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
    
    __weak typeof(self) weakSelf = self;
    if(_updatesToPerform)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_updatesToPerform performBatchUpdatesOnTableView:weakSelf.tableviewToUpdate
                                             withRowAnimation:UITableViewRowAnimationFade
                                                   completion:^(BOOL finished) {
                    weakSelf.tableviewDidFinishUpdates = YES;
            }];
        });
        
    } else {
        _indexPathController.delegate = self;
        _tableviewDidFinishUpdates = NO;
        
        if(_reloadBlock)
            _reloadBlock(_sourceDataToRemove);
    }

    while(!_tableviewDidFinishUpdates)
    {
        [NSThread sleepForTimeInterval:0.5];
    }
}

- (void)controller:(TLIndexPathController *)controller didUpdateDataModel:(TLIndexPathUpdates *)updates
{
    _tableviewToUpdate.delegate = nil;
    
    __weak typeof(self) weakSelf = self;
    if(!weakSelf.tableviewIsVisible) {
//        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableviewToUpdate reloadData];
            weakSelf.tableviewDidFinishUpdates = YES;
//        });
    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
            [updates performBatchUpdatesOnTableView:weakSelf.tableviewToUpdate
                                   withRowAnimation:UITableViewRowAnimationFade
                                         completion:^(BOOL finished) {
                                                 weakSelf.tableviewDidFinishUpdates = YES;
                                         }];

//        });
    }
}

@end
