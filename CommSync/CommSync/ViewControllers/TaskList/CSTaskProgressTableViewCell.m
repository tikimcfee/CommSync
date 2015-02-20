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
#import "CSTaskTransientObjectStore.h"
#import "CSSessionDataAnalyzer.h"

@implementation CSTaskProgressTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithSourceInformation:(CSNewTaskResourceInformationContainer *)container {

    // Set label view traits
    self.taskStatusLabel.layer.borderWidth = 0.5f;
    self.taskStatusLabel.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.5].CGColor;
    self.taskStatusLabel.layer.cornerRadius = self.frame.size.height/4.f;
    
    self.taskStatusLabel.layer.masksToBounds = NO;
    self.taskStatusLabel.layer.shouldRasterize = YES;
    
    // Set label view text
    NSMutableAttributedString* label = [self.taskStatusLabel.attributedText mutableCopy];
    NSDictionary* attributes = [label attributesAtIndex:0 effectiveRange:nil];
    
    NSString* peerName = [NSString stringWithFormat:@"\n%@..", container.peerID.displayName];
    NSMutableAttributedString* sourceName = [[NSMutableAttributedString alloc] initWithString:peerName attributes:attributes];
    
    [label appendAttributedString:sourceName];
    
    [self.taskStatusLabel setAttributedText:label];
    
    // Set progress ring state and observations
    _loadProgress = container.progressObject;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.loadProgress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    });
    
    [_progressRingView setProgressRingWidth:4];
    [_progressRingView setBackgroundRingWidth:4];
    _progressRingView.layer.cornerRadius = 30;
    
    [_progressRingView setPrimaryColor:[[UIColor blueColor] colorWithAlphaComponent:0.5]];
    [_progressRingView setSecondaryColor:[UIColor colorWithRed:0.415 green:0.611 blue:1.000 alpha:1.000]];
    
    [_progressRingView setProgress:0.0 animated:NO];
    _progressRingView.showPercentage = YES;
    
    // Set completion block and state information
    _resourceName = container.resourceName;
    _sourceTask = container;
    
    [self registerForNotifications];
}

- (void)registerForNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newTaskStreamFinished:)
                                                 name:kCSDidFinishReceivingResourceWithName
                                               object:nil];
    
}
- (void)deregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:kCSDidFinishReceivingResourceWithName
                                                object:nil];
    
    [_loadProgress removeObserver:self forKeyPath:@"fractionCompleted" context:nil];
}

- (void) cleanup {
    [self deregisterNotifications];
    
    self.progressRingView = nil;
    self.taskStatusLabel = nil;
    self.loadProgress = nil;
    self.sourceTask = nil;
    self.resourceName = nil;
    self.progressCompletionBlock = nil;
}

- (void) dealloc {
    NSLog(@"Task progress cell deallocated.");
}

- (void) newTaskStreamFinished:(NSNotification*)notification {
    NSDictionary* info = notification.userInfo;
    NSString* resourceName = [info valueForKey:@"resourceName"];
    if( ![resourceName isEqualToString:_resourceName] ) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        CSTaskProgressTableViewCell* strSelf = weakSelf;
        strSelf.progressRingView.showPercentage = NO;
        [strSelf.progressRingView performAction:M13ProgressViewActionSuccess animated:YES];
        
        if(strSelf.progressCompletionBlock)
        {
            strSelf.progressCompletionBlock(self);
            [strSelf cleanup];
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [_progressRingView setProgress:_loadProgress.fractionCompleted animated:YES];
}

@end
