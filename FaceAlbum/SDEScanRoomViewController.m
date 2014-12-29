//
//  SDViewController.m
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEScanRoomViewController.h"
#import "SDEFaceVCDataSource.h"
#import "PhotoScanManager.h"
#import "SDEPhotoFileFilter.h"
#import "Store.h"
@import AssetsLibrary;

static NSString *cellIdentifier = @"photoCell";
static NSString *segueIdentifier = @"enterMontageRoom";

@interface SDEScanRoomViewController ()
@property (nonatomic)SDEFaceVCDataSource *faceDataSource;
@property (nonatomic)PhotoScanManager *photoScanManager;
@property (nonatomic)ALAssetsLibrary *photoLibrary;
@property (nonatomic)NSMutableArray *allAssets;
@property (nonatomic, assign) NSUInteger totalCount;
@property (weak, nonatomic) IBOutlet UILabel *processIndicator;
@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;


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
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.photoScanManager = [PhotoScanManager sharedPhotoScanManager];
    self.managedObjectContext = [[Store sharedStore] managedObjectContext];
    
    [self piplineInitialize];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
    //[self checkALAuthorizationStatus];
    self.photoScanManager.faceCountInThisScan = 0;
    NSManagedObjectContext *moc = [[Store sharedStore] managedObjectContext];
    NSFetchRequest *faceFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *faceEntity = [NSEntityDescription entityForName:@"Face" inManagedObjectContext:moc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"section == 0"];
    [faceFetchRequest setEntity:faceEntity];
    [faceFetchRequest setPredicate:predicate];
    
    NSArray *unknownFaces = [moc executeFetchRequest:faceFetchRequest error:nil];
    self.photoScanManager.numberOfItemsInFirstSection = unknownFaces.count;
    DLog(@"Unknown face count: %lu", (unsigned long)unknownFaces.count);
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


- (void)checkALAuthorizationStatus
{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    switch (status) {
        case ALAuthorizationStatusAuthorized:
            DLog(@"AssetsLibrary can acess.");
            break;
        default:
            self.scanButton.enabled = NO;
            self.assetCollectionView.hidden = YES;
            self.requestPhotoAuthorizationView.hidden = NO;
            break;
    }
}

- (void)piplineInitialize
{
    pipelineWorkIndex = 0;
    self.allAssets = [[NSMutableArray alloc] init];
    self.showAssets = [[NSMutableArray alloc] init];
    
    SDEPhotoFileFilter *photoDetector = [SDEPhotoFileFilter sharedPhotoFileFilter];
    [photoDetector checkPhotoLibrary];
    if ([photoDetector isPhotoAdded]) {
        NSArray *newAssets = [photoDetector assetsNeedToScan];
        if (newAssets.count > 0) {
            for (ALAsset *asset in newAssets) {
                if (self.showAssets.count < 3) {
                    [self.showAssets addObject:asset];
                }else
                    [self.allAssets addObject:asset];
            }
            [self.assetCollectionView reloadData];
            NSLog(@"Asset need to scan: %d", (int)(self.allAssets.count + self.showAssets.count));
            [photoDetector reset];
        }
        //int count = (int)newAssets.count;
        self.totalCount = newAssets.count;
        if (self.totalCount == 0) {
            self.scanButton.enabled = NO;
            self.assetCollectionView.hidden = YES;
            self.requestPhotoAuthorizationView.hidden = YES;
        }
        self.processIndicator.text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)self.totalCount, (unsigned long)self.totalCount];
    }else
        NSLog(@"There is NO new photo");

    /*
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    BOOL isFirstScan = [defaultConfig boolForKey:@"isFirstScan"];
    if (!isFirstScan) {
        NSLog(@"This is the firct scan");
        self.photoScanManager.numberOfItemsInFirstSection = 0;
        
        NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
        [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
            if (group && *stop != YES) {
                //NSURL *groupURL = (NSURL *)[group valueForProperty:ALAssetsGroupPropertyURL];
                DLog(@"Group: %@", [group valueForProperty:ALAssetsGroupPropertyName]);
                DLog(@"Group: %@", [group valueForProperty:ALAssetsGroupPropertyPersistentID]);
                DLog(@"Group: %@", [group valueForProperty:ALAssetsGroupPropertyURL]);
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                    if (asset && *stop != YES) {
                        DLog(@"Asset: %@", [asset valueForProperty:ALAssetPropertyAssetURL]);
                        
                        if (self.showAssets.count < 3) {
                            [self.showAssets addObject:asset];
                        }else
                            [self.allAssets addObject:asset];
                    }
                }];
            }else{
                self.totalCount = self.allAssets.count + self.showAssets.count;
                if (self.totalCount == 0) {
                    self.scanButton.enabled = NO;
                    self.assetCollectionView.hidden = YES;
                    self.requestPhotoAuthorizationView.hidden = YES;
                }
                
                [self.assetCollectionView reloadData];
            }
        } failureBlock:nil];
    }else{

    }
     */
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


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.showAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *photoCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[photoCell viewWithTag:10];
    ALAsset *asset = (ALAsset *)[self.showAssets objectAtIndex:indexPath.item];
    imageView.image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];

    return photoCell;
}

- (IBAction)scanPhotos:(id)sender
{
    self.tabBarController.tabBar.hidden = YES;
    [self.scanButton setTitle:@"Scan..." forState:UIControlStateNormal];
    self.scanButton.enabled = NO;
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
        DLog(@"Remove previous faces");
    }
    
    //solution 1: uiview animation, just can't keep scale effect.
    if (pipelineWorkIndex > 0) {
        UICollectionViewCell *previousCell = [self.assetCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pipelineWorkIndex - 1 inSection:0]];
        previousCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }
    UICollectionViewCell *currentCell = [self.assetCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:pipelineWorkIndex inSection:0]];
    currentCell.transform = CGAffineTransformMakeScale(1.1, 1.1);
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
        int count = (int)(self.allAssets.count + self.showAssets.count - pipelineWorkIndex);
        self.processIndicator.text = [NSString stringWithFormat:@"%d/%lu", count, (unsigned long)self.totalCount];
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
            });
        }
    });
    
    if (self.showAssets.count != 3) {
        if (pipelineWorkIndex == self.showAssets.count) {
            currentCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
            pipelineWorkIndex = 0;
            DLog(@"Find %lu faces in this scan.", (unsigned long)self.photoScanManager.faceCountInThisScan);
            [self.photoScanManager saveAfterScan];
            [self configFirstScene:NO];
            [self cleanManagedObjectContext];
            UIViewController *secondVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MontageRoom"];
            [self.navigationController pushViewController:secondVC animated:YES];
            //[self performSegueWithIdentifier:segueIdentifier sender:self];
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
        DLog(@"Remove previous faces");
    }
    if (self.allAssets.count == 0) {
        DLog(@"Find %lu faces in this scan.", (unsigned long)self.photoScanManager.faceCountInThisScan);
        [self.photoScanManager saveAfterScan];
        [self configFirstScene:NO];
        //UIViewController *secondVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MontageRoom"];
        //[self.navigationController pushViewController:secondVC animated:YES];
        [self cleanManagedObjectContext];
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
        [self performSelector:@selector(lineScan) withObject:nil afterDelay:0.05];
    }
}

@end