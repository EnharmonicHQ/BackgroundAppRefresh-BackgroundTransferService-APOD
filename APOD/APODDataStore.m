//
//  APODDataStore.m
//  APOD
//
//  Created by Dillan Laughlin on 10/9/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import "APODDataStore.h"
#import "ENHDataFetcher.h"
#import "APODAsset.h"

@interface APODDataStore () <ENHDataFetcherDelegate>

@property (nonatomic, strong, readwrite) APODAsset *cachedImageAsset;
@property (nonatomic, strong, readwrite) APODAsset *cachedVideoAsset;
@property (nonatomic, strong, readwrite) ENHDataFetcher *dataFetcher;

@end

@implementation APODDataStore

+(instancetype)sharedDataStore
{
    static dispatch_once_t onceQueue;
    static APODDataStore *sharedDataStore = nil;
    
    dispatch_once(&onceQueue, ^{
        sharedDataStore = [[self alloc] init];
    });
    
    return sharedDataStore;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _dataFetcher = [[ENHDataFetcher alloc] initWithSharedContainerIdentifer:nil];
        [_dataFetcher setDelegate:self];
        
        NSError *error = nil;
        [self loadCachedAssetDataError:&error];
    }
    
    return self;
}

#pragma - Cached Data

-(BOOL)loadCachedAssetDataError:(NSError **)error
{
    BOOL loaded = NO;
    
    NSData *cachedImageJSONData = [NSData dataWithContentsOfURL:[self.class cachedImageJSONURL]];
    if (cachedImageJSONData)
    {
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:cachedImageJSONData
                                                                       options:0
                                                                         error:error];
        if (jsonDictionary)
        {
            // Video
            NSDictionary *videoDictionary = jsonDictionary[@"video"];
            APODAsset *videoAsset = [[APODAsset alloc] initWithDictionary:videoDictionary];
            [self setCachedVideoAsset:videoAsset];
            
            // Image
            NSDictionary *imageDictionary = jsonDictionary[@"image"];
            APODAsset *imageAsset = [[APODAsset alloc] initWithDictionary:imageDictionary];
            NSURL *cachedImageURL = [self.class cachedAssetURLForRemoteURL:imageAsset.assetURL];
            if ([[NSFileManager defaultManager] fileExistsAtPath:cachedImageURL.path])
            {
                [imageAsset setCachedAssetURL:cachedImageURL];
            }
            
            if (jsonDictionary && imageAsset)
            {
                loaded = YES;
            }
            
            [self setCachedImageAsset:imageAsset];
        }
        
    }
    
    return loaded;
}

#pragma mark - Updating

-(void)updateCachedAssetsWithCompletionHandler:(void (^)(APODDataStoreBackgroundFetchResult result, NSError *error))completionHandler
{
    NSLog(@"-[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    
    __weak __typeof(self)weakSelf = self;
    [self.dataFetcher fetchJSONObjectFromURL:[self.class apodJSONURL]
                             taskDescription:@"APOD JSON Fetch"
                           completionHandler:^(id jsonObject, NSData *data, NSError *error) {
                               
                               if (jsonObject && [jsonObject isKindOfClass:NSDictionary.class])
                               {
                                   // Image
                                   NSDictionary *imageDictionary = jsonObject[@"image"];
                                   APODAsset *imageAsset = [[APODAsset alloc] initWithDictionary:imageDictionary];
                                   NSURL *cachedImageURL = [weakSelf.class cachedAssetURLForRemoteURL:imageAsset.assetURL];
                                   
                                   NSFileManager *fileManager = [NSFileManager defaultManager];
                                   if ([fileManager fileExistsAtPath:cachedImageURL.path])
                                   {
                                       // The image file is already cached.
                                       if (completionHandler)
                                       {
                                           completionHandler(APODDataStoreBackgroundFetchResultNoData, nil);
                                       }
                                   }
                                   else
                                   {
                                       NSURL *cachedImageJSONURL = [self.class cachedImageJSONURL];
                                       [data writeToURL:cachedImageJSONURL atomically:YES];
                                       [weakSelf setCachedImageAsset:imageAsset];
                                       
                                       [weakSelf.dataFetcher downloadFileFromURL:imageAsset.assetURL
                                                                 taskDescription:imageAsset.title
                                                               completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                                   
                                                                   NSError *outError = nil;
                                                                   
                                                                   APODDataStoreBackgroundFetchResult result = APODDataStoreBackgroundFetchResultNoData;
                                                                   if (location)
                                                                   {
                                                                       NSError *moveError = nil;
                                                                       if ([fileManager moveItemAtURL:location
                                                                                                toURL:cachedImageURL
                                                                                                error:&moveError])
                                                                       {
                                                                           [imageAsset setCachedAssetURL:cachedImageURL];
                                                                           result = APODDataStoreBackgroundFetchResultNewData;
                                                                       }
                                                                       else
                                                                       {
                                                                           NSLog(@"Move error: %@", moveError);
                                                                           outError = moveError;
                                                                           result = APODDataStoreBackgroundFetchResultFailed;
                                                                       }
                                                                   }
                                                                   else if (error)
                                                                   {
                                                                       NSLog(@"Download Error: %@", error);
                                                                       outError = error;
                                                                       result = APODDataStoreBackgroundFetchResultFailed;
                                                                   }
                                                                   
                                                                   if (completionHandler)
                                                                   {
                                                                       completionHandler(result, outError);
                                                                   }
                                                               }];
                                   }
                                   
                                   // Video
                                   NSDictionary *videoDictionary = jsonObject[@"video"];
                                   APODAsset *videoAsset = [[APODAsset alloc] initWithDictionary:videoDictionary];
                                   [weakSelf setCachedVideoAsset:videoAsset];
                                   [self.dataFetcher backgroundDownloadFileFromURL:videoAsset.assetURL
                                                                   taskDescription:videoAsset.title];
                               }
                               else
                               {
                                   if (error)
                                   {
                                       NSLog(@"JSON Fetch Error: %@", error);
                                   }
                                   
                                   if (completionHandler)
                                   {
                                       completionHandler(APODDataStoreBackgroundFetchResultFailed, error);
                                   }
                               }
                           }];
}

#pragma mark - APODDataFetcherDelegate

-(void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSURL *expectedRemoteURL = [self.cachedVideoAsset assetURL];
    if ([downloadTask.originalRequest.URL isEqual:expectedRemoteURL])
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *destinationURL = [self.class cachedAssetURLForRemoteURL:expectedRemoteURL];
        
        NSError *error = nil;
        if ([fileManager moveItemAtURL:location toURL:destinationURL error:&error])
        {
            [self.cachedVideoAsset setCachedAssetURL:destinationURL];
        }
        else if (error)
        {
            NSLog(@"Error: %@", error);
        }
    }
}

-(void)dataFetcher:(ENHDataFetcher *)dataFetcher
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didCompleteWithError:(NSError *)error
{
    if (error)
    {
        [self.cachedVideoAsset setCachedAssetURL:nil];
        NSLog(@"Error: %@", error);
    }
}

#pragma mark - URLs

+(NSURL *)apodJSONURL
{
    static NSURL *apodJSONURL = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSString *urlString = [NSString stringWithFormat:@"http://enharmonichq.com/test-data/apod-data/0/feed.json"];
        apodJSONURL = [NSURL URLWithString:urlString];
    });
    
    return apodJSONURL;
}

+(NSURL *)cachedImageJSONURL
{
    static NSURL *cachedImageJSONURL = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURL *applicationSupportDirectoryURL = [self applicationSupportDirectoryURL];
        cachedImageJSONURL = [applicationSupportDirectoryURL URLByAppendingPathComponent:@"feed.json"];
    });
    
    return cachedImageJSONURL;
}

+(NSURL *)cachedAssetURLForRemoteURL:(NSURL *)remoteImageURL
{
    NSURL *cachedImageURL = nil;
    
    NSString *filename = [remoteImageURL lastPathComponent];
    if (filename.length > 0)
    {
        NSURL *applicationSupportDirectoryURL = [self.class applicationSupportDirectoryURL];
        cachedImageURL = [applicationSupportDirectoryURL URLByAppendingPathComponent:filename];
    }
    
    return cachedImageURL;
}

+(NSURL *)applicationSupportDirectoryURL
{
    static NSURL *applicationSupportDirectoryURL = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSArray *directoryURLs = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                        inDomains:NSUserDomainMask];
        applicationSupportDirectoryURL = [directoryURLs lastObject];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:applicationSupportDirectoryURL.path])
        {
            [fileManager createDirectoryAtURL:applicationSupportDirectoryURL
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:nil];
        }
        
#if DEBUG
        NSLog(@"Application Support Directory: %@", applicationSupportDirectoryURL.path);
#endif
    });
    
    return applicationSupportDirectoryURL;
}

#pragma mark - 

-(void)setCachedImageAsset:(APODAsset *)cachedImageAsset
{
    if (_cachedImageAsset != cachedImageAsset)
    {
        if (_cachedImageAsset)
        {
            NSURL *cachedImageURL = [self.class cachedAssetURLForRemoteURL:_cachedImageAsset.assetURL];
            [[NSFileManager defaultManager] removeItemAtURL:cachedImageURL error:nil];
        }
        
        _cachedImageAsset = cachedImageAsset;
    }
}

-(void)setCachedVideoAsset:(APODAsset *)cachedVideoAsset
{
    if (_cachedVideoAsset != cachedVideoAsset)
    {
        if (_cachedVideoAsset)
        {
            NSURL *cachedAssetURL = [self.class cachedAssetURLForRemoteURL:_cachedVideoAsset.assetURL];
            [[NSFileManager defaultManager] removeItemAtURL:cachedAssetURL error:nil];
        }
        
        _cachedVideoAsset = cachedVideoAsset;
    }
}

@end
