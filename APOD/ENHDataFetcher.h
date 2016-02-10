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

/**
 *  Initializes a newly allocated data fetcher with the sahred container identifer used by the app.
 *
 *  @param sharedContainerIdentifier The identifier of the shared data container into which files in background sessions should be downloaded.
 *
 *  @return A newly allocated data fetcher. 
 */
-(instancetype)initWithSharedContainerIdentifer:(NSString *)sharedContainerIdentifier NS_DESIGNATED_INITIALIZER;

/**
 *  The delegate that will be sent progress, completion, and error messages.
 */
@property (nonatomic, weak) id <ENHDataFetcherDelegate> delegate;

/**
 *  The identifier of the shared data container into which files in background sessions should be downloaded.
 */
@property (nonatomic, copy, readonly) NSString *sharedContainerIdentifier;

#pragma mark - Fetching

/**
 *  Fetches a JSON object from the specified URL.
 *
 *  @param jsonURL           A `NSURL` pointing to the remote JSON resource.
 *  @param taskDescription   A descriptive label for the task.
 *  @param completionHandler The completion handler called with the jsonObject upon sucess, otherwise nil.
 */
-(void)fetchJSONObjectFromURL:(NSURL *)jsonURL
              taskDescription:(NSString *)taskDescription
            completionHandler:(void (^)(id jsonObject, NSData *data, NSError *error))completionHandler;

/**
 *  Creates a foreground download task that retrieves the contents of the specified URL, saves the results to a file, and calls a handler upon completion.
 *
 *  @param fileURL           A `NSURL` pointing to the remote file.
 *  @param taskDescription   A descriptive label for the task.
 *  @param completionHandler The completion handler called with the location of the downloaded file on disk upon sucess, otherwise nil. The downloaded file should be moved before returning from the completion handler.
 *
 *  @return a `NSURLSessionDownloadTask` that represents a download to local storage.
 */
-(NSURLSessionDownloadTask *)downloadFileFromURL:(NSURL *)fileURL
                                 taskDescription:(NSString *)taskDescription
                               completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

/**
 *  Creates a foreground download task that retrieves the contents of the specified URL.
 *
 *  @param fileURL         A `NSURL` pointing to the remote file.
 *  @param taskDescription A descriptive label for the task.
 *  @param userInfo        A `NSDictionary` object that conforms to the `NSCoding` protocol. This dictionary is useful for supplying context data with a download task. This user info dictionary will be passed back in the `ENHDataFetcherDelegate` methods.
 *
 *  @return a `NSURLSessionDownloadTask` that represents a download to local storage.
 */
-(NSURLSessionDownloadTask * )downloadFileFromURL:(NSURL *)fileURL
                                  taskDescription:(NSString *)taskDescription
                                         userInfo:(NSDictionary *)userInfo;

/**
 *  Creates a background download task that retrieves the contents of the specified URL.
 *
 *  @param fileURL         A `NSURL` pointing to the remote file.
 *  @param taskDescription A descriptive label for the task.
 *  @param userInfo        A `NSDictionary` object that conforms to the `NSCoding` protocol. This dictionary is useful for supplying context data with a download task. This user info dictionary will be passed back in the `ENHDataFetcherDelegate` methods.
 *
 *  @return a `NSURLSessionDownloadTask` that represents a download to local storage.
 */
-(NSURLSessionDownloadTask *)backgroundDownloadFileFromURL:(NSURL *)fileURL
                                           taskDescription:(NSString *)taskDescription
                                                  userInfo:(NSDictionary *)userInfo;

#pragma mark - Background Transfer Service

/**
 *  Handles reattaching to a background session. Typicalled called from the app delegates `application: handleEventsForBackgroundURLSession:completionHandler:` method.
 *
 *  @param identifier        The identifier of the NSURLSession.
 *  @param completionHandler The completion handler that should be called when the session finishes.
 */
-(void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

@end

@protocol ENHDataFetcherDelegate <NSObject>

/**
 *  Sent upon successful download.
 *
 *  @param dataFetcher  The calling `ENHDataFetcher`.
 *  @param downloadTask A descriptive label for the task.
 *  @param location     The location on the disk were the downloaded data currently resides. The data should be moved prior to returning from this method.
 *  @param userInfo     The user info dictionary with context data that was passed when the download was initiated.
 */
-(void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
          userInfo:(NSDictionary *)userInfo;

/**
 *  Sent upon download failure.
 *
 *  @param dataFetcher  The calling `ENHDataFetcher`.
 *  @param downloadTask A descriptive label for the task.
 *  @param error        An `NSError` object describing the issue encountered while attempting to download the file.
 *  @param userInfo     The user info dictionary with context data that was passed when the download was initiated.
 */
-(void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didCompleteWithError:(NSError *)error
          userInfo:(NSDictionary *)userInfo;

@optional

/**
 *  Sent periodically to notify the delegate of download progress.
 *
 *  @param dataFetcher               The calling `ENHDataFetcher`.
 *  @param downloadTask              A descriptive label for the task.
 *  @param bytesWritten              The number of bytes most recently written.
 *  @param totalBytesWritten         The total number of bytes written.
 *  @param totalBytesExpectedToWrite The total number of bytes expected.
 *  @param userInfo                  The user info dictionary with context data that was passed when the download was initiated.
 */
- (void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
           userInfo:(NSDictionary *)userInfo;

@end

