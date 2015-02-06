//
//  CSTaskDetailViewController.m
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskDetailViewController.h"
#import "CustomHeaderCell.h"

@interface CSTaskDetailViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *taskImage;

@end

@implementation CSTaskDetailViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.titleLabel.text = self.sourceTask.taskTitle;
   // self.descriptionLabel.text = self.sourceTask.taskDescription;
    self.navigationBar.title = self.sourceTask.taskTitle;
    [self.sourceTask getAllImagesForTaskWithCompletionBlock:^void(BOOL didFinish) {
        if(didFinish) {
            //[self setImagesFromTask];
        }
    }];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 300;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CustomHeaderCell* headerCell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
    
    headerCell.titleLabel.text = self.sourceTask.taskTitle;
    headerCell.detailLabel.text = self.sourceTask.taskDescription;
    headerCell.priorityLabel.text = self.sourceTask.taskTitle;
    
    switch (self.sourceTask.taskPriority) {
        case 2:
            headerCell.priorityColor.backgroundColor = [UIColor redColor];
            break;
        
        case 1:
            headerCell.priorityColor.backgroundColor = [UIColor yellowColor];
            break;
            
        default:
            headerCell.priorityColor.backgroundColor = [UIColor greenColor];
            break;
    }
    
    return headerCell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    

    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
    
    
    cell.textLabel.text = @"this is a comment";
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - Callbacks and UI State
- (void)setImagesFromTask {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.sourceTask.TRANSIENT_taskImages.count > 0) {
            UIImage* img = [self.sourceTask.TRANSIENT_taskImages objectAtIndex:0];
            self.taskImage.image = img;
        }
    });
}




@end
