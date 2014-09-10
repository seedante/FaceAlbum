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
#import "SDEPortraitCell.h"
#import "SDEGalleryModel.h"

static NSString *PortraitCellIdentifier = @"PortraitCell";
static NSString *AvatorCellIdentifier = @"AvatorCell";
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

@property (nonatomic) UICollectionView *detailContentView;

@property (nonatomic) NSMutableArray *pageVCArray;
@property (nonatomic) UIGestureRecognizer *swipeGestureRecognizer;


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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    //_faceFetchedResultsController.delegate = self;
    
    return _faceFetchedResultsController;
}

- (NSFetchedResultsController *)personFetchedResultsController
{
    if (_personFetchedResultsController != nil) {
        return _personFetchedResultsController;
    }
    
    _personFetchedResultsController = [[Store sharedStore] personFetchedResultsController];
    //_personFetchedResultsController.delegate = self;
    
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
    if ([self countForPageViewController:nil] == 1) {
        return nil;
    }
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    NSLog(@"Current Page Index: %d", self.currentPageIndex);
    NSLog(@"Current VC: %@", viewController);
    NSLog(@"Array: %@", self.pageVCArray);
    if (self.currentPageIndex == 0 || self.currentPageIndex == NSNotFound) {
        NSLog(@"???");
        return nil;
    }
    self.currentPageIndex--;
    UIViewController *vc = (UIViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex];
    NSLog(@"Previous VC: %@", vc);
    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSLog(@"After");
    if ([self countForPageViewController:nil] == 1) {
        return nil;
    }
    NSInteger countOfPage = [self countForPageViewController:nil];
    self.currentPageIndex = [self.pageVCArray indexOfObjectIdenticalTo:viewController];
    if (self.currentPageIndex >= countOfPage - 1 || self.currentPageIndex == NSNotFound) {
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
    }else
        NSLog(@"PageVC is full.");
        
    self.currentPageIndex++;
    vc = (UICollectionViewController *)[self.pageVCArray objectAtIndex:self.currentPageIndex];
    NSLog(@"Array: %@", self.pageVCArray);
    NSLog(@"Next VC: %@", vc);
    return vc;
}

- (NSInteger)countForPageViewController:(UIPageViewController *)pageViewController
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
    //NSUInteger itemCount = [sectionInfo numberOfObjects];
    NSInteger pageCount = ceil([sectionInfo numberOfObjects]/DoubleValueOfAvatorPerPage);
    return pageCount;
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"Count of Page: %ld", (long)[self countForPageViewController:pageViewController]);
    return [self countForPageViewController:pageViewController];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    return self.currentPageIndex;
}


#pragma mark - UICollectionView Data Source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems;
    if ([collectionView isEqual:self.galleryView]) {
        NSLog(@"There are %d person", [[self.faceFetchedResultsController sections] count]);
        numberOfItems = [[self.faceFetchedResultsController sections] count];
    }else{
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
        numberOfItems = [sectionInfo numberOfObjects];
        if (numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage >= NumberOfAvatorPerPage) {
            numberOfItems = NumberOfAvatorPerPage;
        }else
            numberOfItems = numberOfItems - self.currentPageIndex * NumberOfAvatorPerPage;
    }
    /*
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
            break;
        }
        default:
            break;
     
        case DetailLineLayout:{
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            break;
        }
    }*/
    
    return numberOfItems;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    SDEPortraitCell *cell;
    
    if ([collectionView isEqual:self.galleryView]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:PortraitCellIdentifier forIndexPath:indexPath];
        Face *firstFaceInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
        [cell setPortrait:firstFaceInSection.posterImage];
    }else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:AvatorCellIdentifier forIndexPath:indexPath];
        NSInteger itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
        NSIndexPath *faceIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
        Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:faceIndexPath];
        [cell setPortrait:faceItem.avatorImage];
    }
    /*
    switch (self.currentLayoutType) {
        case PortraitLayout:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:PortraitCellIdentifier forIndexPath:indexPath];
            Face *firstFaceInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
            [cell setPortrait:firstFaceInSection.posterImage];
            break;
        }
        case HorizontalGridLayout:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:AvatorCellIdentifier forIndexPath:indexPath];
            NSInteger itemIndexBase = self.currentPageIndex * NumberOfAvatorPerPage;
            NSIndexPath *faceIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:faceIndexPath];
            [cell setPortrait:faceItem.avatorImage];
            break;
        }
        default:
            break;
        case DetailLineLayout:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:PortraitCellIdentifier forIndexPath:indexPath];
            UIImage *backgroundImage = [UIImage imageNamed:@"bg4.jpg"];
            [cell setPortrait:backgroundImage];
            break;
        }
     
    }
    */

    //NSLog(@"Cell Size: %f %f", cell.bounds.size.height, cell.bounds.size.width);
    return cell;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.galleryView]) {
        self.currentPortraitIndex = indexPath.item;
        self.currentPageIndex = 0;
        
        if (self.pageVCArray.count > 0) {
            [self.pageVCArray removeAllObjects];
        }
        
        UICollectionViewController *startingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatorVC"];
        [self.pageVCArray addObject:startingViewController];
        startingViewController.collectionView.dataSource = self;
        startingViewController.collectionView.delegate = self;
        [self.pageViewController setViewControllers:@[startingViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        
        [self addChildViewController:self.pageViewController];
        [self.view addSubview:self.pageViewController.view];
        
        CGRect contentRect = self.galleryView.frame;
        self.pageViewController.view.frame = contentRect;
        self.galleryView.hidden = YES;
        self.styleSwitch.hidden = NO;
        
        [self.pageViewController didMoveToParentViewController:self];
        self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
        
        self.currentLayoutType = HorizontalGridLayout;
    }else{
        //NSLog(@"What happen?");
        [self dismissAvatorView];
        self.currentLayoutType = PortraitLayout;
    }
    /*
    switch (self.currentLayoutType) {
        case PortraitLayout:{

            
            self.currentLayoutType = HorizontalGridLayout;
            break;
        }
        case HorizontalGridLayout:{
            CGRect contentRect = self.galleryView.frame;
            UICollectionViewFlowLayout *horizontalLayout = [[UICollectionViewFlowLayout alloc] init];
            self.detailContentView = [[UICollectionView alloc] initWithFrame:contentRect collectionViewLayout:horizontalLayout];
            self.detailContentView.dataSource = self;
            self.detailContentView.delegate = self;
            
            self.pageViewController.view.hidden = YES;
            [self.view addSubview:self.detailContentView];
            self.currentLayoutType = DetailLineLayout;
            break;
        }
        default:
            break;
        case DetailLineLayout:{
            if (self.detailContentView) {
                [self.detailContentView removeFromSuperview];
                self.detailContentView = nil;
            }
            self.currentLayoutType = PortraitLayout;
            NSLog(@"Cleaning");
            [self dismissAvatorView];
            break;
        }
     
    }
*/
    
}

- (void)dismissAvatorView
{
    [self.pageViewController.view removeFromSuperview];
    [self.pageViewController removeFromParentViewController];
    //self.pageViewController = nil;
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
    if ([collectionView isEqual:self.galleryView]) {
        edgeInsets = UIEdgeInsetsMake(200, 50, 200, 50);
    }else
        edgeInsets = UIEdgeInsetsMake(0, 60, 0, 60);
    
    /*
    switch (self.currentLayoutType) {
        case PortraitLayout:
            edgeInsets = UIEdgeInsetsMake(200, 50, 200, 50);
            break;
        case HorizontalGridLayout:
            edgeInsets = UIEdgeInsetsMake(0, 60, 0, 60);
        case DetailLineLayout:
            edgeInsets = UIEdgeInsetsMake(100, 50, 100, 50);
            break;
    }
     */
    
    return edgeInsets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize = CGSizeZero;
    if ([collectionView isEqual:self.galleryView]) {
        cellSize = CGSizeMake(200, 200);
    }else
        cellSize = CGSizeMake(150, 150);
    /*
    switch (self.currentLayoutType) {
        case PortraitLayout:
            cellSize = CGSizeMake(200, 200);
            break;
        case HorizontalGridLayout:
            cellSize = CGSizeMake(150, 150);
        case DetailLineLayout:
            cellSize = CGSizeMake(500, 500);
            break;
    }
    */
    
    return cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat space = 0.0f;
    if ([collectionView isEqual:self.galleryView]) {
        space = 50.0f;
    }else
        space = 20.0f;
    return space;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat space = 0.0f;
    if ([collectionView isEqual:self.galleryView]) {
        space = 50.0f;
    }else
        space = 10.0f;
    return space;
}



- (IBAction)callActionCenter:(id)sender
{
    self.currentLayoutType = PortraitLayout;
    if ([self.view.subviews containsObject:self.pageViewController.view]) {
        [self dismissAvatorView];
    }
    //[self dismissViewControllerAnimated:YES completion:nil];

}
@end
