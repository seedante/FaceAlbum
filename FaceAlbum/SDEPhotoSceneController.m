//
//  SDEPhotoViewController.m
//  FaceAlbum
//
//  Created by seedante on 11/17/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPhotoSceneController.h"
#import "SDEPhotoItemVC.h"
#import "SDEAssetsCache.h"
#import <AssetsLibrary/AssetsLibrary.h>

/*  层次关系
    kAlbumType,
    ----kAlbumContentType,
    --------kPhtoType,
    kAlbumAndPhtoType,
    ----kPhotoType,
    kTimelineType,
    ----kPhotoType,
*/

typedef enum: NSUInteger {
    kAlbumType,
    kAlbumContentType,
    kPhotoType,
    kAlbumAndPhotoType,
    kTimelineType,
} SDEPhotoSceneContentType;


@interface SDEPhotoSceneController ()

@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSMutableDictionary *assetsDictionary;
@property (nonatomic) NSMutableArray *albumsArray;
@property (nonatomic) NSMutableDictionary *timelineDictionary;
@property (nonatomic) NSMutableArray *timeHeaderArray;
@property (nonatomic) SDEPhotoSceneContentType contentType;
@property (nonatomic) SDEPhotoSceneContentType rootViewType;
@property (nonatomic, assign) BOOL enableBlackBackGround;
@property (nonatomic, assign) NSUInteger albumIndex;
@property (nonatomic, assign, getter=isUpdatingAssets) BOOL updatingAssets;

@end

@implementation SDEPhotoSceneController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(responseToAssetsChangeNotification) name:ALAssetsLibraryChangedNotification object:nil];
    self.updatingAssets = NO;
    self.navigationController.delegate = self;
    self.rootViewType = kAlbumType;
    self.contentType = kAlbumType;
    [self preparePhotoData];
}


- (void)viewWillAppear:(BOOL)animated
{
    self.contentType = self.rootViewType;
    self.tabBarController.tabBar.hidden = NO;
    [super viewWillAppear:animated];
}

- (void)checkIfNoAsset
{
    if (self.assetsDictionary.count == 0) {
        self.photoCollectionView.hidden = YES;
        self.accessErrorView.hidden = YES;
        self.warnningView.hidden = NO;
        self.tabBarController.tabBar.hidden = YES;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.title = @"Get Some Photos";
    }else{
        self.photoCollectionView.hidden = NO;
        self.accessErrorView.hidden = YES;
        self.warnningView.hidden = YES;
        self.tabBarController.tabBar.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSString *title = nil;
        switch (self.rootViewType) {
            case kAlbumType:
                title = @"Albums";
                break;
            case kAlbumAndPhotoType:
                title = @"Albums and Photos";
                break;
            case kTimelineType:
                title = @"Moments";
                break;
            default:
                break;
        }
        self.navigationItem.title = title;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)responseToAssetsChangeNotification
{
    if ([self isUpdatingAssets]) {
        return;
    }

    //NSLog(@"update Assets...");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.updateIndicator.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.tabBarController.tabBar.hidden = YES;
    });
    
    self.updatingAssets = YES;
    [self cleanCache];
    [self preparePhotoData];
}

- (void)cleanCache
{
    if (self.assetsDictionary.count > 0) {
        [self.assetsDictionary removeAllObjects];
    }
    
    if (self.albumsArray.count > 0) {
        [self.albumsArray removeAllObjects];
    }
    
    if (self.timelineDictionary.count > 0) {
        [self.timelineDictionary removeAllObjects];
    }
    
    if (self.timeHeaderArray.count > 0) {
        [self.timeHeaderArray removeAllObjects];
    }
}

- (void)preparePhotoData
{
    self.contentType = self.rootViewType;
    self.albumIndex = 0;
    
    if (!self.photoLibrary) {
        self.photoLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    if (!self.assetsDictionary) {
        self.assetsDictionary = [[SDEAssetsCache sharedData] assetsDictionary];
    }
    
    if (!self.albumsArray) {
        self.albumsArray = [[SDEAssetsCache sharedData] albumsArray];
    }
    
    if (!self.timelineDictionary) {
        self.timelineDictionary = [[SDEAssetsCache sharedData] timelineDictionary];
    }
    
    if (!self.timeHeaderArray) {
        self.timeHeaderArray = [[SDEAssetsCache sharedData] timeHeaderArray];
    }
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    NSUInteger groupType = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupType usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        if (group && *stop != YES) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            if (group.numberOfAssets > 0) {
                NSString *persistentID = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
                NSString *albumName = [group valueForProperty:ALAssetsGroupPropertyName];
                NSMutableArray *assetsOfAlbum = [NSMutableArray new];
                [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *shouldStop){
                    if (asset && *shouldStop != YES) {
                        if (index == 0) {
                            [self.albumsArray addObject:@{@"AlbumName": albumName,
                                                          @"ID": persistentID,
                                                          @"PosterImage": [UIImage imageWithCGImage:asset.aspectRatioThumbnail],
                                                          @"Assets": assetsOfAlbum,
                                                          @"Count": @(group.numberOfAssets)}];
                        }
                        
                        NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
                        NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
                        NSString *assetURLString = assetURL.absoluteString;
                        NSDictionary *assetInfo = @{@"Asset": asset,
                                                    @"Date": assetDate,
                                                    @"Album": albumName};
                        [assetsOfAlbum addObject:assetInfo];
                        [self.assetsDictionary setObject:asset forKey:assetURLString];
                        
                        NSString *dayString = [dateFormatter stringFromDate:assetDate];
                        NSMutableArray *sameDateArray = (NSMutableArray *)[self.timelineDictionary objectForKey:dayString];
                        if (!sameDateArray) {
                            sameDateArray = [NSMutableArray new];
                            [sameDateArray addObject:assetInfo];
                            [self.timelineDictionary setObject:sameDateArray forKey:dayString];
                            [self.timeHeaderArray addObject: @{@"DayString": dayString, @"DayDate": assetDate}];
                        }else{
                            [sameDateArray addObject:assetInfo];
                        }
                    }else{
                       // NSLog(@"Group %@ scan finish", [group valueForProperty:ALAssetsGroupPropertyName]);
                        [assetsOfAlbum sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Date" ascending:NO]]];
                    }
                }];
            }
            
        }else{
            //NSLog(@"...Scan Finish");
            [self.timeHeaderArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"DayDate" ascending:NO]]];
            [self checkIfNoAsset];
            [self.photoCollectionView reloadData];
            
            self.updatingAssets = NO;
            self.updateIndicator.hidden = YES;
        }
    } failureBlock:^(NSError *error){
        self.photoCollectionView.hidden = YES;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.tabBarController.tabBar.hidden = YES;
        self.navigationItem.title = @"Access Denied!";
        self.warnningView.hidden = NO;
    }];
    
}

#pragma mark - UICollectionView Data Source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger section = 0;
    switch (self.contentType) {
        case kAlbumType:
            if(self.albumsArray.count > 0)
                section = 1;
            break;
        case kAlbumContentType:
            section = 1;
            break;
        case kPhotoType:{
            switch (self.rootViewType) {
                case kAlbumType:
                    section = 1;
                    break;
                case kAlbumAndPhotoType:
                    section = self.albumsArray.count;
                    break;
                case kTimelineType:
                    section = self.timelineDictionary.count;
                    break;
                default:
                    break;
            }
            break;
        }
        case kTimelineType:
            section = self.timelineDictionary.count;
            break;
        case kAlbumAndPhotoType:
            section = self.albumsArray.count;
            break;
    }
    return section;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count;
    switch (self.contentType) {
        case kAlbumType:
            count = self.albumsArray.count;
            break;
        case kAlbumContentType:
            count = [self.albumsArray[self.albumIndex][@"Assets"] count];
            break;
        case kPhotoType:{
            switch (self.rootViewType) {
                case kAlbumType:
                    count = [self.albumsArray[self.albumIndex][@"Assets"] count];
                    break;
                case kAlbumAndPhotoType:{
                    NSNumber *countNumber = (NSNumber *)self.albumsArray[section][@"Count"];
                    count = countNumber.integerValue;
                    break;
                }
                case kTimelineType:{
                    NSString *dayString = self.timeHeaderArray[section][@"DayString"];
                    count = [self.timelineDictionary[dayString] count];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case kAlbumAndPhotoType:{
            NSNumber *countNumber = (NSNumber *)self.albumsArray[section][@"Count"];
            count = countNumber.intValue;
            break;
        }
        case kTimelineType:{
            NSString *dayString = self.timeHeaderArray[section][@"DayString"];
            count = [self.timelineDictionary[dayString] count];
            break;
        }
    }
    //NSLog(@"Section: %d Count: %d", section, count);
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    UIImageView *photoView;
    
    switch (self.contentType) {
        case kAlbumType:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"albumCell" forIndexPath:indexPath];
            photoView = (UIImageView *)[cell viewWithTag:10];
            break;
        }
        default:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
            photoView = (UIImageView *)[cell viewWithTag:10];
            break;
        }
    }
        
    switch (self.contentType) {
        case kAlbumType:{
            NSDictionary *albumInfo = (NSDictionary *)[self.albumsArray objectAtIndex:indexPath.item];
            UILabel *albumNameLabel = (UILabel *)[cell viewWithTag:20];
            [photoView setImage: albumInfo[@"PosterImage"]];
            albumNameLabel.text = albumInfo[@"AlbumName"];
            return cell;
        }
        case kAlbumContentType:{
            NSDictionary *assetInfo = self.albumsArray[self.albumIndex][@"Assets"][indexPath.item];
            ALAsset *asset = assetInfo[@"Asset"];
            [photoView setImage: [UIImage imageWithCGImage: asset.aspectRatioThumbnail]];
            return cell;
        }
        case kPhotoType:{
            switch (self.rootViewType) {
                case kAlbumType:{
                    NSDictionary *assetInfo = (NSDictionary *)self.albumsArray[self.albumIndex][@"Assets"][indexPath.item];
                    ALAsset *asset = assetInfo[@"Asset"];
                    [photoView setImage: [UIImage imageWithCGImage: asset.defaultRepresentation.fullScreenImage]];
                    break;
                }
                case kAlbumAndPhotoType:{
                    NSDictionary *assetInfo = (NSDictionary *)self.albumsArray[indexPath.section][@"Assets"][indexPath.item];
                    ALAsset *asset = assetInfo[@"Asset"];
                    [photoView setImage: [UIImage imageWithCGImage: asset.defaultRepresentation.fullScreenImage]];
                    break;
                }
                case kTimelineType:{
                    NSString *dayString = self.timeHeaderArray[indexPath.section][@"DayString"];
                    NSDictionary *assetInfo = (NSDictionary *)self.timelineDictionary[dayString][indexPath.item];
                    ALAsset *asset = assetInfo[@"Asset"];
                    [photoView setImage: [UIImage imageWithCGImage: asset.defaultRepresentation.fullScreenImage]];
                    break;
                }
                default:
                    break;
            }
            
            return cell;
        }
        case kTimelineType:{
            NSDictionary *assetInfo = [[self.timelineDictionary objectForKey:(NSString *)self.timeHeaderArray[indexPath.section][@"DayString"]] objectAtIndex:indexPath.item];
            ALAsset *asset = assetInfo[@"Asset"];
            [photoView setImage: [UIImage imageWithCGImage: asset.aspectRatioThumbnail]];
            return cell;
        }
        case kAlbumAndPhotoType:{
            NSDictionary *assetInfo = (NSDictionary *)self.albumsArray[indexPath.section][@"Assets"][indexPath.item];
            ALAsset *asset = assetInfo[@"Asset"];
            [photoView setImage:[UIImage imageWithCGImage:asset.aspectRatioThumbnail]];
            return cell;
        }
    }
    
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
    UILabel *timeLabel = (UILabel *)[header viewWithTag:10];
    UILabel *nameLabel = (UILabel *)[header viewWithTag:20];
    switch (self.contentType) {
        case kAlbumType:
        case kAlbumContentType:
        case kPhotoType:
            timeLabel.text = @"";
            nameLabel.text = @"";
            header.backgroundColor = [UIColor whiteColor];
            break;
        case kAlbumAndPhotoType:
            timeLabel.text = @"";
            nameLabel.text = (NSString *)self.albumsArray[indexPath.section][@"AlbumName"];
            header.backgroundColor = [UIColor lightGrayColor];
            break;
        case kTimelineType:
            timeLabel.text = (NSString *)[self.timeHeaderArray objectAtIndex:indexPath.section][@"DayString"];
            nameLabel.text = @"";
            header.backgroundColor = [UIColor whiteColor];
            break;
    }
    return header;
}

#pragma mark - UICollectionView Layout
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    switch (self.contentType) {
        case kAlbumType:
        case kAlbumAndPhotoType:
        case kTimelineType:
        case kAlbumContentType:
            return UIEdgeInsetsMake(20, 50, 20, 50);
        case kPhotoType:
            return UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.contentType) {
        case kAlbumType:
            return CGSizeMake(180, 210);
        case kPhotoType:
            return CGSizeMake(1024, 768);
        default:
            return CGSizeMake(150, 150);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    switch (self.contentType) {
        case kAlbumType:
            return 50.0;
        case kPhotoType:
            return 0.0;
        default:
            return 20.0;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    switch (self.contentType) {
        case kAlbumType:
            return 50.0;
        case kPhotoType:
            return 0.0;
        default:
            return 10.0;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    switch (self.contentType) {
        case kAlbumAndPhotoType:
        case kTimelineType:
            return CGSizeMake(768, 50);
        default:
            return CGSizeZero;
    }
}

#pragma mark - UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.contentType) {
        case kAlbumType:{
            self.tabBarController.tabBar.hidden = YES;
            self.albumIndex = indexPath.item;
            self.contentType = kAlbumContentType;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            UICollectionViewController *albumVC = (UICollectionViewController *)[storyboard instantiateViewControllerWithIdentifier:@"AlbumContentVC"];
            albumVC.collectionView.dataSource = self;
            albumVC.collectionView.delegate = self;
            [albumVC.collectionView reloadData];
            albumVC.navigationItem.title = self.albumsArray[indexPath.item][@"AlbumName"];
            albumVC.navigationItem.backBarButtonItem.title = self.albumsArray[indexPath.item][@"AlbumName"];
            [self.navigationController pushViewController:albumVC animated:YES];
            break;
        }
        case kAlbumContentType:{
            self.contentType = kPhotoType;
            self.enableBlackBackGround = NO;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            SDEPhotoItemVC *detailVC = (SDEPhotoItemVC *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
            detailVC.collectionView.dataSource = self;
            detailVC.collectionView.delegate = self;
            [detailVC.collectionView reloadData];
            [detailVC specifyStartIndexPath:indexPath];
            //此处使用 PUSH 的动画效果是错误的，下面一个也是，应该是 Photos 那样的放大效果（弹簧般的效果真是赞），不过暂时没时间弄了
            [self.navigationController pushViewController:detailVC animated:YES];
            detailVC.navigationItem.title = @"";
            break;
        }
        case kTimelineType:
        case kAlbumAndPhotoType:{
            self.tabBarController.tabBar.hidden = YES;
            self.contentType = kPhotoType;
            self.enableBlackBackGround = NO;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            SDEPhotoItemVC *detailVC = (SDEPhotoItemVC *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
            detailVC.collectionView.dataSource = self;
            detailVC.collectionView.delegate = self;
            [detailVC.collectionView reloadData];
            [detailVC specifyStartIndexPath:indexPath];
            [self.navigationController pushViewController:detailVC animated:YES];
            detailVC.navigationItem.title = @"";
            break;
        }
        case kPhotoType:
            self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
            if (self.enableBlackBackGround) {
                self.enableBlackBackGround = NO;
                collectionView.backgroundColor = [UIColor whiteColor];
            }else{
                self.enableBlackBackGround = YES;
                collectionView.backgroundColor = [UIColor blackColor];
            }
            break;
    }
}

#pragma mark - UINavigationViewController Delegate Method
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSUInteger count = self.navigationController.viewControllers.count;
    switch (self.contentType) {
        case kPhotoType:
            if (count == 2) {
                if (self.rootViewType == kAlbumType) {
                    self.contentType = kAlbumContentType;
                }
            }
            break;
        default:
            //self.tabBarController.tabBar.hidden = NO;
            break;
    }
}


- (IBAction)changeShowStyle:(id)sender
{
    switch (self.contentType) {
        case kAlbumType:
            self.contentType = kAlbumAndPhotoType;
            self.rootViewType = kAlbumAndPhotoType;
            self.navigationItem.title = @"Albums and Photos";
            break;
        case kAlbumAndPhotoType:
            self.contentType = kTimelineType;
            self.rootViewType = kTimelineType;
            self.navigationItem.title = @"Moments";
            break;
        case kTimelineType:
            self.contentType = kAlbumType;
            self.rootViewType = kAlbumType;
            self.navigationItem.title = @"Albums";
            break;
        default:
            break;
    }

        
    [self.photoCollectionView.collectionViewLayout invalidateLayout];
    [self.photoCollectionView reloadData];
}
@end


