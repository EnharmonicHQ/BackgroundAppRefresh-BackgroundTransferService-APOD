//
//  APODDataFetcher.h
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ENHDataFetcherDelegate;

@interface ENHDataFetcher : NSObject

-(instancetype)initWithSharedContainerIdentifer:(NSString *)sharedContainerIdentifier NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id <ENHDataFetcherDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sharedContainerIdentifier;

// Fetching

-(void)fetchJSONObjectFromURL:(NSURL *)jsonURL
              taskDescription:(NSString *)taskDescription
            completionHandler:(void (^)(id jsonObject, NSData *data, NSError *error))completionHandler;

-(NSURLSessionDownloadTask *)downloadFileFromURL:(NSURL *)fileURL
                                 taskDescription:(NSString *)taskDescription
                               completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

-(NSURLSessionDownloadTask * )downloadFileFromURL:(NSURL *)fileURL
                                  taskDescription:(NSString *)taskDescription;

-(NSURLSessionDownloadTask *)backgroundDownloadFileFromURL:(NSURL *)fileURL
                                           taskDescription:(NSString *)taskDescription;

// Background Transfer Service
-(void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

@end

@protocol ENHDataFetcherDelegate <NSObject>

-(void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location;

-(void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didCompleteWithError:(NSError *)error;

@end

