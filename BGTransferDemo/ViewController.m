//
//  ViewController.m
//  BGTransferDemo
//
//  Created by Gabriel Theodoropoulos on 25/3/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "ViewController.h"
#import "FileDownloadInfo.h"
#import "AppDelegate.h"
#import "DownloadManager.h"


// Define some constants regarding the tag values of the prototype cell's subviews.
#define CellLabelTagValue               20
#define CellStartPauseButtonTagValue    30
#define CellStopButtonTagValue          40
#define CellProgressBarTagValue         50
#define CellLabelReadyTagValue          60


@interface ViewController ()

@property (nonatomic, strong) NSArray *data;

@end



@implementation ViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    // Make self the delegate and datasource of the table view.
    self.tblFiles.delegate = self;
    self.tblFiles.dataSource = self;
    
    // Disable scrolling in table view.
    self.tblFiles.scrollEnabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadProgress:) name:@"download_progress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinished:) name:@"download_finished" object:nil];
}

-(NSURLSession *)session {
    return [[DownloadManager sharedManager] session];
}

-(NSURL *)docDirectoryURL {
    return [[DownloadManager sharedManager] docDirectoryURL];
}

#pragma mark - download manager listeners
-(void)downloadProgress:(NSNotification *)notification {
    FileDownloadInfo *fdi = notification.userInfo[@"file_info"];
    NSUInteger index = [self.data indexOfObject:fdi];
    
    // Get the progress view of the appropriate cell and update its progress.
    UITableViewCell *cell = [self.tblFiles cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
    progressView.progress = fdi.downloadProgress;
}

-(void)downloadFinished:(NSNotification *)notification {
    FileDownloadInfo *fdi = notification.userInfo[@"file_info"];
    NSUInteger index = [self.data indexOfObject:fdi];
    // Reload the respective table view row using the main thread.
    [self.tblFiles reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                         withRowAnimation:UITableViewRowAnimationNone];
}

-(NSArray *)data {
    return [[DownloadManager sharedManager] downloadingFiles];
}


#pragma mark - UITableView Delegate and Datasource method implementation

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"idCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"idCell"];
    }
    
    // Get the respective FileDownloadInfo object from the arrFileDownloadData array.
    FileDownloadInfo *fdi = [self.data objectAtIndex:indexPath.row];
    
    // Get all cell's subviews.
    UILabel *displayedTitle = (UILabel *)[cell viewWithTag:10];
    UIButton *startPauseButton = (UIButton *)[cell viewWithTag:CellStartPauseButtonTagValue];
    UIButton *stopButton = (UIButton *)[cell viewWithTag:CellStopButtonTagValue];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
    UILabel *readyLabel = (UILabel *)[cell viewWithTag:CellLabelReadyTagValue];
    
    NSString *startPauseButtonImageName;
    
    // Set the file title.
    displayedTitle.text = fdi.fileTitle;
    
    // Depending on whether the current file is being downloaded or not, specify the status
    // of the progress bar and the couple of buttons on the cell.
    if (!fdi.isDownloading) {
        // Hide the progress view and disable the stop button.
        progressView.hidden = YES;
        stopButton.enabled = NO;
        
        // Set a flag value depending on the downloadComplete property of the fdi object.
        // Using it will be shown either the start and stop buttons, or the Ready label.
        BOOL hideControls = (fdi.downloadComplete) ? YES : NO;
        startPauseButton.hidden = hideControls;
        stopButton.hidden = hideControls;
        readyLabel.hidden = !hideControls;
        
        startPauseButtonImageName = @"play-25";
    }
    else{
        // Show the progress view and update its progress, change the image of the start button so it shows
        // a pause icon, and enable the stop button.
        progressView.hidden = NO;
        progressView.progress = fdi.downloadProgress;
        
        stopButton.enabled = YES;
        
        startPauseButtonImageName = @"pause-25";
    }
    
    // Set the appropriate image to the start button.
    [startPauseButton setImage:[UIImage imageNamed:startPauseButtonImageName] forState:UIControlStateNormal];
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0;
}


#pragma mark - IBAction method implementation

-(UITableViewCell *)cellFromSubview:(UIView *)subview {
    while (subview.superview != nil) {
        if ([subview isKindOfClass:[UITableViewCell class]]) {
            return (UITableViewCell *)subview;
        }
        subview = subview.superview;
    }
    return nil;
}

- (IBAction)startOrPauseDownloadingSingleFile:(id)sender {
    UITableViewCell *containerCell = (UITableViewCell *)[self cellFromSubview:sender];
    if (containerCell != nil) {
        
        // Get the row (index) of the cell. We'll keep the index path as well, we'll need it later.
        NSIndexPath *cellIndexPath = [self.tblFiles indexPathForCell:containerCell];
        int cellIndex = cellIndexPath.row;
        
        // Get the FileDownloadInfo object being at the cellIndex position of the array.
        FileDownloadInfo *fdi = [self.data objectAtIndex:cellIndex];
        
        // The isDownloading property of the fdi object defines whether a downloading should be started
        // or be stopped.
        if (!fdi.isDownloading) {
            // This is the case where a download task should be started.
            
            // Create a new task, but check whether it should be created using a URL or resume data.
            if (fdi.taskIdentifier == -1) {
                // If the taskIdentifier property of the fdi object has value -1, then create a new task
                // providing the appropriate URL as the download source.
                fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
                
                // Keep the new task identifier.
                fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
                
                // Start the task.
                [fdi.downloadTask resume];
            }
            else{
            	// Create a new download task, which will use the stored resume data.
                fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
                [fdi.downloadTask resume];
                
                // Keep the new download task identifier.
                fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            }
        }
        else{
            // Pause the task by canceling it and storing the resume data.
            [fdi.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                if (resumeData != nil) {
                    fdi.taskResumeData = [[NSData alloc] initWithData:resumeData];
                }
            }];
        }
        
        // Change the isDownloading property value.
        fdi.isDownloading = !fdi.isDownloading;
        
        // Reload the table view.
        [self.tblFiles reloadRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}


- (IBAction)stopDownloading:(id)sender {
    // Get the container cell.
    UITableViewCell *containerCell = (UITableViewCell *)[self cellFromSubview:sender];
    if ([containerCell isKindOfClass:[UITableViewCell class]]) {
        
        // Get the row (index) of the cell. We'll keep the index path as well, we'll need it later.
        NSIndexPath *cellIndexPath = [self.tblFiles indexPathForCell:containerCell];
        int cellIndex = cellIndexPath.row;
        
        // Get the FileDownloadInfo object being at the cellIndex position of the array.
        FileDownloadInfo *fdi = [self.data objectAtIndex:cellIndex];
        
        // Cancel the task.
        [fdi.downloadTask cancel];
        
        // Change all related properties.
        fdi.isDownloading = NO;
        fdi.taskIdentifier = -1;
        fdi.downloadProgress = 0.0;
        
        // Reload the table view.
        [self.tblFiles reloadRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}


- (IBAction)startAllDownloads:(id)sender {
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[self.data count]; i++) {
        FileDownloadInfo *fdi = [self.data objectAtIndex:i];
        
        // Check if a file is already being downloaded or not.
        if (!fdi.isDownloading) {
            // Check if should create a new download task using a URL, or using resume data.
            if (fdi.taskIdentifier == -1) {
                fdi.downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            }
            else{
                fdi.downloadTask = [self.session downloadTaskWithResumeData:fdi.taskResumeData];
            }
            
            // Keep the new taskIdentifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            
            // Start the download.
            [fdi.downloadTask resume];
            
            // Indicate for each file that is being downloaded.
            fdi.isDownloading = YES;
        }
    }
    
    // Reload the table view.
    [self.tblFiles reloadData];
}


- (IBAction)stopAllDownloads:(id)sender {
    // Access all FileDownloadInfo objects using a loop.
    for (int i=0; i<[self.data count]; i++) {
        FileDownloadInfo *fdi = [self.data objectAtIndex:i];
        
        // Check if a file is being currently downloading.
        if (fdi.isDownloading) {
            // Cancel the task.
            [fdi.downloadTask cancel];
            
            // Change all related properties.
            fdi.isDownloading = NO;
            fdi.taskIdentifier = -1;
            fdi.downloadProgress = 0.0;
            fdi.downloadTask = nil;
        }
    }
    
    // Reload the table view.
    [self.tblFiles reloadData];
}


- (IBAction)initializeAll:(id)sender {
    // Access all FileDownloadInfo objects using a loop and give all properties their initial values.
    for (int i=0; i<[self.data count]; i++) {
        FileDownloadInfo *fdi = [self.data objectAtIndex:i];
        
        if (fdi.isDownloading) {
            [fdi.downloadTask cancel];
        }
        
        fdi.isDownloading = NO;
        fdi.downloadComplete = NO;
        fdi.taskIdentifier = -1;
        fdi.downloadProgress = 0.0;
        fdi.downloadTask = nil;
    }
    
    // Reload the table view.
    [self.tblFiles reloadData];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Get all files in documents directory.
    NSArray *allFiles = [fileManager contentsOfDirectoryAtURL:[[DownloadManager sharedManager] docDirectoryURL]
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:nil];
    for (int i=0; i<[allFiles count]; i++) {
        [fileManager removeItemAtURL:[allFiles objectAtIndex:i] error:nil];
    }
}

@end
