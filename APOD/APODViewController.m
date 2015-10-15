//
//  APODViewController.m
//  APOD
//
//  Created by Dillan Laughlin on 10/8/15.
//  Copyright © 2015 Enharmonic inc. All rights reserved.
//

#import "APODViewController.h"
#import "APODDataStore.h"
#import "APODAsset.h"

@import QuartzCore;
@import AVKit;
@import AVFoundation;

static void * APODViewControllerKVOContext = &APODViewControllerKVOContext;

static NSString *kAPODCachedImageModelKeypath = @"cachedImageAsset";
static NSString *kAPODCachedImageURLKeypath = @"cachedImageAsset.cachedAssetURL";
static NSString *kAPODCachedVideoModelKeypath = @"cachedVideoAsset";
static NSString *kAPODCachedVideoURLKeypath = @"cachedVideoAsset.cachedAssetURL";

@interface APODViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *watchVideoButton;

@end

@implementation APODViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handleTapGestureRecognizer:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    [self.overlayView setAlpha:0.0];
    [self.overlayView setHidden:YES];
    [self.overlayView.layer setMasksToBounds:YES];
    [self.overlayView.layer setCornerRadius:10.0];
    
    [self observeCachedAssets];
}

-(void)dealloc
{
    [self unobserveCachedAssets];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[APODDataStore sharedDataStore] updateCachedAssetsWithCompletionHandler:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textView flashScrollIndicators];
}

-(void)reloadData
{
    APODAsset *imageAsset = [[APODDataStore sharedDataStore] cachedImageAsset];
    NSData *imageData = [NSData dataWithContentsOfURL:imageAsset.cachedAssetURL];
    UIImage *image = [UIImage imageWithData:imageData];
    APODAsset *videoAsset = [[APODDataStore sharedDataStore] cachedVideoAsset];
    NSURL *videoURL = [videoAsset assetURL];
    [self.titleLabel setText:imageAsset.title];
    [self.textView setText:imageAsset.explanation];
    [self.imageView setImage:image];
    [self.watchVideoButton setEnabled:(videoURL != nil)];
    NSString *title = (videoAsset.title.length > 0) ? [NSString stringWithFormat:@"Watch: %@", videoAsset.title] : @"Downloading Video";
    [self.watchVideoButton setTitle:title forState:(UIControlStateNormal)];
}

-(void)toggleOverlay
{
    BOOL isHidden = [self.overlayView isHidden];
    CGFloat alpha = isHidden ? 1.0 : 0.0;
    [UIView animateWithDuration:0.2
                     animations:^{
                         [self.overlayView setAlpha:alpha];
                     } completion:^(BOOL finished) {
                         if (finished)
                         {
                             [self.overlayView setHidden:!isHidden];
                         }
                     }];
}

#pragma mark - Actions

-(IBAction)watchVideoButtonTapped:(id)sender
{
    [self presentCachedVideo];
}

-(void)handleTapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (tapGestureRecognizer.state == UIGestureRecognizerStateRecognized)
    {
        [self toggleOverlay];
    }
}

#pragma mark - KVO

-(void)observeCachedAssets
{
    APODDataStore *dataStore = [APODDataStore sharedDataStore];
    [dataStore addObserver:self
                forKeyPath:kAPODCachedImageModelKeypath
                   options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                   context:APODViewControllerKVOContext];
    
    [dataStore addObserver:self
                forKeyPath:kAPODCachedImageURLKeypath
                   options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                   context:APODViewControllerKVOContext];
    
    [dataStore addObserver:self
                forKeyPath:kAPODCachedVideoModelKeypath
                   options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                   context:APODViewControllerKVOContext];
    
    [dataStore addObserver:self
                forKeyPath:kAPODCachedVideoURLKeypath
                   options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                   context:APODViewControllerKVOContext];
}

-(void)unobserveCachedAssets
{
    APODDataStore *dataStore = [APODDataStore sharedDataStore];
    [dataStore removeObserver:self
                   forKeyPath:kAPODCachedImageModelKeypath
                      context:APODViewControllerKVOContext];
    [dataStore removeObserver:self
                   forKeyPath:kAPODCachedImageURLKeypath
                      context:APODViewControllerKVOContext];
    [dataStore removeObserver:self
                   forKeyPath:kAPODCachedVideoModelKeypath
                      context:APODViewControllerKVOContext];
    [dataStore removeObserver:self
                   forKeyPath:kAPODCachedVideoURLKeypath
                      context:APODViewControllerKVOContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == APODViewControllerKVOContext)
    {
        [self reloadData];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 

-(void)presentCachedVideo
{
    APODAsset *videoAsset = [[APODDataStore sharedDataStore] cachedVideoAsset];
    AVPlayer *player = [[AVPlayer alloc] initWithURL:videoAsset.assetURL];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    [playerViewController setPlayer:player];
    [self presentViewController:playerViewController animated:YES completion:^{
        [player play];
    }];
}

@end
