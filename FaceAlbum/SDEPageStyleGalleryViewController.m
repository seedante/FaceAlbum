//
//  SDEPageStyleGalleryViewController.m
//  FaceAlbum
//
//  Created by seedante on 9/8/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPageStyleGalleryViewController.h"
#import "SDENewPhotoDetector.h"
#import "Store.h"
#import "Face.h"
#import "Person.h"
#import "Photo.h"
#import "SDEGalleryCell.h"
#import "LineLayout.h"
#import "SDEPageViewLayout.h"
@import AssetsLibrary;

static NSString *CellIdentifier = @"GalleryCell";

#define NumberOfAvatorPerPage 20
#define DoubleValueOfAvatorPerPage 20.0

typedef enum: NSUInteger{
    PortraitLayout,
    HorizontalGridLayout,
    DetailLineLayout
} LayoutType;

typedef enum: NSUInteger{
    kFaceType,
    kPhotoType,
} GridCellType;

@interface SDEPageStyleGalleryViewController ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSFetchedResultsController *personFetchedResultsController;
@property (nonatomic) UIPageViewController *pageViewController;

@property (nonatomic) NSInteger currentPortraitIndex;
@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) LayoutType currentLayoutType;
@property (nonatomic) GridCellType currentGridCellType;

@property (nonatomic) UICollectionViewController *singlePageCollectionViewController;
@property (nonatomic) UICollectionView *singlePageCollectionView;
@property (nonatomic) UICollectionViewController *detailContentViewController;
@property (nonatomic) UICollectionView *detailContentCollectionView;
@property (nonatomic)ALAssetsLibrary *photoLibrary;

@property (nonatomic) NSMutableArray *pageVCArray;
@property (nonatomic, assign) BOOL inPageViewFlag;
@property (nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic) SDENewPhotoDetector *newPhotoDetector;
@end

@implementation SDEPageStyleGalleryViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.galleryView.dataSource = self;
    self.galleryView.delegate = self;
    self.navigationController.delegate = self;
    
    self.currentPortraitIndex = 0;
    self.pageVCArray = [NSMutableArray new];
    self.inPageViewFlag = NO;
    self.currentLayoutType = PortraitLayout;
    self.currentGridCellType = kFaceType;
    self.styleSwitch.hidden = YES;
    self.styleSwitch.delegate = self;
    UITabBarItem *item = [self.styleSwitch.items objectAtIndex:self.currentGridCellType];
    [self.styleSwitch setSelectedItem:item];
    
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Aged-Paper"]];
    
    NSString *startSceneName = [self startScene];
    DLog(@"Start Scene: %@", startSceneName);
    if ([startSceneName isEqualToString:@"ScanRoom"]) {
        UIViewController *scanRoomVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ScanRoom"];
        [self.navigationController pushViewController:scanRoomVC animated:NO];
    }else if ([startSceneName isEqualToString:@"MontageRoom"]){
        UIViewController *montageRoomVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MontageRoom"];
        [self.navigationController pushViewController:montageRoomVC animated:NO];
    }
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controlShowOfTabBar:)];
    [self.galleryView addGestureRecognizer:self.pinchGestureRecognizer];
    [self.galleryView addGestureRecognizer:self.tapGestureRecognizer];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    self.tabBarController.tabBar.hidden = YES;
    [self.newPhotoDetector comparePhotoDataBetweenLocalAndDataBase];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.buttonPanel.hidden = YES;
    [self.galleryView reloadData];
    //[self.styleSwitch setSelectedItem:(UITabBarItem *)self.styleSwitch.items.firstObject];
    [super viewWillAppear:animated];
}

- (NSString *)startScene
{
    NSString *startScene;
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    [defaultConfig registerDefaults:@{@"isFirstScan": @YES}];
    [defaultConfig registerDefaults:@{@"isGalleryOpened": @NO}];
    [defaultConfig registerDefaults:@{@"shouldBeMontageRoom": @YES}];
    [defaultConfig synchronize];
    
    BOOL isGalleryOpened = [defaultConfig boolForKey:@"isGalleryOpened"];
    if (isGalleryOpened) {
        startScene = @"PersonGallery";
        return startScene;
    }
    
    BOOL isFirstScan = [defaultConfig boolForKey:@"isFirstScan"];
    if (isFirstScan) {
        startScene = @"ScanRoom";
        return startScene;
    }
    
    BOOL shouldBeMontageRoom = [defaultConfig boolForKey:@"shouldBeMontageRoom"];
    if (shouldBeMontageRoom) {
        startScene = @"MontageRoom";
    }
    return startScene;
}


- (SDENewPhotoDetector *)newPhotoDetector
{
    if (!_newPhotoDetector) {
        _newPhotoDetector = [SDENewPhotoDetector sharedPhotoDetector];
    }
    return _newPhotoDetector;
}

- (ALAssetsLibrary *)photoLibrary
{
    if (_photoLibrary != nil) {
        return _photoLibrary;
    }
    _photoLibrary = [[ALAssetsLibrary alloc] init];
    return _photoLibrary;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    Store *storeCenter = [Store sharedStore];
    _managedObjectContext = storeCenter.managedObjectContext;
    return _managedObjectContext;
}

- (NSFetchedResultsController *)faceFetchedResultsController
{
    if (_faceFetchedResultsController != nil) {
        return _faceFetchedResultsController;
    }
    
    _faceFetchedResultsController = [[Store sharedStore] faceFetchedResultsController];
    [_faceFetchedResultsController performFetch:nil];
    
    return _faceFetchedResultsController;
}

- (NSFetchedResultsController *)personFetchedResultsController
{
    if (_personFetchedResultsController != nil) {
        return _personFetchedResultsController;
    }
    
    _personFetchedResultsController = [[Store sharedStore] personFetchedResultsController];
    [_personFetchedResultsController performFetch:nil];
    return _personFetchedResultsController;
}

- (UIPageViewController *)pageViewController
{
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        _pageViewController.delegate = self;
        _pageViewController.dataSource = self;
        [self addChildViewController:_pageViewController];
        [_pageViewController didMoveToParentViewController:self];
        
    }
    return _pageViewController;
}

- (UICollectionViewController *)singlePageCollectionViewController
{
    if (!_singlePageCollectionViewController) {
        _singlePageCollectionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
        [self addChildViewController:_singlePageCollectionViewController];
        [_singlePageCollectionViewController didMoveToParentViewController:self];
        
        CGRect contentRect = self.galleryView.frame;
        _singlePageCollectionViewController.collectionView.frame = contentRect;
        _singlePageCollectionViewController.collectionView.dataSource = self;
        _singlePageCollectionViewController.collectionView.delegate = self;
        [self.view addSubview:_singlePageCollectionViewController.collectionView];
        
    }
    return _singlePageCollectionViewController;
}

- (UICollectionView *)singlePageCollectionView
{
    if (!_singlePageCollectionViewController) {
        _singlePageCollectionView = self.singlePageCollectionViewController.collectionView;
    }
    return _singlePageCollectionView;
}

- (UICollectionViewController *)detailContentViewController
{
    if (!_detailContentViewController) {
        _detailContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailVC"];
        [self addChildViewController:_detailContentViewController];
        [_detailContentViewController didMoveToParentViewController:self];
        
        CGRect contentRect = self.view.frame;
        contentRect.origin.y = self.galleryView.frame.origin.y;
        contentRect.size.height = self.view.frame.size.height - self.galleryView.frame.origin.y;
        DLog(@"Detail Height: %f", contentRect.size.height);
        _detailContentViewController.collectionView.frame = contentRect;
        _detailContentViewController.collectionView.dataSource = self;
        _detailContentViewController.collectionView.delegate = self;
        [self.view addSubview:_detailContentViewController.collectionView];
        _detailContentViewController.view.hidden = YES;
    }
    
    return _detailContentViewController;
}

- (UICollectionView *)detailContentCollectionView
{
    if (!_detailContentCollectionView) {
        _detailContentCollectionView = self.detailContentViewController.collectionView;
        //[_detailContentCollectionView setCollectionViewLayout:[[LineLayout alloc] init]];
    }
    
    return _detailContentCollectionView;
}


#pragma mark - UIPageViewController Data Source
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    DLog(@"Before");

    if ([self countForPageViewController] == 1) {
        return nil;
    }
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];

    if (self.currentPageIndex == 0 || self.currentPageIndex == NSNotFound) {
        self.currentPageIndex = 0;
        DLog(@"???");
        return nil;
    }
    
    
    UIViewController *vc = (UIViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex - 1];
    DLog(@"Previous VC: %@", vc);
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    DLog(@"After");
    if ([self countForPageViewController] == 1) {
        return nil;
    }
    NSInteger countOfPage = [self countForPageViewController];
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    if (self.currentPageIndex >= countOfPage - 1 || self.currentPageIndex == NSNotFound) {
        DLog(@"Current Page Index: %ld", (long)self.currentPageIndex);
        DLog(@"!!!");
        return nil;
    }
    
    //DLog(@"Current Page Index: %ld", (long)self.currentPageIndex);
    //DLog(@"Current VC: %@", viewController);
    UICollectionViewController *vc;
    if (self.pageVCArray.count < countOfPage) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
        [self.pageVCArray addObject:vc];
        //self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:vc];
        vc.collectionView.dataSource = self;
        vc.collectionView.delegate = self;
        //DLog(@"Count of PageVCArray: %lu", (unsigned long)self.pageVCArray.count);
    }
    
    self.inPageViewFlag = YES;
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex + 1];
    //DLog(@"Array: %@", self.pageVCArray);
    //DLog(@"Next VC: %@", vc);
    return vc;
}

- (NSInteger)countForPageViewController
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
    NSInteger pageCount = ceil([sectionInfo numberOfObjects]/DoubleValueOfAvatorPerPage);
    return pageCount;
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    //DLog(@"%@", NSStringFromSelector(_cmd));
    DLog(@"Count of Page: %ld", (long)[self countForPageViewController]);
    return [self countForPageViewController];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    //DLog(@"%@", NSStringFromSelector(_cmd));
    UIViewController *firstViewController = self.pageViewController.viewControllers.firstObject;
    NSInteger index = [self.pageVCArray indexOfObjectIdenticalTo:firstViewController];
    self.currentPageIndex = index;
    DLog(@"Current Page Index: %ld", (long)index);
    return index;
    //return self.currentPageIndex;
}


#pragma mark - UICollectionView Data Source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    NSInteger numberOfItems;
    switch (self.currentLayoutType) {
        case PortraitLayout:{
            DLog(@"There are %lu person", (unsigned long)[[self.faceFetchedResultsController sections] count]);
            numberOfItems = [[self.faceFetchedResultsController sections] count];
            break;
        }
        case HorizontalGridLayout:{
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            if (self.inPageViewFlag) {
                if (self.currentPageIndex < [self countForPageViewController]-1) {
                    self.currentPageIndex ++;
                }
            }

            if (numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage >= NumberOfAvatorPerPage) {
                numberOfItems = NumberOfAvatorPerPage;
            }else
                numberOfItems = numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage;
            DLog(@"Avator Number: %ld in Page: %ld", (long)numberOfItems, (long)self.currentPageIndex);
            break;
        }
        case DetailLineLayout:{
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            break;
        }
        default:
            break;
    }
    
    return numberOfItems;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDEGalleryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];

    switch (self.currentLayoutType) {
        case PortraitLayout:{
            Face *firstFaceInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
            if (firstFaceInSection.section == 0) {
                [cell setShowContent:[UIImage imageNamed:@"FacelessManPoster.jpg"]];
            }else
                [cell setShowContent:firstFaceInSection.posterImage];
            break;
        }
        case HorizontalGridLayout:{
            NSInteger itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
            NSIndexPath *faceIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:faceIndexPath];
            switch (self.currentGridCellType) {
                case kFaceType:
                    [cell setShowContent:faceItem.avatorImage];
                    break;
                case kPhotoType:{
                    /*
                    NSURL *photoURL = [NSURL URLWithString:faceItem.assetURLString];
                    [self.photoLibrary assetForURL:photoURL resultBlock:^(ALAsset *asset){
                        if (asset) {
                            UIImage *photoImage = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
                            [cell setShowContent:photoImage];
                        }
                    }failureBlock:^(NSError *accessError){
                        [cell setShowContent:[UIImage imageNamed:@"FacelessManPoster.jpg"]];
                    }];
                     */
                    UIImage *photoImage = faceItem.photoOwner.thumbnail;
                    [cell setShowContent:photoImage];
                    break;
                }
            }
            break;
        }
        case DetailLineLayout:{
            NSIndexPath *selectedPersonIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:selectedPersonIndexPath];
            Photo *photoItem = faceItem.photoOwner;
            if (photoItem.faceCount == 1) {
                self.infoTitle.text = @"1 Person";
            }else
                self.infoTitle.text = [NSString stringWithFormat:@"%d Persons", photoItem.faceCount];
            NSMutableString *nameString = [[NSMutableString alloc] initWithCapacity:photoItem.faceCount];
            for (Face *face in photoItem.faceset) {
                if (face.name.length > 0) {
                    [nameString appendString:[NSString stringWithFormat:@"%@ ",face.name]];
                }
            }
            self.nameTitle.text = [nameString copy];
            NSURL *photoURL = [NSURL URLWithString:faceItem.assetURLString];
            [self.photoLibrary assetForURL:photoURL resultBlock:^(ALAsset *asset){
                if (asset) {
                    UIImage *photoImage = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
                    [cell setShowContent:photoImage];
                }
            }failureBlock:^(NSError *accessError){
                [cell setShowContent:[UIImage imageNamed:@"AccessDenied.png"]];
            }];
            
            if ([collectionView isEqual:self.detailContentCollectionView]) {
                NSInteger pageIndex = indexPath.item/NumberOfAvatorPerPage;
                //DLog(@"Page Index: %d", pageIndex);
                //DLog(@"Real Page Index: %d", self.currentPageIndex);
                if (pageIndex > self.currentPageIndex) {
                    DLog(@"Go to Next  page view at behindly.");
                    self.currentPageIndex = pageIndex;
                    if (self.pageVCArray.count < pageIndex + 1) {
                        DLog(@"Add new page view.");
                        UICollectionViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
                        [self.pageVCArray addObject:vc];
                    }
                }else if(pageIndex < self.currentPageIndex){
                    DLog(@"Go back to Previous page view.");
                    self.currentPageIndex = pageIndex;
                    UICollectionViewController *vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:pageIndex];
                    [self.pageViewController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
                    //[vc.collectionView reloadData];
                }
            }

            break;
        }
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITabBarDelegate Method
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    self.inPageViewFlag = NO;
    NSUInteger tabIndex = [tabBar.items indexOfObject:item];
    if (self.currentGridCellType != tabIndex) {
        self.currentGridCellType = tabIndex;
    }
    
    if ([self countForPageViewController] == 1) {
        [self.singlePageCollectionView reloadData];
    }else{
        UICollectionViewController *currentVC = (UICollectionViewController *)[self.pageViewController.viewControllers firstObject];
        [currentVC.collectionView reloadData];
    }
    
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.currentPortraitIndex]];
    [self updateHeaderView:faceItem];
}

#pragma mark - UINavigationController Delegate Method
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"Select Item: %ld", (long)indexPath.item);
    switch (self.currentLayoutType) {
        case PortraitLayout:{
            DLog(@"Switch to Horizontal Grid Mode.");
            [self.detailContentCollectionView reloadData];
            [self switchToHorizontalGridModeAtPortraitIndex:indexPath.item fromMode:PortraitLayout];
            break;
        }
        case HorizontalGridLayout:{
            DLog(@"Switch to Detail  Mode");
            [self switchToDetailModeAtIndexPath:indexPath];
            break;
        }
        case DetailLineLayout:{
            DLog(@"Now Use Gesturegnizer.");
            break;
        }
    }
    
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;

    switch (self.currentLayoutType) {
        case PortraitLayout:
            edgeInsets = UIEdgeInsetsMake(100, 50, 100, 50);
            break;
        case HorizontalGridLayout:
            switch (self.currentGridCellType) {
                case kFaceType:
                    edgeInsets = UIEdgeInsetsMake(0, 60, 0, 60);
                    break;
                default:
                    edgeInsets = UIEdgeInsetsMake(0, 60, 0, 60);
                    break;
            }
            
            break;
        case DetailLineLayout:
            edgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
            break;
    }

    return edgeInsets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize = CGSizeZero;
    switch (self.currentLayoutType) {
        case PortraitLayout:
            cellSize = CGSizeMake(300, 300);
            break;
        case HorizontalGridLayout:{
            cellSize = CGSizeMake(144, 144);
            break;
        }
        case DetailLineLayout:{
            cellSize = CGSizeMake(1000, 700);
            break;
        }
    }
    
    return cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat space = 0.0f;
    switch (self.currentLayoutType) {
        case PortraitLayout:
            space = 50.0f;
            break;
        case HorizontalGridLayout:
            switch (self.currentGridCellType) {
                case kFaceType:
                    space = 20.0f;
                    break;
                case kPhotoType:
                    space = 20.0f;
                    break;
            }
            break;
        case DetailLineLayout:
            space = 10.0f;
            break;
        default:
            break;
    }
    return space;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat space = 0.0f;
    switch (self.currentLayoutType) {
        case PortraitLayout:
            space = 50.0f;
            break;
        case HorizontalGridLayout:
            space = 5.0f;
            break;
        case DetailLineLayout:
            space = 24.0f;
            break;
    }
    return space;
}

#pragma mark - IBAction Method
- (IBAction)scanPhotoLibrary:(id)sender
{
    DLog(@"Scan Library");
    if ([self.newPhotoDetector shouldScanPhotoLibrary]) {
            UIViewController *scanVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ScanRoom"];
            [self.navigationController pushViewController:scanVC animated:YES];
    }

}

- (IBAction)editAlbum:(id)sender
{
    DLog(@"Need a little change.");
    DLog(@"Check for deleted photos");
    [self handleDeletedPhotos];
    [self dismissAvatorView];
    [self performSegueWithIdentifier:@"enterMontageRoom" sender:self];
}

- (void)dismissAvatorView
{
    self.currentLayoutType = PortraitLayout;
    if ([self countForPageViewController] == 1) {
        self.singlePageCollectionView.hidden = YES;
    }else{
        [self.pageViewController.view removeFromSuperview];
    }
    
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";

    self.detailContentCollectionView.hidden = YES;
    self.styleSwitch.hidden = YES;
    self.actionCenterButton.hidden = NO;
    [self.actionCenterButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
    self.galleryView.hidden = NO;
    self.currentPageIndex = 0;
    
    if (self.pageVCArray.count > 0) {
        [self.pageVCArray removeAllObjects];
    }
    
}

- (void)handleDeletedPhotos
{
    DLog(@"Handle for Delete");
    NSArray *deletedAssetsURLString = [self.newPhotoDetector notexistedAssetsURLString];
    if (deletedAssetsURLString.count > 0) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
        for (NSString *URLString in deletedAssetsURLString) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(isExisted == YES) AND (uniqueURLString like %@)", URLString];
            [fetchRequest setPredicate:predicate];
            NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
            if (result.count == 1) {
                Photo *deletedPhoto = (Photo *)result.firstObject;
                deletedPhoto.isExisted = NO;
            }else
                DLog(@"Some Thing Wrong");
        }
        [self.managedObjectContext save:nil];
    }
    
    NSArray *gobackAssetsURLString = [self.newPhotoDetector againStoredAssetsURLString];
    if (gobackAssetsURLString.count > 0) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
        for (NSString *URLString in gobackAssetsURLString) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(isExisted == NO) AND (uniqueURLString like %@)", URLString];
            [fetchRequest setPredicate:predicate];
            NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
            if (result.count == 1) {
                Photo *gobackPhoto = (Photo *)result.firstObject;
                gobackPhoto.isExisted = YES;
            }else
                DLog(@"Some Wrong here");
        }
        [self.managedObjectContext save:nil];
    }
    
    [self.newPhotoDetector cleanData];
}

- (IBAction)popMenu:(id)sender
{
    if (![self.newPhotoDetector shouldScanPhotoLibrary]) {
        self.scanRoomButton.hidden = YES;
    }else
        self.scanRoomButton.hidden = NO;
    if ([[self.newPhotoDetector notexistedAssetsURLString] count] > 0) {
        self.MontageRoomButton.highlighted = YES;
    }else
        self.MontageRoomButton.highlighted = NO;
    
    if (self.buttonPanel.hidden) {
        self.buttonPanel.hidden = NO;
        [self.buttonPanel hide];
    }
    
    if (self.buttonPanel.isPopup) {
        [self.buttonPanel hide];
    }else
        [self.buttonPanel popup];
}


#pragma mark - Gesture Method
- (void)controlShowOfTabBar:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.galleryView];
    NSIndexPath *indexPath = [self.galleryView indexPathForItemAtPoint:location];
    if (!indexPath) {
        self.tabBarController.tabBar.hidden = !self.tabBarController.tabBar.hidden;
    }else{
        [self collectionView:self.galleryView didSelectItemAtIndexPath:indexPath];
    }
    
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecongnizer
{
    //DLog(@"Pinch Gesture.");
    //DLog(@"Velocity: %f", gestureRecongnizer.velocity);
    DLog(@"Scale: %f", gestureRecongnizer.scale);
    
    if (gestureRecongnizer.velocity > 0) {
        //Pinch Out
        if (gestureRecongnizer.state == UIGestureRecognizerStateChanged) {
            if (gestureRecongnizer.scale > 2.0f) {
                switch (self.currentLayoutType) {
                    case PortraitLayout:{
                        CGPoint centroid = [gestureRecongnizer locationInView:self.galleryView];
                        NSInteger number = [self.galleryView numberOfItemsInSection:0];
                        for (NSInteger i = 0; i < number; i++) {
                            UICollectionViewLayoutAttributes *attributes = [self.galleryView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                            if (attributes) {
                                if (CGRectContainsPoint(attributes.frame, centroid)) {
                                    DLog(@"Centroid at Item: %ld", (long)i);
                                    [self.detailContentCollectionView reloadData];
                                    [self switchToHorizontalGridModeAtPortraitIndex:i fromMode:PortraitLayout];
                                    break;
                                }
                            }
                        }
                        break;
                    }
                    case HorizontalGridLayout:{
                        if ([self countForPageViewController] == 1) {
                            CGPoint centroid = [gestureRecongnizer locationInView:self.singlePageCollectionView];
                            NSInteger number = [self.singlePageCollectionView numberOfItemsInSection:0];
                            for (NSInteger i = 0; i < number; i++) {
                                UICollectionViewLayoutAttributes *attributes = [self.singlePageCollectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                                if (attributes) {
                                    if (CGRectContainsPoint(attributes.frame, centroid)) {
                                        DLog(@"Centroid at Item: %ld", (long)i);
                                        [self switchToDetailModeAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                                    }
                                }
                            }
                        }else{
                            UICollectionViewController *vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex];
                            CGPoint centroid = [gestureRecongnizer locationInView:vc.collectionView];
                            NSInteger number = [vc.collectionView numberOfItemsInSection:0];
                            for (NSInteger i = 0; i < number; i++) {
                                UICollectionViewLayoutAttributes *attributes = [vc.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                                if (attributes) {
                                    if (CGRectContainsPoint(attributes.frame, centroid)) {
                                        DLog(@"Centroid at Item: %ld", (long)i);
                                        [self switchToDetailModeAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                                    }
                                }
                            }
                        }
                        break;
                    }
                    case DetailLineLayout:
                        DLog(@"Scale Cell");
                        break;
                }
            }
        }
        if (gestureRecongnizer.state == UIGestureRecognizerStateEnded) {

        }

    }else{
        //Pinch In
        if (gestureRecongnizer.state == UIGestureRecognizerStateChanged) {
            //DLog(@"Code not finish.");
            
        }
        if (gestureRecongnizer.state == UIGestureRecognizerStateEnded) {
            if (gestureRecongnizer.scale < 0.5f) {
                switch (self.currentLayoutType) {
                    case PortraitLayout:
                        break;
                    case HorizontalGridLayout:
                        [self switchToPortraitMode];
                        break;
                    case DetailLineLayout:
                        [self switchToHorizontalGridModeAtPortraitIndex:self.currentPortraitIndex fromMode:DetailLineLayout];
                        break;
                }
                
            }
        }
    }
}

- (void)switchToPortraitMode
{
    self.currentLayoutType = PortraitLayout;
    
    self.galleryView.hidden = NO;
    [self.galleryView addGestureRecognizer:self.pinchGestureRecognizer];
    self.styleSwitch.hidden = YES;
    if ([self countForPageViewController] == 1) {
        [self.singlePageCollectionView removeGestureRecognizer:self.pinchGestureRecognizer];
        self.singlePageCollectionView.hidden = YES;
    }else{
        [self.pageViewController.view removeGestureRecognizer:self.pinchGestureRecognizer];
        [self.pageViewController.view removeFromSuperview];
        self.pageViewController.dataSource = nil;
        self.pageViewController.delegate = nil;
        
        if (self.pageVCArray.count > 0) {
            [self.pageVCArray removeAllObjects];
        }
    }
    
    self.actionCenterButton.hidden = NO;
    [self.actionCenterButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
}

- (void)switchToHorizontalGridModeAtPortraitIndex:(NSInteger)portraitIndex fromMode:(LayoutType)layoutType
{
    //Note: Must change layoutType before startingViewController, if not, startingViewController will get wrong data source
    self.currentLayoutType = HorizontalGridLayout;
    self.currentPortraitIndex = portraitIndex;
    
    if ([self countForPageViewController] == 1) {
        self.currentPageIndex = 0;
        self.singlePageCollectionView.hidden = NO;
        [self.singlePageCollectionView reloadData];
        [self.singlePageCollectionView addGestureRecognizer:self.pinchGestureRecognizer];
    }else{
        switch (layoutType) {
            case PortraitLayout:{
                self.currentPageIndex = 0;
                self.inPageViewFlag = NO;
                if (self.pageVCArray.count > 0) {
                    [self.pageVCArray removeAllObjects];
                }
                
                UICollectionViewController *startingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
                startingViewController.collectionView.dataSource = self;
                startingViewController.collectionView.delegate = self;
                [self.pageVCArray addObject:startingViewController];
                
                CGRect contentRect = self.galleryView.frame;
                self.pageViewController.view.frame = contentRect;
                [self.view addSubview:self.pageViewController.view];
                
                self.pageViewController.dataSource = self;
                self.pageViewController.delegate = self;
                [self.pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                [self.pageViewController.view addGestureRecognizer:self.pinchGestureRecognizer];
                break;
            }
            case DetailLineLayout:{
                self.inPageViewFlag = NO;
                UICollectionViewController *vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex];
                if (vc.collectionView.dataSource != self) {
                    DLog(@"Connect to datasource");
                    vc.collectionView.dataSource = self;
                    vc.collectionView.delegate = self;
                }
                
                //self.pageViewController.dataSource = self;
                //self.pageViewController.delegate = self;
                self.pageViewController.view.hidden = NO;
                [self.pageViewController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                [self.pageViewController.view addGestureRecognizer:self.pinchGestureRecognizer];
                break;
            }
            default:
                break;
        }
    }

    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.currentPortraitIndex]];
    [self updateHeaderView:faceItem];
    
    [self.galleryView removeGestureRecognizer:self.pinchGestureRecognizer];
    [self.detailContentCollectionView removeGestureRecognizer:self.pinchGestureRecognizer];
    //self.detailContentCollectionView.dataSource = nil;
    //self.detailContentCollectionView.delegate = nil;
    
    self.galleryView.hidden = YES;
    self.styleSwitch.hidden = NO;
    self.detailContentCollectionView.hidden = YES;
    
    self.actionCenterButton.hidden = NO;
    if (faceItem.section == 0) {
        [self.actionCenterButton setImage:[UIImage imageNamed:@"FacelessManPoster.jpg"] forState:UIControlStateNormal];
    }else
        [self.actionCenterButton setImage:faceItem.avatorImage forState:UIControlStateNormal];
    self.actionCenterButton.imageView.layer.cornerRadius = 22.0f;
    self.actionCenterButton.imageView.clipsToBounds = YES;
    if (!self.buttonPanel.hidden) {
        self.buttonPanel.hidden = YES;
        [self.buttonPanel hide];
    }
    
}

- (void)switchToDetailModeAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentLayoutType = DetailLineLayout;
    self.styleSwitch.hidden = YES;
    self.actionCenterButton.hidden = YES;
    if (!self.buttonPanel.hidden) {
        self.buttonPanel.hidden = YES;
        [self.buttonPanel hide];
    }
    
    if ([self countForPageViewController] == 1) {
        self.singlePageCollectionView.hidden = YES;
        [self.singlePageCollectionView removeGestureRecognizer:self.pinchGestureRecognizer];
    }else{
        self.pageViewController.view.hidden = YES;
        [self.pageViewController.view removeGestureRecognizer:self.pinchGestureRecognizer];
    }
    
    NSInteger itemIndexBase = 0;
    if ([self countForPageViewController] != 1) {
        itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
        DLog(@"itemIndexBase: %ld", (long)itemIndexBase);
    }
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
    Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:selectedIndexPath];
    [self updateHeaderView:selectedFaceItem];
    
    [self.detailContentCollectionView reloadData];
    self.detailContentCollectionView.hidden = NO;
    [self.detailContentCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:selectedIndexPath.item inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    
    [self.detailContentCollectionView addGestureRecognizer:self.pinchGestureRecognizer];
}

#pragma mark - Update headerView Info
- (void)updateHeaderView:(Face *)faceItem
{
    id<NSFetchedResultsSectionInfo>sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
    int avatorCount = (int)[sectionInfo numberOfObjects];
    
    Person *personItem = faceItem.personOwner;
    Photo *photoItem = faceItem.photoOwner;
    int personCount = photoItem.faceCount;
    switch (self.currentLayoutType) {
        case PortraitLayout:
            self.nameTitle.text = @"";
            self.infoTitle.text = @"";
            break;
        case HorizontalGridLayout:{
            if (personItem.name.length == 0) {
                self.nameTitle.text = [NSString stringWithFormat:@"Count：%d", avatorCount];
                self.infoTitle.text = @"";
            }else{
                self.nameTitle.text = [NSString stringWithFormat:@"%@", personItem.name];
                self.infoTitle.text = [NSString stringWithFormat:@"Count: %d", avatorCount];
            }
            break;
        }
        case DetailLineLayout:{
            NSMutableString *nameString = [[NSMutableString alloc] initWithCapacity:photoItem.faceCount];
            for (Face *faceObject in photoItem.faceset) {
                if (faceObject.name.length > 0) {
                    [nameString appendString:[NSString stringWithFormat:@"%@ ",faceObject.name]];
                }
            }
            self.nameTitle.text = (NSString *)[nameString copy];
            if (personCount == 1) {
                self.infoTitle.text = @"1 Person";
            }else
                self.infoTitle.text = [NSString stringWithFormat:@"%d Persons", personCount];
            break;
        }
    }
}

@end
