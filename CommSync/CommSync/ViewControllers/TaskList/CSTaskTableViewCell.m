//
//  CSTaskTableViewCell.m
//  CommSync
//
//  Created by Darin Doria on 1/22/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskTableViewCell.h"
#import "UIColor+FlatColors.h"

@interface CSTaskTableViewCell ()
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UIView *priorityColorView;

@end

@implementation CSTaskTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)configureWithSourceTask:(CSTaskRealmModel *)task
{
    self.sourceTask = task;
    self.title.text = task.taskTitle;
    self.assignmentLabel.text = task.assignedID;
    switch (task.taskPriority) {
        case CSTaskPriorityHigh:
            self.priorityColorView.backgroundColor = [UIColor kTaskHighPriorityColor];
            break;
        case CSTaskPriorityMedium:
            self.priorityColorView.backgroundColor = [UIColor kTaskMidPriorityColor];
            break;
        default:
            self.priorityColorView.backgroundColor = [UIColor kTaskLowPriorityColor];
            break;
    }
}

@end
