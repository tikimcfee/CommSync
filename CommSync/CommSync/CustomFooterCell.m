//
//  CustomFooterCell.m
//  CommSync
//
//  Created by Student on 2/7/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CustomFooterCell.h"

@implementation CustomFooterCell

- (void)awakeFromNib {
    // Initialization code
    _realm = [RLMRealm defaultRealm];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)addComment:(id)sender {
    
    if([self.commentField.text  isEqual: @""]) return;
    
    NSLog(@"addcomment");
    CSCommentRealmModel *comment = [CSCommentRealmModel new];
    comment.UID = @"added comment";
    comment.text = self.commentField.text;
    comment.time = 3;
    
    [_realm beginWriteTransaction];
    [_sourceTask addComment:comment];
    [_realm commitWriteTransaction];
  
}
@end
