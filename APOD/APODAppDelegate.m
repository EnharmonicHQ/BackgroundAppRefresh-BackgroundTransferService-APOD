//
//  APODAppDelegate.m
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import "APODAppDelegate.h"

#import "APODDataStore.h"
#import "ENHDataFetcher.h"

@interface APODAppDelegate ()

@end

@implementation APODAppDelegate


- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSTimeInterval minimumBackgroundFetchInterval = 60.0 * 60.0; // 1 Hour
    [application setMinimumBackgroundFetchInterval:minimumBackgroundFetchInterval];
    
    return YES;
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[APODDataStore sharedDataStore] updateCachedAssetsWithCompletionHandler:^(APODDataStoreBackgroundFetchResult result, NSError *error) {
        UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNewData;
        switch (result) {
            case APODDataStoreBackgroundFetchResultNewData:
                fetchResult = UIBackgroundFetchResultNewData;
                break;
                
            case APODDataStoreBackgroundFetchResultNoData:
                fetchResult = UIBackgroundFetchResultNoData;
                break;
                
            case APODDataStoreBackgroundFetchResultFailed:
                fetchResult = UIBackgroundFetchResultFailed;
                break;
                
            default:
                fetchResult = UIBackgroundFetchResultNewData;
                break;
        }
        if (completionHandler)
        {
            completionHandler(fetchResult);
        }
    }];
}

-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    [[[APODDataStore sharedDataStore] dataFetcher] handleEventsForBackgroundURLSession:identifier
                                                                     completionHandler:completionHandler];
}

@end
