//
//  SDViewController.m
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEScanRoomViewController.h"
#import "PhotoScanManager.h"
#import "SDEPhotoFileFilter.h"
#import "Store.h"
@import AssetsLibrary;

static NSString *cellIdentifier = @"Cell";

@interface SDEScanRoomViewController ()
@property (nonatomic)PhotoScanManager *photoScanManager;
@property (nonatomic)SDEPhotoFileFilter *photoFileFilter;
@property (nonatomic)ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSArray *assetsToScan;
@property (nonatomic) NSMutableArray *avators;
@property (nonatomic, assign) NSUInteger totalCount;
@property (nonatomic, assign) NSUInteger faceCount;
@property (weak, nonatomic) IBOutlet UILabel *processIndicator;
@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;


@end

@implementation SDEScanRoomViewController

#pragma mark - view prepare
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.tabBarController.tabBar.hidden = YES;
    self.faceCount = 0;
    self.photoScanManager = [PhotoScanManager sharedPhotoScanManager];
    self.managedObjectContext = [[Store sharedStore] managedObjectContext];
    self.photoFileFilter = [SDEPhotoFileFilter sharedPhotoFileFilter];
    [self.photoFileFilter addObserver:self forKeyPath:@"photoAdded" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.photoFileFilter checkPhotoLibrary];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.photoFileFilter removeObserver:self forKeyPath:@"photoAdded"];
    [super viewWillDisappear:animated];
}

- (ALAssetsLibrary *)photoLibrary
{
    if (_photoLibrary != nil) {
        return _photoLibrary;
    }
    _photoLibrary = [[ALAssetsLibrary alloc] init];
    return _photoLibrary;
}

- (void)configFirstScene:(BOOL)antiFinished
{
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    [defaultConfig setBool:antiFinished forKey:@"isFirstScan"];
    [defaultConfig synchronize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self cleanManagedObjectContext];
}

- (void)cleanManagedObjectContext
{
    NSLog(@"Clean ManagedObject");
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:nil];
    }
    [self.managedObjectContext reset];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([self.photoFileFilter isPhotoAdded]) {
        self.assetsToScan = [self.photoFileFilter assetsNeedToScan];
        [self.assetCollectionView reloadData];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    NSInteger numberOfItems = 0;
    if ([collectionView isEqual:self.assetCollectionView]) {
        numberOfItems = self.assetsToScan.count;
    }else{
        numberOfItems = self.faceCount;
    }
    //NSLog(@"item number: %ld", (long)numberOfItems);
    return numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    UICollectionViewCell *photoCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[photoCell viewWithTag:10];
    if ([collectionView isEqual:self.assetCollectionView]) {
        ALAsset *asset = (ALAsset *)[self.assetsToScan objectAtIndex:indexPath.item];
        imageView.image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
    }else{
        UIImage *avatorImage = (UIImage *)[self.avators objectAtIndex:indexPath.item];
        if (avatorImage) {
            imageView.image = avatorImage;
        }else
            NSLog(@"??");
    }
    return photoCell;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.assetCollectionView]) {
        [self.assetCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (IBAction)scanPhotos:(id)sender
{
    self.tabBarController.tabBar.hidden = YES;
    [self.scanButton setTitle:@"Scan..." forState:UIControlStateNormal];
    self.scanButton.enabled = NO;
    [self enumerateScanAssetAtIndexPath:@(0)];
}

- (void)enumerateScanAssetAtIndexPath:(NSNumber *)indexNumber
{
    if (indexNumber.integerValue == self.assetsToScan.count) {
        [self prepareForNextScene];
        return;
    }
    
    NSInteger index = indexNumber.integerValue;
    [self.assetCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    UICollectionViewCell *cell = [self.assetCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
    scale.duration = 0.4;
    scale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1)];
    [cell.layer addAnimation:scale forKey:@"scale"];
    
    ALAsset *asset = (ALAsset *)[self.assetsToScan objectAtIndex:index];
    if (asset) {
        BOOL faceDetected = [self.photoScanManager scanAsset:asset withDetector:FaceppFaceDetector];
        if (faceDetected) {
            NSArray *detectedFaces = [self.photoScanManager allFacesInPhoto];
            self.faceCount += detectedFaces.count;
            [self.avators addObjectsFromArray:detectedFaces];
            NSLog(@"fetch detected face.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.faceCollectionView performBatchUpdates:^{
                    for (NSInteger i = self.faceCount - detectedFaces.count; i < self.faceCount; i++) {
                        [self.faceCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:i inSection:0]]];
                    }
                }completion:nil];
            });
            
        }
    }else
        NSLog(@"Asset fetch error.");

    [self performSelector:@selector(enumerateScanAssetAtIndexPath:) withObject:@(index + 1) afterDelay:0.1];
    
}

- (void)prepareForNextScene
{
    [self configFirstScene:NO];
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:nil];
    }
    UIViewController *montageRoomVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MontageRoom"];
    [self.navigationController pushViewController:montageRoomVC animated:NO];
}

@end