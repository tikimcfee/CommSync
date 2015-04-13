//
//  CSTaskProgressTableViewCell.m
//  CommSync
//
//  Created by CommSync on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskProgressTableViewCell.h"
#import "CSSessionDataAnalyzer.h"
#import "CSSessionManager.h"
#import "CSSessionDataAnalyzer.h"
#import "CSIncomingTaskRealmModel.h"

@implementation CSTaskProgressTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithIdentifier:(NSString*)identifier {

    CSIncomingTaskRealmModel* incoming = [CSIncomingTaskRealmModel objectInRealm:[RLMRealm realmWithPath:[CSSessionManager incomingTaskRealmDirectory]]
                                                                   forPrimaryKey:identifier];
    
    // Set label view traits
    self.taskStatusLabel.layer.borderWidth = 0.5f;
    self.taskStatusLabel.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.5].CGColor;
    self.taskStatusLabel.layer.cornerRadius = self.frame.size.height/4.f;
    self.taskStatusLabel.layer.masksToBounds = NO;
    self.taskStatusLabel.layer.shouldRasterize = YES;
    
    // Set label view text
    NSMutableAttributedString* label = [self.taskStatusLabel.attributedText mutableCopy];
    NSDictionary* attributes = [label attributesAtIndex:0 effectiveRange:nil];
    
    NSString* peerName = [NSString stringWithFormat:@"\n%@..", incoming.peerDisplayName];
    NSMutableAttributedString* sourceName = [[NSMutableAttributedString alloc] initWithString:peerName attributes:attributes];
    [label appendAttributedString:sourceName];
    [self.taskStatusLabel setAttributedText:label];

    [_progressRingView setProgressRingWidth:4];
    [_progressRingView setBackgroundRingWidth:4];
    _progressRingView.layer.cornerRadius = 30;
    
    [_progressRingView setPrimaryColor:[[UIColor blueColor] colorWithAlphaComponent:0.5]];
    [_progressRingView setSecondaryColor:[UIColor colorWithRed:0.415 green:0.611 blue:1.000 alpha:1.000]];
    
    [_progressRingView setProgress:0.0 animated:NO];
    _progressRingView.showPercentage = YES;
    
    // Set completion block and state information
    _resourceName = incoming.taskObservationString;
    
    [self registerForNotifications];
}

- (void)registerForNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(observeProgressChanges:)
                                                 name:kCSReceivingProgressNotification
                                               object:nil];
}

- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) cleanup {
    [self deregisterNotifications];
    
    self.progressRingView = nil;
    self.taskStatusLabel = nil;
    self.resourceName = nil;
    self.progressCompletionBlock = nil;
}

- (void) dealloc {
    NSLog(@"Task progress cell deallocated.");
}

- (void)observeProgressChanges:(NSNotification*)notification {
    NSProgress* progress = [notification.userInfo valueForKey:@"progress"];
    if([[progress.userInfo valueForKey:kCSTaskObservationID] isEqualToString:_resourceName]) {
        if(progress.fractionCompleted == 1.0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _progressRingView.showPercentage = NO;
                [_progressRingView performAction:M13ProgressViewActionSuccess animated:YES];
                [_progressRingView setProgress:progress.fractionCompleted animated:YES];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                _progressRingView.showPercentage = YES;
                [_progressRingView performAction:M13ProgressViewActionNone animated:YES];
                [_progressRingView setProgress:progress.fractionCompleted animated:YES];
            });
        }

    }
}

@end
