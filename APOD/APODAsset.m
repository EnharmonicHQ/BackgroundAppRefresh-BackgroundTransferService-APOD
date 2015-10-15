//
//  APODImage.m
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import "APODAsset.h"

@interface APODAsset ()

@property (nonatomic, strong, readwrite) NSURL *assetURL;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *explanation;

@end

@implementation APODAsset

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        NSString *imageURLString = dictionary[@"url"];
        _assetURL = [NSURL URLWithString:imageURLString];
        _title = dictionary[@"title"];
        _explanation = dictionary[@"explanation"];
    }
    
    return self;
}

@end
