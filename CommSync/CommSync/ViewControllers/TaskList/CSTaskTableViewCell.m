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
//            self.priorityColorView.backgroundColor = [UIColor colorWithRed:0.626 green:0.081 blue:0.000 alpha:0.800];
            self.priorityColorView.backgroundColor = [UIColor flatPomegranateColor];
            break;
        case CSTaskPriorityMedium:
//            self.priorityColorView.backgroundColor = [UIColor colorWithRed:0.859 green:0.703 blue:0.000 alpha:0.800];
            self.priorityColorView.backgroundColor = [UIColor flatOrangeColor];
            break;
        default:
//            self.priorityColorView.backgroundColor = [UIColor colorWithRed:0.068 green:0.459 blue:0.006 alpha:0.800];
            self.priorityColorView.backgroundColor = [UIColor flatBelizeHoleColor];
            break;
    }
}

@end
