//
//  CSTaskDetailViewController.m
//  CommSync
//
//  Created by Darin Doria on 1/21/15.
//  Copyright (c) 2015 AppsByDLI. All rights reserved.
//

#import "CSTaskDetailViewController.h"
#import "CustomHeaderCell.h"
#import "CSCommentRealmModel.h"
#import "CustomFooterCell.h"
#import <Realm/Realm.h>
#import "CSTaskCreationViewController.h"

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

//header size just a temp value

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 400;
}

//initiate the header
-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //creates the header
    CustomHeaderCell* headerCell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell"];
    
    //sets the
    headerCell.titleLabel.text = self.sourceTask.taskTitle;
    headerCell.descriptionLabel.text = self.sourceTask.taskDescription;
    headerCell.priorityLabel.text = self.sourceTask.taskTitle;
    
    switch (self.sourceTask.taskPriority) {
        case 2:
            headerCell.priorityColor.backgroundColor = [UIColor redColor];
            headerCell.priorityLabel.text = @"High Priority";
            break;
        
        case 1:
            headerCell.priorityColor.backgroundColor = [UIColor yellowColor];
            headerCell.priorityLabel.text = @"Standard Priority";
            break;
        
        //if green is selected or nothing is selected the task defaults to low priority
        default:
            headerCell.priorityColor.backgroundColor = [UIColor greenColor];
            headerCell.priorityLabel.text = @"Low Priority";
            break;
    }
    
    return headerCell;
}



//as many cells as the number of comments
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.sourceTask.comments count];
}

//inserts the comments into the cells one comment per cell
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
    
    CSCommentRealmModel *comment = [self.sourceTask.comments objectAtIndex:indexPath.row];
    
    
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    NSString *newDateString = [outputFormatter stringFromDate:comment.time];
    
    
    cell.textLabel.text = [NSString stringWithFormat: @"(ID: %@) %@ time %@", comment.UID, comment.text, newDateString];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    //cell.textLabel.text = comment.text;
    return cell;
}


//footer size

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 200;
}

//initiate the header
-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    CustomFooterCell* footerCell = [tableView dequeueReusableCellWithIdentifier:@"FooterCell"];
    footerCell.sourceTask = _sourceTask;
    return footerCell;
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


- (IBAction)resfresh:(id)sender {
      [self.tableView reloadData];
}


//pushes a modal edit view on top
- (IBAction)editTask:(id)sender {
    [self performSegueWithIdentifier:@"editModal" sender:self];
}

//sends a reference to the current view controller to the create page so that it can be modified
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"editModal"])
    {
        CSTaskCreationViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:[CSTaskDetailViewController class]])
        {
            [vc setTaskScreen:sender];
        }
    }
}
@end