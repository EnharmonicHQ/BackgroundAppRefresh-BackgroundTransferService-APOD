//
//  ENHDataFetcher.h
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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

/**
 *  Resumes a download task in the foreground.
 *
 *  @param resumeData      `NSData` blob used to resume a download task.
 *  @param taskDescription A descriptive label for the task.
 *  @param userInfo        A `NSDictionary` object that conforms to the `NSCoding` protocol. This dictionary is useful for supplying context data with
 *
 *  @return a `NSURLSessionDownloadTask` that represents a download to local storage.
 */
- (NSURLSessionDownloadTask *)downloadFileWithResumeData:(NSData *)resumeData
                                         taskDescription:(NSString *)taskDescription
                                                userInfo:(NSDictionary *)userInfo;

/**
 *  Resumes a download task in the background.
 *
 *  @param resumeData      `NSData` blob used to resume a download task.
 *  @param taskDescription A descriptive label for the task.
 *  @param userInfo        A `NSDictionary` object that conforms to the `NSCoding` protocol. This dictionary is useful for supplying context data with
 *
 *  @return a `NSURLSessionDownloadTask` that represents a download to local storage.
 */
- (NSURLSessionDownloadTask *)backgroundDownloadFileWithResumeData:(NSData *)resumeData
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
 *  @param averageThroughput         The average throughput in bytes per second. Calculated as an exponential moving average when the downlaod task is backed with a `NSMutableURLRequest`. Otherwise the throughput is calculated as an average over the lifetime of the request.
 *  @param userInfo                  The user info dictionary with context data that was passed when the download was initiated.
 */
- (void)dataFetcher:(ENHDataFetcher *)dataFetcher
       downloadTask:(NSURLSessionDownloadTask *)downloadTask
       didWriteData:(int64_t)bytesWritten
  totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
  averageThroughput:(int64_t)averageThroughput
           userInfo:(NSDictionary *)userInfo;

/**
 *  Notifies the delegate when a download resumes.
 *
 *  @param dataFetcher        The calling `ENHDataFetcher`.
 *  @param downloadTask       A descriptive label for the task.
 *  @param fileOffset         The byte position where the download begins resuming from.
 *  @param expectedTotalBytes The total number of bytes expected.
 */
- (void)dataFetcher:(ENHDataFetcher *)dataFetcher
       downloadTask:(NSURLSessionDownloadTask *)downloadTask
  didResumeAtOffset:(int64_t)fileOffset
 expectedTotalBytes:(int64_t)expectedTotalBytes
           userInfo:(NSDictionary *)userInfo;

@end

