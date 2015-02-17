//
//  CSTaskProgressTableViewCell.m
//  CommSync
//
//  Created by CommSync on 2/16/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskProgressTableViewCell.h"

@implementation CSTaskProgressTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithSourceInformation:(NSDictionary *)task andIndexPath:(NSIndexPath*)path; {

    // Set label view traits
    self.taskStatusLabel.layer.borderWidth = 0.5f;
    self.taskStatusLabel.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.5].CGColor;
    self.taskStatusLabel.layer.cornerRadius = self.frame.size.height/4.f;
    
    self.taskStatusLabel.layer.masksToBounds = NO;
    self.taskStatusLabel.layer.shouldRasterize = YES;
    
    // Set label view text
    NSMutableAttributedString* label = [self.taskStatusLabel.attributedText mutableCopy];
    NSDictionary* attributes = [label attributesAtIndex:0 effectiveRange:nil];
    
    NSString* peerName = [NSString stringWithFormat:@"\n%@..", [task valueForKey:@"peerName"]];
    NSMutableAttributedString* sourceName = [[NSMutableAttributedString alloc] initWithString:peerName attributes:attributes];
    
    [label appendAttributedString:sourceName];
    
    [self.taskStatusLabel setAttributedText:label];
    
    // Set progress ring state and observations
    _loadProgress = [task valueForKey:@"progress"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_loadProgress addObserver:self
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
    _progressCompletionBlock = [task valueForKey:@"callback"];
    _pathToSelf = path;
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [_progressRingView setProgress:_loadProgress.fractionCompleted animated:YES];
    
    __weak typeof(self) weakSelf = self;
    if(_loadProgress.fractionCompleted == 1.0) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.progressRingView performAction:M13ProgressViewActionSuccess animated:YES];
                if(weakSelf.progressCompletionBlock) {
                    weakSelf.progressCompletionBlock(weakSelf.pathToSelf);
                };
                
            });
    }
}

@end
