//
//  DownloadManager.h
//  BGTransferDemo
//
//  Created by Hovhannes Safaryan on 2/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadManager : NSObject<NSURLSessionDelegate>

+ (DownloadManager *)sharedManager;

@property(nonatomic, readonly) NSArray *downloadingFiles;
@property(nonatomic) NSURLSession *session;

@property (nonatomic, readonly) NSURL *docDirectoryURL;



@end
