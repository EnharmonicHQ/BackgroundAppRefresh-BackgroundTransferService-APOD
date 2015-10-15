//
//  APODImage.h
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APODAsset : NSObject

@property (nonatomic, strong, readonly) NSURL *assetURL;
@property (nonatomic, strong) NSURL *cachedAssetURL;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *explanation;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
