//
//  SDEPhotoViewController.m
//  FaceAlbum
//
//  Created by seedante on 11/17/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPhotoViewController.h"
#import "SDESpecialItemVC.h"
#import "SDEPhotoSceneDataSource.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef enum: NSUInteger {
    kAlbumType,
    kAlbumContentType,
    kPhotoType,
    kTimelineType,
    kAlbumAndPhotoType,
} ContentType;

@interface SDEPhotoViewController ()

@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSMutableArray *assetsArray;
@property (nonatomic) NSMutableArray *albumsArray;
@property (nonatomic) NSMutableDictionary *timelineDictionary;
@property (nonatomic) NSMutableArray *timeHeaderArray;
@property (nonatomic) ContentType contentType;
@property (nonatomic) ContentType rootViewType;
@property (nonatomic) BOOL isAlbumContentMode;
@property (nonatomic) BOOL enableBlackBackGround;
@property (nonatomic) NSUInteger albumIndex;

@end

@implementation SDEPhotoViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.delegate = self;
    self.rootViewType = kAlbumType;
    [self preparePhotoData];
}


- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Show albums.");
    //[self checkALAuthorizationStatus];
    self.contentType = self.rootViewType;
    self.isAlbumContentMode = NO;
    [super viewWillAppear:animated];
}

- (void)checkPhotoEmpty
{
    if (self.assetsArray.count == 0) {
        self.photoCollectionView.hidden = YES;
        self.accessErrorView.hidden = YES;
        self.warnningView.hidden = NO;
        self.tabBarController.tabBar.hidden = YES;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.title = @"Get Some Photos";
    }
    
}

- (void)checkALAuthorizationStatus
{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    switch (status) {
        case ALAuthorizationStatusAuthorized:
            NSLog(@"AssetsLibrary can acess.");
            self.tabBarController.tabBar.hidden = NO;
            break;
        default:
            self.tabBarController.tabBar.hidden = YES;
            self.navigationItem.title = @"Access Denied!";
            self.navigationItem.rightBarButtonItem.enabled = NO;
            self.warnningView.hidden = NO;
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)manualRefreshView
{
    self.albumsArray = nil;
    self.timelineDictionary = nil;
    self.timeHeaderArray = nil;
    [self preparePhotoData];
}

- (void)preparePhotoData
{
    self.contentType = self.rootViewType;
    self.isAlbumContentMode = NO;
    self.albumIndex = 0;
    
    if (!self.photoLibrary) {
        self.photoLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    
    
    if (!self.assetsArray) {
        self.assetsArray = [[SDEPhotoSceneDataSource sharedData] assetsArray];
    }
    
    if (!self.albumsArray) {
        self.albumsArray = [[SDEPhotoSceneDataSource sharedData] albumsArray];
    }
    
    if (!self.timelineDictionary) {
        self.timelineDictionary = [[SDEPhotoSceneDataSource sharedData] timelineDictionary];
    }
    
    if (!self.timeHeaderArray) {
        self.timeHeaderArray = [[SDEPhotoSceneDataSource sharedData] timeHeaderArray];
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
                        NSDictionary *assetInfo = @{@"Asset": asset,
                                                    @"Date": assetDate,
                                                    @"Album": albumName};
                        [assetsOfAlbum addObject:assetInfo];
                        [self.assetsArray addObject:assetInfo];
                        
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
                        NSLog(@"Group %@ scan finish", [group valueForProperty:ALAssetsGroupPropertyName]);
                        [assetsOfAlbum sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Date" ascending:NO]]];
                    }
                }];
            }
            
        }else{
            [self.timeHeaderArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"DayDate" ascending:NO]]];
            [self.photoCollectionView reloadData];
            [self checkPhotoEmpty];
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
    NSLog(@"Section: %d", section);
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
    NSLog(@"Section: %d Count: %d", section, count);
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
            self.isAlbumContentMode = YES;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            UICollectionViewController *albumVC = (UICollectionViewController *)[storyboard instantiateViewControllerWithIdentifier:@"AlbumContentVC"];
            albumVC.collectionView.dataSource = self;
            albumVC.collectionView.delegate = self;
            [albumVC.collectionView reloadData];
            albumVC.navigationItem.title = self.albumsArray[indexPath.item][@"AlbumName"];
            albumVC.navigationItem.backBarButtonItem.title = self.albumsArray[indexPath.item][@"AlbumName"];
            [self.navigationController pushViewController:albumVC animated:YES];
            //UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"showAlbum" source:self destination:albumVC];
            //[segue perform];
            break;
        }
        case kAlbumContentType:{
            self.contentType = kPhotoType;
            self.enableBlackBackGround = NO;
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            SDESpecialItemVC *detailVC = (SDESpecialItemVC *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
            detailVC.collectionView.dataSource = self;
            detailVC.collectionView.delegate = self;
            [detailVC.collectionView reloadData];
            [detailVC specifyStartIndexPath:indexPath];
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
            SDESpecialItemVC *detailVC = (SDESpecialItemVC *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
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
        default:
            break;
    }
}

#pragma mark - UINavigationViewController Delegate Method
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSLog(@"Navigation Delegate Method.");
    NSUInteger count = self.navigationController.viewControllers.count;
    NSLog(@"View Controller Count: %d", count);
    switch (self.contentType) {
        case kPhotoType:
            if (count == 3) {
                NSLog(@"Show Photo Detail.");
            }else if (count == 2){
                if (self.isAlbumContentMode) {
                    self.contentType = kAlbumContentType;
                }
            }else{
                self.contentType = self.rootViewType;
                NSLog(@"Go back Home.");
            }
            break;
        case kAlbumContentType:
            NSLog(@"AlbumContentType");
            break;
        case kAlbumType:
        case kAlbumAndPhotoType:
        case kTimelineType:
            [self checkALAuthorizationStatus];
            break;
        default:
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

