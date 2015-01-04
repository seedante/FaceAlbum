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
#import "SDECrytalBallLayout.h"
@import AssetsLibrary;

static NSString * const cellIdentifier = @"Cell";
static NSInteger const MAXCellCount = 15;

@interface SDEScanRoomViewController ()
@property (nonatomic)PhotoScanManager *photoScanManager;
@property (nonatomic)SDEPhotoFileFilter *photoFileFilter;
@property (nonatomic)ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSArray *assetsToScan;
@property (nonatomic) NSMutableArray *avators;
@property (nonatomic, assign) NSUInteger totalCount;
@property (nonatomic, assign) NSUInteger faceCount;
@property (nonatomic, assign) BOOL isScaning;
@property (nonatomic, assign) NSInteger startIndex;
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
    self.isScaning = NO;
    self.startIndex = 0;
    self.avators = [NSMutableArray new];
    self.faceCount = 0;
    self.photoScanManager = [PhotoScanManager sharedPhotoScanManager];
    self.managedObjectContext = [[Store sharedStore] managedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Face"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"section == 0"];
    [fetchRequest setPredicate:predicate];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (results.count>0) {
        self.photoScanManager.numberOfItemsInFirstSection = results.count;
    }
    
    SDECrytalBallLayout *cryalBallLayout = [[SDECrytalBallLayout alloc] init];
    [self.faceCollectionView setCollectionViewLayout:cryalBallLayout];
    
    self.photoFileFilter = [SDEPhotoFileFilter sharedPhotoFileFilter];
    [self.photoFileFilter addObserver:self forKeyPath:@"photoAdded" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    //[self.photoFileFilter checkPhotoLibrary];
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    BOOL isFirstScan = [defaultConfig boolForKey:@"isFirstScan"];
    if (!isFirstScan) {
        self.assetsToScan = [self.photoFileFilter assetsNeedToScan];
        [self.assetCollectionView reloadData];
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.photoFileFilter removeObserver:self forKeyPath:@"photoAdded"];
    [self.photoFileFilter reset];
    NSLog(@"Detect %lu faces in this scan", (unsigned long)self.faceCount);
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
    self.isScaning = NO;
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:nil];
    }
    [self.managedObjectContext reset];
    [self performSelector:@selector(continueScan) withObject:nil afterDelay:0.5];
}

- (void)continueScan
{
    NSLog(@"continue Scan");
    self.isScaning = YES;
    [self enumerateScanAssetAtIndexPath:@(self.startIndex)];;
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
        [collectionView.collectionViewLayout invalidateLayout];
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
        }
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
    if (!self.isScaning) {
        self.isScaning = YES;
        [self.scanButton setTitle:@"Pause" forState:UIControlStateNormal];
        [self enumerateScanAssetAtIndexPath:@(self.startIndex)];
    }else{
        self.isScaning = NO;
        [self.scanButton setTitle:@"Continue" forState:UIControlStateNormal];
    }
    self.tabBarController.tabBar.hidden = YES;

}

- (void)enumerateScanAssetAtIndexPath:(NSNumber *)indexNumber
{
    if (indexNumber.integerValue == self.assetsToScan.count) {
        [self prepareForNextScene];
        return;
    }
    
    if (!self.isScaning) {
        return;
    }
    
    self.processIndicator.text = [NSString stringWithFormat:@"%ld/%lu", (long)self.startIndex, (unsigned long)self.assetsToScan.count];
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
            NSArray *detectedFaces = [self.photoScanManager allAvatorsInPhoto];
            self.faceCount += detectedFaces.count;
            [self.avators addObjectsFromArray:detectedFaces];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.faceCollectionView performBatchUpdates:^{
                    for (NSInteger i = self.faceCount - detectedFaces.count; i < self.faceCount; i++) {
                        [self.faceCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:i inSection:0]]];
                    }
                }completion:nil];
                
                if (self.faceCount > MAXCellCount) {
                    NSRange deleteRange;
                    deleteRange.location = 0;
                    deleteRange.length = self.faceCount - MAXCellCount;
                    self.faceCount = MAXCellCount;
                    [self.avators removeObjectsInRange:deleteRange];
                    NSMutableArray *indexPathArray = [[NSMutableArray alloc] initWithCapacity:deleteRange.length];
                    for (NSInteger j = 0; j < deleteRange.length; j++) {
                        [indexPathArray addObject:[NSIndexPath indexPathForItem:j inSection:0]];
                    }
                    [self.faceCollectionView performBatchUpdates:^{
                        [self.faceCollectionView deleteItemsAtIndexPaths:indexPathArray];
                    }completion:nil];
                }
            });
            
        }
    }else
        NSLog(@"Asset fetch error.");
    
    self.startIndex = index + 1;
    [self performSelector:@selector(enumerateScanAssetAtIndexPath:) withObject:@(self.startIndex) afterDelay:0.1];
}

- (void)prepareForNextScene
{
    [self configFirstScene:NO];
    [self.photoFileFilter reset];
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:nil];
    }
    [self.managedObjectContext reset];
    UIViewController *montageRoomVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MontageRoom"];
    [self.navigationController pushViewController:montageRoomVC animated:NO];
}

@end