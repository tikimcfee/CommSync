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

- (void)configureWithSourceInformation:(NSDictionary *)task; {
    NSMutableAttributedString* label = [self.taskStatusLabel.attributedText copy];
    NSDictionary* attributes = [label attributesAtIndex:0 effectiveRange:nil];
    
    NSString* peerName = [task valueForKey:@"peerName"];
    NSAttributedString* sourceName = [[NSAttributedString alloc] initWithString:peerName attributes:attributes];
    
    [label appendAttributedString:sourceName];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.taskStatusLabel setAttributedText:label];
    });
    
    [_progressRingView setProgressRingWidth:2];
    [_progressRingView setPrimaryColor:[UIColor blueColor]];
    [_progressRingView setSecondaryColor:[UIColor redColor]];
    [_progressRingView setProgress:0 animated:NO];
    [_progressRingView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.5]];
    _progressRingView.showPercentage = YES;
    
}

@end
