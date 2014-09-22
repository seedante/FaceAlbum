//
//  SDViewController.m
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEScanRoomViewController.h"
#import "PhotoCell.h"
#import "SDEFaceVCDataSource.h"
#import "PhotoScanManager.h"
#import "SDENewPhotoDetector.h"
@import AssetsLibrary;

static NSString *cellIdentifier = @"photoCell";
static NSString *segueIdentifier = @"enterMontageRoom";

@interface SDEScanRoomViewController ()
@property (nonatomic)SDEFaceVCDataSource *faceDataSource;
@property (nonatomic)PhotoScanManager *photoScanManager;
@property (nonatomic)ALAssetsLibrary *photoLibrary;
@property (nonatomic)NSMutableArray *allAssets;

@end

@implementation SDEScanRoomViewController
{
    int pipelineWorkIndex;
}

#pragma mark - view prepare
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.faceDataSource = [SDEFaceVCDataSource sharedDataSource];
    self.faceCollectionView.dataSource = self.faceDataSource;
    self.faceCollectionView.delegate = self.faceDataSource;
    self.faceDataSource.collectionView = self.faceCollectionView;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    //[self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:@"photoCell"];
    self.photoScanManager = [PhotoScanManager sharedPhotoScanManager];
    
    [self piplineInitialize];
}

- (void)piplineInitialize
{
    pipelineWorkIndex = 0;
    self.allAssets = [[NSMutableArray alloc] init];
    self.showAssets = [[NSMutableArray alloc] init];
    
    
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    BOOL isFirstScan = [defaultConfig boolForKey:@"isFirstScan"];
    if (isFirstScan) {
        NSLog(@"This is the firct scan");
        NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
        [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
            if (group && *stop != YES) {
                //NSURL *groupURL = (NSURL *)[group valueForProperty:ALAssetsGroupPropertyURL];
                NSLog(@"XXXGroup: %@", [group valueForProperty:ALAssetsGroupPropertyName]);
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                    if (asset && *stop != YES) {
                        if (self.showAssets.count < 3) {
                            [self.showAssets addObject:asset];
                        }else
                            [self.allAssets addObject:asset];
                    }
                }];
            }else{
                NSLog(@".......");
                [self.assetCollectionView reloadData];
            }
        } failureBlock:nil];
    }else{
        SDENewPhotoDetector *photoDetector = [SDENewPhotoDetector sharedPhotoDetector];
        if ([photoDetector shouldScanPhotoLibrary]) {
            NSLog(@"WORKAAAAAAAAAAAAA");
            NSArray *newAssets = [photoDetector assetsNeedToScan];
            if (newAssets.count > 0) {
                for (ALAsset *asset in newAssets) {
                    if (self.showAssets.count < 3) {
                        [self.showAssets addObject:asset];
                    }else
                        [self.allAssets addObject:asset];
                }
                NSLog(@"What happen again?");
                [self.assetCollectionView reloadData];
                NSLog(@"Asset need to scan: %d", self.allAssets.count);
                NSLog(@"Asset count: %d", self.showAssets.count);
                [photoDetector cleanData];
            }
        }else
            NSLog(@"There is NO new photo");
    }
    
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
    // Dispose of any resources that can be recreated.
    
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.showAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *photoCell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = (ALAsset *)[self.showAssets objectAtIndex:indexPath.item];
    photoCell.asset = asset;
    //NSLog(@"Size: %zuX%zu", CGImageGetWidth([asset aspectRatioThumbnail]), CGImageGetHeight([asset aspectRatioThumbnail]));
    
    return photoCell;
}

- (IBAction)showAllPhotos:(id)sender
{
    [self productionlineStart];
}


- (void)productionlineStart
{
    [self lineScan];
}

#pragma mark - production line work
- (void)lineScan
{
    if ([self.faceDataSource numberOfSectionsInCollectionView:self.faceCollectionView]) {
        [self.faceDataSource removeAllFaces];
        [self.faceCollectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
        NSLog(@"Remove previous faces");
    }
    
    //solution 1: uiview animation, just can't keep scale effect.
    if (pipelineWorkIndex > 0) {
        UICollectionViewCell *previousCell = [self.assetCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pipelineWorkIndex - 1 inSection:0]];
        previousCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }
    UICollectionViewCell *currentCell = [self.assetCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pipelineWorkIndex inSection:0]];
    currentCell.transform = CGAffineTransformMakeScale(1.5, 1.5);
    /*
    void (^scanAnimation)() = ^(){
        UICollectionViewLayoutAttributes *attribute = [self.assetCollectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:pipelineWorkIndex inSection:0]];
        attribute.transform3D = CATransform3DMakeScale(1.2, 1.2, 1.0);
    };
    [UIView transitionWithView:currentCell duration:0.5 options:UIViewAnimationOptionTransitionFlipFromRight animations:scanAnimation completion:nil];
     */
    
    /*
    //en, it can work without GCD.
    BOOL includeFace = [self.photoScanManager scanSingleAsset:self.showAssets[pipelineFlag] withDetector:FaceppFaceDetector];
    pipelineFlag += 1;
    if (includeFace) {
        [self.faceDataSource addFaces:[self.photoScanManager allFacesInPhoto]];
        [self.photoScanManager cleanCache];
        [self.faceCollectionView performBatchUpdates:^{
            NSUInteger showFaceCount = [[self.faceDataSource allFaces] count];
            [self.faceDataSource.collectionView insertSections:[NSIndexSet indexSetWithIndex:0]];
            for (NSUInteger index = 0; index < showFaceCount; index ++) {
                [self.faceCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
            };
        }completion:nil];
    }
     */
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_sync(backgroundQueue, ^{
        BOOL includeFace = [self.photoScanManager scanAsset:self.showAssets[pipelineWorkIndex] withDetector:FaceppFaceDetector];
        pipelineWorkIndex += 1;
        if (includeFace) {
            [self.faceDataSource addFaces:[self.photoScanManager allFacesInPhoto]];
            [self.photoScanManager cleanCache];
            dispatch_async(mainQueue, ^{
                [self.faceCollectionView performBatchUpdates:^{
                    NSUInteger showFaceCount = [[self.faceDataSource allFaces] count];
                    [self.faceCollectionView insertSections:[NSIndexSet indexSetWithIndex:0]];
                    for (NSUInteger index = 0; index < showFaceCount; index ++) {
                        [self.faceCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
                    };
                }completion:nil];
                //currentCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
            });
        }
    });
    
    if (self.showAssets.count != 3) {
        if (pipelineWorkIndex == self.showAssets.count) {
            currentCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
            pipelineWorkIndex = 0;
            NSLog(@"Find %lu faces in this scan.", (unsigned long)self.photoScanManager.faceTotalCount);
            [self.photoScanManager saveAfterScan];
            [self configFirstScene:NO];
            [self performSegueWithIdentifier:segueIdentifier sender:self];
            return;
        }else
            [self performSelector:@selector(lineScan) withObject:nil afterDelay:0.5];
    }else{
        if (pipelineWorkIndex == 3) {
            if (self.allAssets.count == 0) {
                currentCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }
            pipelineWorkIndex = 0;
            [self performSelector:@selector(lineLoad) withObject:nil afterDelay:0.5];
        }else
            [self performSelector:@selector(lineScan) withObject:nil afterDelay:0.5];
    }
}

- (void)lineLoad
{
    if ([self.faceDataSource numberOfSectionsInCollectionView:self.faceCollectionView]) {
        [self.faceDataSource removeAllFaces];
        [self.faceCollectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
        NSLog(@"Remove previous faces");
    }
    if (self.allAssets.count == 0) {
        NSLog(@"Find %lu faces in this scan.", (unsigned long)self.photoScanManager.faceTotalCount);
        [self.photoScanManager saveAfterScan];
        [self configFirstScene:NO];
        [self performSegueWithIdentifier:segueIdentifier sender:self];
        return;
    }else if (self.allAssets.count >= 3){
        [self.showAssets removeAllObjects];
        [self.assetCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0]]];
        NSArray *assetsForLoad = @[self.allAssets[0], self.allAssets[1], self.allAssets[2]];
        [self.showAssets addObjectsFromArray:assetsForLoad];
        [self.allAssets removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
        [self.assetCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0]]];
        
        [self performSelector:@selector(lineScan) withObject:nil afterDelay:0.05];
    }else{
        [self.showAssets removeAllObjects];
        [self.assetCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0], [NSIndexPath indexPathForItem:2 inSection:0]]];
        [self.showAssets addObjectsFromArray:self.allAssets];
        [self.allAssets removeAllObjects];
        if (self.showAssets.count == 1) {
            [self.assetCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        }else
            [self.assetCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:0]]];
        //[self.photoScanManager saveAfterScan];
        [self performSelector:@selector(lineScan) withObject:nil afterDelay:0.05];
    }
}

@end