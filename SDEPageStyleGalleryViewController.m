//
//  SDEPageStyleGalleryViewController.m
//  FaceAlbum
//
//  Created by seedante on 9/8/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPageStyleGalleryViewController.h"
#import "Store.h"
#import "Face.h"
#import "SDEGalleryCell.h"
#import "SDEGalleryModel.h"
#import "LineLayout.h"

static NSString *CellIdentifier = @"GalleryCell";

#define NumberOfAvatorPerPage 20
#define DoubleValueOfAvatorPerPage 20.0

typedef enum: NSUInteger{
    PortraitLayout,
    HorizontalGridLayout,
    DetailLineLayout
} LayoutType;

@interface SDEPageStyleGalleryViewController ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSFetchedResultsController *personFetchedResultsController;
@property (nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) SDEGalleryModel *galleryModel;

@property (nonatomic) NSInteger currentPortraitIndex;
@property (nonatomic) NSInteger currentPageIndex;
@property (nonatomic) LayoutType currentLayoutType;

@property (nonatomic) UICollectionViewController *singlePageCollectionViewController;
@property (nonatomic) UICollectionView *singlePageCollectionView;
@property (nonatomic) UICollectionViewController *detailContentViewController;
@property (nonatomic) UICollectionView *detailContentCollectionView;

@property (nonatomic) NSMutableArray *pageVCArray;
@property (nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

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
    
    /*
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:self.pinchGestureRecognizer];
    [self.singlePageCollectionView addGestureRecognizer:self.pinchGestureRecognizer];
    [self.pageViewController.view addGestureRecognizer:self.pinchGestureRecognizer];
    [self.detailContentCollectionView addGestureRecognizer:self.pinchGestureRecognizer];
     */
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
        
        CGRect contentRect = self.galleryView.frame;
        _detailContentViewController.collectionView.frame = contentRect;
        _detailContentViewController.collectionView.dataSource = self;
        _detailContentViewController.collectionView.delegate = self;
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

- (SDEGalleryModel *)galleryModel
{
    if (!_galleryModel) {
        _galleryModel = [[SDEGalleryModel alloc] init];
    }
    
    return _galleryModel;
}


#pragma mark - UIPageViewController Data Source
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSLog(@"Before");
    if ([self countForPageViewController] == 1) {
        return nil;
    }
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    NSLog(@"Current Page Index: %d", self.currentPageIndex);
    NSLog(@"Current VC: %@", viewController);
    NSLog(@"Array: %@", self.pageVCArray);
    if (self.currentPageIndex == 0 || self.currentPageIndex == NSNotFound) {
        self.currentPageIndex = 0;
        NSLog(@"???");
        return nil;
    }
    self.currentPageIndex--;
    UIViewController *vc = (UIViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex];
    self.currentPageIndex+= 2;
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
        NSLog(@"C: %d", self.currentPageIndex);
        self.currentPageIndex++;
        NSLog(@"!!!");
        return nil;
    }
    
    NSLog(@"Current Page Index: %d", self.currentPageIndex);
    NSLog(@"Current VC: %@", viewController);
    UICollectionViewController *vc;
    if (self.pageVCArray.count < countOfPage) {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
        vc.collectionView.dataSource = self;
        vc.collectionView.delegate = self;
        [self.pageVCArray addObject:vc];
        NSLog(@"Count of PageVCArray: %d", self.pageVCArray.count);
    }
        
    self.currentPageIndex++;
    vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex];
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
    NSLog(@"Current Page Index: %d", index);
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
            NSLog(@"There are %d person", [[self.faceFetchedResultsController sections] count]);
            numberOfItems = [[self.faceFetchedResultsController sections] count];
            break;
        }
        case HorizontalGridLayout:{
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            if (numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage >= NumberOfAvatorPerPage) {
                numberOfItems = NumberOfAvatorPerPage;
            }else
                numberOfItems = numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage;
            NSLog(@"Avator Number: %d in Page: %d", numberOfItems, self.currentPageIndex);
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
            [cell setShowContent:firstFaceInSection.posterImage];
            break;
        }
        case HorizontalGridLayout:{
            NSInteger itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
            NSIndexPath *faceIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:faceIndexPath];
            [cell setShowContent:faceItem.avatorImage];
            break;
        }
        case DetailLineLayout:{
            NSIndexPath *selectedPersonIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:selectedPersonIndexPath];
            [cell setShowContent:faceItem.avatorImage];
            break;
        }
        default:
            break;
    }
    
    return cell;
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
    NSLog(@"Select Item: %d", indexPath.item);
    switch (self.currentLayoutType) {
        case PortraitLayout:{
            NSLog(@"Switch to Horizontal Grid Mode.");
            self.currentPortraitIndex = indexPath.item;
            self.currentPageIndex = 0;
            //Note: Must change layoutType before startingViewController, if not, startingViewController will get wrong data source
            self.currentLayoutType = HorizontalGridLayout;
            
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            NSUInteger numberOfAvators = [sectionInfo numberOfObjects];
            self.infoTitle.text = [NSString stringWithFormat:@"%d avators", numberOfAvators];
            
            if (self.pageVCArray.count > 0) {
                [self.pageVCArray removeAllObjects];
            }
            
            if ([self countForPageViewController] == 1) {
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
            
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:0];
            [self.detailContentCollectionView scrollToItemAtIndexPath:selectedIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            [self.view addSubview:self.detailContentCollectionView];

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
        self.singlePageCollectionView.hidden = NO;
        [self.singlePageCollectionView removeFromSuperview];
    }else{
        self.pageViewController.view.hidden = NO;
        [self.pageViewController.view removeFromSuperview];
    }

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
            edgeInsets = UIEdgeInsetsMake(10, 60, 20, 60);
            break;
        case DetailLineLayout:
            edgeInsets = UIEdgeInsetsMake(50, 262, 50, 262);
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
        case HorizontalGridLayout:
            cellSize = CGSizeMake(144, 144);
            break;
        case DetailLineLayout:{
            cellSize = CGSizeMake(500, 500);
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
            space = 20.0f;
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
            space = 10.0f;
            break;
        case DetailLineLayout:
            space = 524.0f;
            break;
        default:
            break;
    }
    return space;
}


- (IBAction)callActionCenter:(id)sender
{
    self.currentLayoutType = PortraitLayout;
    [self dismissAvatorView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
