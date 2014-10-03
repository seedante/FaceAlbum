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
#import "SDEGalleryModel.h"
#import "LineLayout.h"
//#import "SDECenterMenu.h"
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
@property (nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

@property (nonatomic) SDENewPhotoDetector *newPhotoDetector;
@end

@implementation SDEPageStyleGalleryViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.galleryView.dataSource = self;
    self.galleryView.delegate = self;

    self.currentPortraitIndex = 0;
    self.pageVCArray = [NSMutableArray new];
    self.currentLayoutType = PortraitLayout;
    self.currentGridCellType = kFaceType;
    self.styleSwitch.delegate = self;
    UITabBarItem *item = [self.styleSwitch.items objectAtIndex:self.currentGridCellType];
    [self.styleSwitch setSelectedItem:item];
    
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Aged-Paper"]];
    
    /*
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:self.pinchGestureRecognizer];
    [self.singlePageCollectionView addGestureRecognizer:self.pinchGestureRecognizer];
    [self.pageViewController.view addGestureRecognizer:self.pinchGestureRecognizer];
    [self.detailContentCollectionView addGestureRecognizer:self.pinchGestureRecognizer];
    */
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    /*
    UIImage *startImage = [UIImage imageNamed:@"user_male2-50.png"];
    UIImage *firstMenuImage = [UIImage imageNamed:@"edit_user-50.png"];
    UIImage *secondMenyImage = [UIImage imageNamed:@"find_user-50.png"];
    SDECenterMenu *centerMenu = [[SDECenterMenu alloc] initWithStartPoint:CGPointMake(950, 50) startImage:startImage submenuImages:@[firstMenuImage, secondMenyImage]];
    centerMenu.delegate = self;
    [self.view addSubview:centerMenu];
    [self.view bringSubviewToFront:centerMenu];
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.newPhotoDetector comparePhotoDataBetweenLocalAndDataBase];
    
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
        NSLog(@"Detail Height: %f", contentRect.size.height);
        _detailContentViewController.collectionView.frame = contentRect;
        _detailContentViewController.collectionView.dataSource = self;
        _detailContentViewController.collectionView.delegate = self;
        [self.view addSubview:_detailContentViewController.collectionView];
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
    NSLog(@"Before");
    if ([self countForPageViewController] == 1) {
        return nil;
    }
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    NSLog(@"Current Page Index: %ld", (long)self.currentPageIndex);
    NSLog(@"Current VC: %@", viewController);
    NSLog(@"Array: %@", self.pageVCArray);
    if (self.currentPageIndex == 0 || self.currentPageIndex == NSNotFound) {
        self.currentPageIndex = 0;
        NSLog(@"???");
        return nil;
    }
    
    UIViewController *vc = (UIViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex - 1];
    NSLog(@"Previous VC: %@", vc);
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSLog(@"After");
    if ([self countForPageViewController] == 1) {
        return nil;
    }
    NSInteger countOfPage = [self countForPageViewController];
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    if (self.currentPageIndex >= countOfPage - 1 || self.currentPageIndex == NSNotFound) {
        NSLog(@"Current Page Index: %ld", (long)self.currentPageIndex);
        NSLog(@"!!!");
        return nil;
    }
    
    NSLog(@"Current Page Index: %ld", (long)self.currentPageIndex);
    NSLog(@"Current VC: %@", viewController);
    UICollectionViewController *vc;
    if (self.pageVCArray.count < countOfPage) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
        [self.pageVCArray addObject:vc];
        self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:vc];
        vc.collectionView.dataSource = self;
        vc.collectionView.delegate = self;
        NSLog(@"Count of PageVCArray: %lu", (unsigned long)self.pageVCArray.count);
    }
    
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex + 1];
    NSLog(@"Array: %@", self.pageVCArray);
    NSLog(@"Next VC: %@", vc);
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
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"Count of Page: %ld", (long)[self countForPageViewController]);
    return [self countForPageViewController];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    UIViewController *firstViewController = self.pageViewController.viewControllers.firstObject;
    NSInteger index = [self.pageVCArray indexOfObjectIdenticalTo:firstViewController];
    self.currentPageIndex = index;
    NSLog(@"Current Page Index: %ld", (long)index);
    return index;
    //return self.currentPageIndex;
}

#pragma mark - Update headerView Info
- (void)updateHeaderView:(Face *)faceItem
{
    Person *personItem = faceItem.personOwner;
    Photo *photoItem = faceItem.photoOwner;
    int faceCount = personItem.ownedFaces.count;
    int personCount = photoItem.faceCount;
    switch (self.currentLayoutType) {
        case PortraitLayout:
            self.nameTitle.text = @"";
            self.infoTitle.text = @"";
            break;
        case HorizontalGridLayout:{
            switch (self.currentGridCellType) {
                case kFaceType:
                    self.nameTitle.text = [NSString stringWithFormat:@"%@", personItem.name];
                    if (faceCount == 1) {
                        self.infoTitle.text = [NSString stringWithFormat:@"1 avator"];
                    }else
                        self.infoTitle.text = [NSString stringWithFormat:@"%d avators", faceCount];
                    break;
                case kPhotoType:
                    if ([personItem.name isEqualToString:@"UnKnown"]) {
                        self.nameTitle.text = @"UnKnown";
                    }else
                        self.nameTitle.text = [NSString stringWithFormat:@"%@ and others", personItem.name];
                    if (faceCount == 1){
                        self.infoTitle.text = [NSString stringWithFormat:@"1 Photo"];
                    }else
                        self.infoTitle.text = [NSString stringWithFormat:@"%d Photos", faceCount];
                    break;
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
        default:
            break;
    }
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
            NSLog(@"There are %lu person", (unsigned long)[[self.faceFetchedResultsController sections] count]);
            numberOfItems = [[self.faceFetchedResultsController sections] count];
            break;
        }
        case HorizontalGridLayout:{
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            if (self.currentPageIndex < [self countForPageViewController]-1) {
                self.currentPageIndex ++;
            }
            if (numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage >= NumberOfAvatorPerPage) {
                numberOfItems = NumberOfAvatorPerPage;
            }else
                numberOfItems = numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage;
            NSLog(@"Avator Number: %ld in Page: %ld", (long)numberOfItems, (long)self.currentPageIndex);
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
            [cell setShowContent:[UIImage imageWithContentsOfFile:firstFaceInSection.pathForBackup]];
            cell.layer.borderWidth = 10.0f;
            cell.layer.borderColor = [[UIColor whiteColor] CGColor];
            break;
        }
        case HorizontalGridLayout:{
            NSInteger itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
            NSIndexPath *faceIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:faceIndexPath];
            switch (self.currentGridCellType) {
                case kFaceType:
                    [cell setShowContent:[UIImage imageWithContentsOfFile:faceItem.pathForBackup]];
                    break;
                case kPhotoType:{
                    NSURL *photoURL = [NSURL URLWithString:faceItem.assetURLString];
                    [self.photoLibrary assetForURL:photoURL resultBlock:^(ALAsset *asset){
                        if (asset) {
                            UIImage *photoImage = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
                            [cell setShowContent:photoImage];
                        }else{
                            UIImage *photoImage = [UIImage imageNamed:@"Smartisan.png"];
                            [cell setShowContent:photoImage];
                        }
                    }failureBlock:nil];
                    break;
                }
            }
            break;
        }
        case DetailLineLayout:{
            cell.layer.borderWidth = 5.0f;
            cell.layer.borderColor = [[UIColor whiteColor] CGColor];
            NSIndexPath *selectedPersonIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:selectedPersonIndexPath];
            Photo *photoItem = faceItem.photoOwner;
            self.infoTitle.text = [NSString stringWithFormat:@"%d persons", photoItem.faceCount];
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
                }else{
                    UIImage *photoImage = [UIImage imageNamed:@"Smartisan.png"];
                    [cell setShowContent:photoImage];
                }

            }failureBlock:nil];
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
    NSUInteger tabIndex = [tabBar.items indexOfObject:item];
    if (self.currentGridCellType != tabIndex) {
        self.currentGridCellType = tabIndex;
        if ([self countForPageViewController] == 1) {
            [self.singlePageCollectionView reloadData];
        }else{
            UICollectionViewController *currentVC = (UICollectionViewController *)[self.pageViewController.viewControllers firstObject];
            [currentVC.collectionView reloadData];
        }
        
        Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.currentPortraitIndex]];
        [self updateHeaderView:faceItem];
    }
}


#pragma mark - Gesture Method
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecongnizer
{
    NSLog(@"Pinch Gesture.");
    NSLog(@"Velocity: %f", gestureRecongnizer.velocity);
    NSLog(@"Scale: %f", gestureRecongnizer.scale);
    if (gestureRecongnizer.velocity > 0) {
        //Pinch Out
        if (gestureRecongnizer.scale > 1.5f) {
            switch (self.currentLayoutType) {
                case PortraitLayout:{
                    NSLog(@"Switch to Horizontal Grid Mode.");
                    self.currentPortraitIndex = 2;
                    self.currentPageIndex = 0;
                    //Note: Must change layoutType before startingViewController, if not, startingViewController will get wrong data source
                    self.currentLayoutType = HorizontalGridLayout;
                    
                    if (self.pageVCArray.count > 0) {
                        [self.pageVCArray removeAllObjects];
                    }
                    
                    if ([self countForPageViewController] == 1) {
                        //CGRect contentRect = self.galleryView.frame;
                        NSLog(@"Single Page Mode");
                        self.galleryView.hidden = YES;
                        self.styleSwitch.hidden = NO;
                        self.singlePageCollectionView.hidden = NO;
                        [self.view addSubview:self.singlePageCollectionView];
                        [self.singlePageCollectionView reloadData];
                    }else{
                        UICollectionViewController *startingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
                        startingViewController.collectionView.dataSource = self;
                        startingViewController.collectionView.delegate = self;
                        [self.pageVCArray addObject:startingViewController];
                        
                        [self.pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
                        
                        //[self addChildViewController:self.pageViewController];
                        self.pageViewController.view.hidden = NO;
                        [self.view addSubview:self.pageViewController.view];
                        
                        CGRect contentRect = self.galleryView.frame;
                        self.pageViewController.view.frame = contentRect;
                        self.galleryView.hidden = YES;
                        self.styleSwitch.hidden = NO;
                        
                        //[self.pageViewController didMoveToParentViewController:self];
                        //self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
                    }
                    
                    break;
                }
                case HorizontalGridLayout:{
                    NSLog(@"Switch to Detail  Mode");
                    self.currentLayoutType = DetailLineLayout;
                    self.styleSwitch.hidden = YES;
                    
                    if ([self countForPageViewController] == 1) {
                        self.singlePageCollectionView.hidden = YES;
                    }else
                        self.pageViewController.view.hidden = YES;
                    
                    [self.detailContentCollectionView reloadData];
                    
                    NSInteger itemIndexBase = 0;
                    if (self.currentPageIndex > 0) {
                        itemIndexBase = (self.currentPageIndex - 1) * NumberOfAvatorPerPage;
                    }
                    
                    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:itemIndexBase inSection:0];
                    [self.detailContentCollectionView scrollToItemAtIndexPath:selectedIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                    [self.view addSubview:self.detailContentCollectionView];
                    
                    break;
                }
                default:
                    NSLog(@"Don't pinch out more.");
                    break;
            }
        }
    }else{
        //Pinch In
        
    }
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Select Item: %ld", (long)indexPath.item);
    switch (self.currentLayoutType) {
        case PortraitLayout:{
            NSLog(@"Switch to Horizontal Grid Mode.");
            self.currentPortraitIndex = indexPath.item;
            self.currentPageIndex = 0;
            //Note: Must change layoutType before startingViewController, if not, startingViewController will get wrong data source
            self.currentLayoutType = HorizontalGridLayout;
            
            //id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            //NSUInteger numberOfAvators = [sectionInfo numberOfObjects];
            //self.infoTitle.text = [NSString stringWithFormat:@"%lu avators", (unsigned long)numberOfAvators];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.currentPortraitIndex]];
            //self.nameTitle.text = faceItem.personOwner.name;
            
            if (self.pageVCArray.count > 0) {
                [self.pageVCArray removeAllObjects];
            }
            
            if ([self countForPageViewController] == 1) {
                NSLog(@"Single Page Mode");
                self.galleryView.hidden = YES;
                self.styleSwitch.hidden = NO;
                self.singlePageCollectionView.hidden = NO;
                [self.singlePageCollectionView reloadData];
            }else{
                UICollectionViewController *startingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
                startingViewController.collectionView.dataSource = self;
                startingViewController.collectionView.delegate = self;
                [self.pageVCArray addObject:startingViewController];
                
                [self.pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
                
                [self addChildViewController:self.pageViewController];
                self.pageViewController.view.hidden = NO;
                [self.view addSubview:self.pageViewController.view];
                
                CGRect contentRect = self.galleryView.frame;
                self.pageViewController.view.frame = contentRect;
                self.galleryView.hidden = YES;
                self.styleSwitch.hidden = NO;
                
                //[self.pageViewController didMoveToParentViewController:self];
                //self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
            }
            [self updateHeaderView:faceItem];
            
            [self.actionCenterButton setImage:[UIImage imageWithContentsOfFile:faceItem.pathForBackup] forState:UIControlStateNormal];
            self.actionCenterButton.imageView.layer.cornerRadius = 22.0f;
            self.actionCenterButton.imageView.clipsToBounds = YES;

            self.buttonPanel.hidden = YES;

            break;
        }
        case HorizontalGridLayout:{
            NSLog(@"Switch to Detail  Mode");
            self.currentLayoutType = DetailLineLayout;
            self.styleSwitch.hidden = YES;
            self.actionCenterButton.hidden = YES;
            if (!self.buttonPanel.hidden) {
                self.buttonPanel.hidden = YES;
                [self.buttonPanel hide];
            }
            
            if ([self countForPageViewController] == 1) {
                //self.singlePageCollectionView.hidden = YES;
            }else
                ;
                //self.pageViewController.view.hidden = YES;
            
            
            [self.view addSubview:self.detailContentCollectionView];
            [self.detailContentCollectionView reloadData];
            
            NSInteger itemIndexBase = 0;
            if ([self countForPageViewController] != 1) {
                itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
                NSLog(@"itemIndexBase: %d", itemIndexBase);
            }
            
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
            Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:selectedIndexPath];
            //Photo *photoItem = selectedFaceItem.photoOwner;
            //self.infoTitle.text = [NSString stringWithFormat:@"%d persons", photoItem.faceCount];
            
            //NSMutableString *nameString = [[NSMutableString alloc] initWithCapacity:photoItem.faceCount];
            //for (Face *faceItem in photoItem.faceset) {
            //    if (faceItem.name.length > 0) {
            //        [nameString appendString:[NSString stringWithFormat:@"%@ ",faceItem.name]];
            //    }
            //}
            //self.nameTitle.text = (NSString *)[nameString copy];
            [self.detailContentCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:selectedIndexPath.item inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            //[self.view addSubview:self.detailContentCollectionView];
            [self updateHeaderView:selectedFaceItem];

            break;
        }
        case DetailLineLayout:{
            NSLog(@"Swith Back to Portrait Mode.");
            self.currentLayoutType = PortraitLayout;
            if ([self countForPageViewController] == 1) {
                self.singlePageCollectionView.hidden = NO;
            }else
                self.pageViewController.view.hidden = NO;
            [self.detailContentCollectionView removeFromSuperview];
            self.nameTitle.text = @"";
            self.infoTitle.text = @"";
            [self.actionCenterButton setImage:[UIImage imageNamed:@"user_male2-50.png"] forState:UIControlStateNormal];
            [self dismissAvatorView];
            break;
        }
        default:
            NSLog(@"Bad Way!");
            break;
    }
    
}

- (void)dismissAvatorView
{
    if ([self countForPageViewController] == 1) {
        self.singlePageCollectionView.hidden = YES;
        //[self.singlePageCollectionView removeFromSuperview];
    }else{
        self.pageViewController.view.hidden = YES;
        //[self.pageViewController.view removeFromSuperview];
    }
    self.actionCenterButton.hidden = NO;
    self.galleryView.hidden = NO;
    self.styleSwitch.hidden = YES;
    self.currentPageIndex = 0;
    
    if (self.pageViewController) {
        for (UIGestureRecognizer *gr in self.pageViewController.gestureRecognizers) {
            [self.view removeGestureRecognizer:gr];
        }
    }
    
    if (self.pageVCArray.count > 0) {
        [self.pageVCArray removeAllObjects];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;

    switch (self.currentLayoutType) {
        case PortraitLayout:
            edgeInsets = UIEdgeInsetsMake(200, 50, 200, 50);
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
            cellSize = CGSizeMake(200, 200);
            break;
        case HorizontalGridLayout:{
            switch (self.currentGridCellType) {
                case kFaceType:
                    cellSize = CGSizeMake(144, 144);
                    break;
                default:
                    cellSize = CGSizeMake(144, 144);
                    break;
            }
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
                    space = 15.0f;
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
        default:
            break;
    }
    return space;
}

- (IBAction)scanPhotoLibrary:(id)sender
{
    NSLog(@"Scan Library");
    if ([self.newPhotoDetector shouldScanPhotoLibrary]) {
        if (self.navigationController.childViewControllers.count == 3) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }else{
            UIViewController *newRootVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ScanRoom"];
            [self.navigationController setViewControllers:@[newRootVC] animated:YES];
        }
    }else
        NSLog(@"Nothing to Do.");

}

- (IBAction)searchPerson:(id)sender
{
    NSLog(@"Search as you like.");
}

- (IBAction)editAlbum:(id)sender
{
    NSLog(@"Need a little change.");
    NSLog(@"Check for deleted photos");
    [self handleDeletedPhotos];
    if (self.navigationController.childViewControllers.count > 1 && [self.navigationController.topViewController isEqual:self]) {
        NSLog(@"Pop self");
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        NSLog(@"Segue Jump");
        [self performSegueWithIdentifier:@"enterMontageRoom" sender:self];
    }
}

- (void)handleDeletedPhotos
{
    NSLog(@"Handle for Delete");
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
                NSLog(@"Some Thing Wrong");
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
                NSLog(@"Some Wrong here");
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

@end
