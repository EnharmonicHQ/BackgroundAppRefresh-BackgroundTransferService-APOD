//
//  APODDataStore.h
//  APOD
//
//  Created by Dillan Laughlin on 10/9/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class APODAsset;
@class ENHDataFetcher;

typedef NS_ENUM (NSUInteger, APODDataStoreBackgroundFetchResult)
{
    APODDataStoreBackgroundFetchResultNewData,
    APODDataStoreBackgroundFetchResultNoData,
    APODDataStoreBackgroundFetchResultFailed
};

@interface APODDataStore : NSObject

+(instancetype)sharedDataStore;

@property (nonatomic, strong, readonly) ENHDataFetcher *dataFetcher;
@property (nonatomic, strong, readonly) APODAsset *cachedImageAsset;
@property (nonatomic, strong, readonly) APODAsset *cachedVideoAsset;

-(void)updateCachedAssetsWithCompletionHandler:(void (^)(APODDataStoreBackgroundFetchResult result, NSError *error))completionHandler;

@end
