//
//  APODDataFetcher.m
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//
//  Storing info via NSURLProtocol inspired by: https://gist.github.com/dtorres/46780d9db0af4cea1c57

#import "ENHDataFetcher.h"

static NSString * const kENHDataFetcherUserInfoKey = @"kENHDataFetcherUserInfoKey";

@interface ENHDataFetcher () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSMutableDictionary *completionHandlerDictionary;
@property (nonatomic, copy, readwrite) NSString *sharedContainerIdentifier;

@end

@implementation ENHDataFetcher

- (instancetype)init
{
    return [self initWithSharedContainerIdentifer:nil];
}

-(instancetype)initWithSharedContainerIdentifer:(NSString *)sharedContainerIdentifier
{
    self = [super init];
    if (self)
    {
        _sharedContainerIdentifier = [sharedContainerIdentifier copy];
    }
    
    return self;
}

#pragma mark - Session Configuration

+(NSString *)backgroundSessionIdentifier
{
    static NSString *backgroundSessionIdentifier = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
        NSString *bundleIdentifier = [plist valueForKey:@"CFBundleIdentifier"];
        backgroundSessionIdentifier = [bundleIdentifier stringByAppendingString:@".BackgroundSession"];
    });
    
    return backgroundSessionIdentifier;
}

-(NSURLSession *)backgroundURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSString *backgroundSessionIdentifier = [[self class] backgroundSessionIdentifier];
        
        NSURLSessionConfiguration *backgroundSessionConfiguration = nil;
        
        backgroundSessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backgroundSessionIdentifier];
        [backgroundSessionConfiguration setSharedContainerIdentifier:self.sharedContainerIdentifier];
        
        session = [NSURLSession sessionWithConfiguration:backgroundSessionConfiguration
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

-(NSURLSession *)foregroundURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *foregroundSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        [foregroundSessionConfiguration setSharedContainerIdentifier:self.sharedContainerIdentifier];
        session = [NSURLSession sessionWithConfiguration:foregroundSessionConfiguration
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

-(NSURLSession *)blockForegroundURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *foregroundSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        [foregroundSessionConfiguration setSharedContainerIdentifier:self.sharedContainerIdentifier];
        session = [NSURLSession sessionWithConfiguration:foregroundSessionConfiguration
                                                delegate:nil
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

#pragma mark - Fetching

-(void)fetchJSONObjectFromURL:(NSURL *)jsonURL
              taskDescription:(NSString *)taskDescription
            completionHandler:(void (^)(id jsonObject, NSData *data, NSError *error))completionHandler
{
    NSParameterAssert(jsonURL);
    NSParameterAssert(taskDescription);
    NSParameterAssert(completionHandler);
    
    NSURLSession *session = [self foregroundURLSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:jsonURL];
    [request setValue:@"application/JSON" forHTTPHeaderField:@"Accept"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpResponse statusCode];
            NSRange acceptedStatusRange = NSMakeRange(200, 100);
            if (NSLocationInRange(statusCode, acceptedStatusRange) && data.length > 0)
            {
                NSError *jsonError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:&jsonError];
                
                NSString *stringRep = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"URL: %@\nResponse:\n%@", jsonURL, stringRep);
                
                if (jsonObject && completionHandler)
                {
                    completionHandler(jsonObject, data, nil);
                }
                else if (jsonError)
                {
                    if (completionHandler)
                    {
                        completionHandler(nil, nil, jsonError);
                    }
                    NSLog(@"JSON Error: %@", jsonError);
                }
            }
        }
        else if (error)
        {
            NSLog(@"Fetch  Error: %@", error);
            if (completionHandler)
            {
                completionHandler(nil, nil, error);
            }
        }
    }];
    
    [dataTask setTaskDescription:taskDescription];
    [dataTask resume];
}

-(NSURLSessionDownloadTask *)downloadFileFromURL:(NSURL *)fileURL
                                 taskDescription:(NSString *)taskDescription
                               completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSession *session = [self blockForegroundURLSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:fileURL completionHandler:completionHandler];
    [downloadTask setTaskDescription:taskDescription];
    [downloadTask resume];
    
    return downloadTask;
}

-(NSURLSessionDownloadTask * )downloadFileFromURL:(NSURL *)fileURL
                                  taskDescription:(NSString *)taskDescription
                                         userInfo:(NSDictionary *)userInfo
{
    return [self downloadFileFromURL:fileURL taskDescription:taskDescription userInfo:userInfo useBackgroundTransferService:NO];
}

-(NSURLSessionDownloadTask *)backgroundDownloadFileFromURL:(NSURL *)fileURL
                                           taskDescription:(NSString *)taskDescription
                                                  userInfo:(NSDictionary *)userInfo
{
    return [self downloadFileFromURL:fileURL taskDescription:taskDescription userInfo:userInfo useBackgroundTransferService:YES];
}

-(NSURLSessionDownloadTask *)downloadFileFromURL:(NSURL *)fileURL
                                 taskDescription:(NSString *)taskDescription
                                        userInfo:(NSDictionary *)userInfo
                    useBackgroundTransferService:(BOOL)useBackgroundTransferService
{
    NSURLSession *session = useBackgroundTransferService ? [self backgroundURLSession] : [self foregroundURLSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    if (userInfo)
    {
        [NSURLProtocol setProperty:userInfo forKey:kENHDataFetcherUserInfoKey inRequest:request];
    }
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    [downloadTask setTaskDescription:taskDescription];
    
    NSAssert([session delegate] == self, @"self should be the delegate");
    
    [downloadTask resume];
    
    return downloadTask;
}

#pragma mark - NSURLSessionDownloadDelegate

-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSParameterAssert([self delegate]);
    
    if ([self.delegate respondsToSelector:@selector(dataFetcher:downloadTask:didFinishDownloadingToURL:userInfo:)])
    {
        NSDictionary *userInfo = [NSURLProtocol propertyForKey:kENHDataFetcherUserInfoKey
                                                     inRequest:downloadTask.originalRequest];
        [self.delegate dataFetcher:self downloadTask:downloadTask didFinishDownloadingToURL:location userInfo:userInfo];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSParameterAssert([self delegate]);
    
    if ([self.delegate respondsToSelector:@selector(dataFetcher:downloadTask:didCompleteWithError:userInfo:)])
    {
        NSDictionary *userInfo = [NSURLProtocol propertyForKey:kENHDataFetcherUserInfoKey
                                                     inRequest:task.originalRequest];
        
        [self.delegate dataFetcher:self downloadTask:(NSURLSessionDownloadTask *)task didCompleteWithError:error userInfo:userInfo];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSParameterAssert([self delegate]);
    
    if ([self.delegate respondsToSelector:@selector(dataFetcher:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:userInfo:)])
    {
        NSDictionary *userInfo = [NSURLProtocol propertyForKey:kENHDataFetcherUserInfoKey
                                                     inRequest:downloadTask.originalRequest];
        
        [self.delegate dataFetcher:self
                      downloadTask:downloadTask
                      didWriteData:bytesWritten
                 totalBytesWritten:totalBytesWritten
         totalBytesExpectedToWrite:totalBytesExpectedToWrite
                          userInfo:userInfo];
    }
}

#pragma mark - Background Transfer Service

-(void)handleEventsForBackgroundURLSession:(NSString *)identifier
                         completionHandler:(void (^)())completionHandler
{
    // Re-establish session configuration to get delegate callbacks.
    NSURLSession *backgroundSession = [self backgroundURLSession];
    NSAssert([backgroundSession delegate] == self, @"Self should be the delegate");
    
    // Store the completion handler to call upon completion.
    NSAssert([self.completionHandlerDictionary objectForKey:identifier] == nil,
             @"Multiple handlers for a given session identifier. This should not happen.");
    [self.completionHandlerDictionary setObject:completionHandler forKey:identifier];
}

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSString *identifier = [session.configuration identifier];
   if (identifier)
    {
        void (^ completionHandler)() = [self.completionHandlerDictionary objectForKey:identifier];
        
        if (completionHandler)
        {
            [self.completionHandlerDictionary removeObjectForKey:identifier];
            completionHandler();
        }
    }
}

@end
