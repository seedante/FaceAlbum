//
//  SDEFaceRoomViewController.m
//  FaceAlbum
//
//  Created by seedante on 11/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEFaceRoomViewController.h"
#import "HorizontalCollectionViewLayout.h"
#import "SDEPhotoSceneDataSource.h"
#import "SDESpecialItemVC.h"
#import "SDENewPhotoDetector.h"
//#import "FJFlowLayoutWithAnimations.h"
#import "Face.h"
#import "Photo.h"
#import "Store.h"
#import "Person.h"
#import "LineLayout.h"
@import AssetsLibrary;
#import <QuartzCore/QuartzCore.h>

typedef enum: NSUInteger{
    kPortraitType,
    kLibraryType,
    kPhotoType,
} ShowContentType;

typedef enum: NSUInteger{
    kFaceType,
    kThumbnailType
} LibraryType;

static NSString *cellIdentifier = @"photoCell";
static NSUInteger numberOfItemsInPage = 20;

@interface SDEFaceRoomViewController ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;

@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSInteger portraitIndex;
@property (nonatomic) ShowContentType contentType;
@property (nonatomic) LibraryType libraryType;
@property (nonatomic) NSDictionary *assetsDictionary;
@property (nonatomic) NSInteger numberOfPerson;
@property (nonatomic) NSArray *personItemsArray;
@property (nonatomic) NSInteger itemNumber;
@property (nonatomic) NSInteger currentMaxItem;
@property (nonatomic) BOOL shouldFlyCell;
@property (nonatomic) BOOL shouldMoveToOriginal;
@property (nonatomic) BOOL shouldMoveToAssemblePosition;
@property (nonatomic) BOOL didCrossThreshold;
@property (nonatomic) NSIndexPath *lastVisibleIndexPath;
@property (nonatomic) CGPoint startPoint;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic) SDENewPhotoDetector *newerPhotoDetector;
@property (nonatomic) NSIndexPath *specialIndexPath;
@property (nonatomic) SDESpecialItemVC *libraryVC;

@end

@implementation SDEFaceRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES];
    //[[UITabBar appearance] setBarTintColor:[UIColor clearColor]];
    
    self.assetsDictionary = [[[SDEPhotoSceneDataSource sharedData] assetsDictionary] copy];
    self.portraitIndex = -1;
    self.contentType = kPortraitType;
    self.libraryType = kFaceType;
    self.librarySwitch.alpha = 0;
    self.librarySwitch.delegate = self;
    UITabBarItem *item = [self.librarySwitch.items objectAtIndex:self.libraryType];
    [self.librarySwitch setSelectedItem:item];
    
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controlShowOfTabBar:)];
    [self.galleryView addGestureRecognizer:self.tapGestureRecognizer];
    //[self.galleryView addGestureRecognizer:self.pinchGestureRecognizer];
    //[self.galleryView setCollectionViewLayout:[[FJFlowLayoutWithAnimations alloc] init]];
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Aged-Paper"]];
    
    NSString *startSceneName = [self startScene];
    if ([startSceneName isEqualToString:@"ScanRoom"]) {
        UIViewController *scanRoomVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ScanRoom"];
        [self.navigationController pushViewController:scanRoomVC animated:NO];
    }else if ([startSceneName isEqualToString:@"MontageRoom"]){
        UIViewController *montageRoomVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MontageRoom"];
        [self.navigationController pushViewController:montageRoomVC animated:NO];
    }
    
    
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

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"view will appear");
    [self fetchPerson];
    self.tabBarController.tabBar.hidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.buttonPanel.hidden = YES;
    [self.galleryView reloadData];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - Fetch Person
- (void)fetchPerson
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    [fetchRequest setFetchBatchSize:10];
    
    NSSortDescriptor *orderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:@[orderDescriptor]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(whetherToDisplay == YES) AND (ownedFaces.@count > 0)"];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    NSArray *personItems = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    self.numberOfPerson = personItems.count;
    self.personItemsArray = personItems;
    
}

#pragma mark - UICollectionView Data Source Method
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems;
    switch (self.contentType) {
        case kPortraitType:{
            [self fetchPerson];
            numberOfItems = self.numberOfPerson;
            NSLog(@"Now %ld persons.", (long)numberOfItems);
            break;
        }
        case kLibraryType:
        case kPhotoType:{
            id<NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.portraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            self.itemNumber = numberOfItems;
            //self.currentMaxItem = -1;
            break;
        }
    }
    NSLog(@"Cell Number: %ld in section: %ld", (long)numberOfItems, (long)section);
    return numberOfItems;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    UIImageView *photoView = (UIImageView *)[cell viewWithTag:10];
    
    switch (self.contentType) {
        case kPortraitType:{
            Person *personItem = [self.personItemsArray objectAtIndex:indexPath.item];
            if (personItem.order == 0) {
                [photoView setImage:[UIImage imageNamed:@"FacelessManPoster.jpg"]];
            }else{
                if (personItem.avatorImage) {
                    NSLog(@"Work");
                    [photoView setImage:personItem.avatorImage];
                }else
                    [photoView setImage:[UIImage imageWithContentsOfFile:personItem.posterURLString]];
            }
            photoView.alpha = 0.1;
            photoView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            
            //set shadow
            CALayer *layer = cell.layer;
            [layer setShadowOffset:CGSizeMake(0, 5)];
            [layer setShadowColor:[[UIColor blackColor] CGColor]];
            [layer setShadowOpacity:0.5];
            layer.masksToBounds = NO;
            //[layer setShadowPath:[[UIBezierPath bezierPathWithRect:cell.bounds] CGPath]];
            
            NSTimeInterval delay = indexPath.item * 0.1;
            [UIView animateWithDuration:0.5 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
                photoView.alpha = 1.0;
                photoView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                cell.userInteractionEnabled = NO;
            }completion:nil];
            
            break;
        }
        case kLibraryType:{
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:self.portraitIndex]];
            switch (self.libraryType) {
                case kFaceType:
                    [photoView setImage:faceItem.avatorImage];
                    break;
                case kThumbnailType:{
                    ALAsset *asset = self.assetsDictionary[faceItem.assetURLString];
                    if (asset) {
                        [photoView setImage:[UIImage imageWithCGImage:asset.aspectRatioThumbnail]];
                    }else
                        [photoView setImage:faceItem.photoOwner.thumbnail];
                    break;
                }
            }
            
            BOOL shouldAnimation = NO;
            if (indexPath.item > self.currentMaxItem) {
                shouldAnimation = YES;
                if (indexPath.item == self.itemNumber - 1) {
                    self.currentMaxItem = indexPath.item;
                }else if (indexPath.item == self.currentMaxItem + numberOfItemsInPage){
                    self.currentMaxItem = indexPath.item;
                }
            }
            
            if (shouldAnimation) {
                photoView.alpha = 0.1;
                photoView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                
                NSTimeInterval delay = (indexPath.item % numberOfItemsInPage) * 0.05;
                [UIView animateWithDuration:0.5 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{
                    photoView.alpha = 1.0;
                    photoView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                }completion:nil];
            }
            
            if (self.shouldFlyCell) {
                if (indexPath.item == self.itemNumber - 1 || indexPath.item == numberOfItemsInPage - 1)
                    self.shouldFlyCell = NO;
                
                UICollectionViewLayoutAttributes *attr = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
                
                CABasicAnimation *fly = [CABasicAnimation animationWithKeyPath:@"position"];
                fly.fromValue = [NSValue valueWithCGPoint:self.startPoint];
                fly.toValue = [NSValue valueWithCGPoint:attr.center];
                fly.duration = 0.5;
                [cell.layer addAnimation:fly forKey:@"FlyCell"];
            }
            
            if (self.shouldMoveToAssemblePosition) {
                //CABasicAnimation *move = [CABasicAnimation animationWithKeyPath:@"position"];
                //move.toValue = [NSValue valueWithCGPoint:self.startPoint];
                //NSTimeInterval delay = (numberOfItemsInPage - indexPath.item % numberOfItemsInPage) * 0.05;
                //move.beginTime = CACurrentMediaTime() + delay;
                //move.duration = 0.5;
                //[cell.layer addAnimation:move forKey:@"MoveToAssemblePosition"];
                //同下，有闪屏现象
                NSInteger pageIndex = self.lastVisibleIndexPath.item / numberOfItemsInPage;
                CGPoint relativeStartPoint;
                relativeStartPoint.x = self.startPoint.x + pageIndex * 1024;
                relativeStartPoint.y = self.startPoint.y;
                [UIView animateWithDuration:0.5
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     cell.center = relativeStartPoint;
                                     self.galleryView.alpha = 1.0f;
                                     self.librarySwitch.alpha = 0;
                }completion:^(BOOL finished){
                    if (finished) {
                        [UIView animateWithDuration:0.1
                                              delay:0
                                            options:UIViewAnimationOptionCurveEaseIn
                                         animations:^{
                                             CGPoint endPoint = relativeStartPoint;
                                             endPoint.y += 100;
                                             cell.center = endPoint;
                        }completion:nil];
                    }
                }];
                
                if ([indexPath isEqual:self.lastVisibleIndexPath]) {
                    [self performSelector:@selector(dismissLibraryVC) withObject:nil afterDelay:0.6];
                }

            }else if (self.shouldMoveToOriginal) {
                HorizontalCollectionViewLayout *layout = (HorizontalCollectionViewLayout *)self.libraryVC.collectionView.collectionViewLayout;
                UICollectionViewLayoutAttributes *attr = [layout originalLayoutAttributesForItemAtIndexPath:indexPath];
                /*
                CABasicAnimation *move = [CABasicAnimation animationWithKeyPath:@"position"];
                move.toValue = [NSValue valueWithCGPoint:attr.center];
                move.duration = 1;
                move.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                [cell.layer addAnimation:move forKey:@"MoveToOriginal"];
                 */
                //使用CA 动画在最后刷新布局时，会有闪屏的现象；而使用 UIView 动画不会有这种现象，不知道为什么，但是需要这种安静的动画效果
                NSTimeInterval delay = (indexPath.item % numberOfItemsInPage) * 0.01;
                [UIView animateWithDuration:1
                                      delay:delay
                                    options:UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     cell.center = attr.center;
                                     self.galleryView.alpha = 0;
                                 }completion:^(BOOL finished){
                                     if (finished) {
                                         self.galleryView.hidden = YES;
                                     }
                                 }];
                
                if ([indexPath isEqual:self.lastVisibleIndexPath]) {
                    self.shouldMoveToOriginal = NO;
                    [layout resetVisibleItems];
                    [layout performSelector:@selector(invalidateLayout) withObject:nil afterDelay:1];
                }
            }
            
            break;
        }
        case kPhotoType:{
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:self.portraitIndex]];
            ALAsset *asset = self.assetsDictionary[faceItem.assetURLString];
            if (asset) {
                [photoView setImage:[UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage]];
            }else{
                NSURL *assetURL = [NSURL URLWithString:faceItem.assetURLString];
                [self.photoLibrary assetForURL:assetURL resultBlock:^(ALAsset *assetForURL){
                    if (assetForURL) {
                        [photoView setImage:[UIImage imageWithCGImage:assetForURL.defaultRepresentation.fullScreenImage]];
                    }
                }failureBlock:^(NSError *error){
                    [photoView setImage:[UIImage imageNamed:@"AccessDenied.png"]];
                }];
            }
            
            break;
        }
    }
    return cell;
}



#pragma mark - UICollectionViewDelegateFlowLayout
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
    
    switch (self.contentType) {
        case kPortraitType:
            edgeInsets = UIEdgeInsetsMake(100.0f, 50.0f, 100.0f, 50.0f);
            break;
        case kLibraryType:
            edgeInsets = UIEdgeInsetsMake(10.0f, 60.0f, 10.0f, 60.0f);
            break;
        case kPhotoType:
            edgeInsets = UIEdgeInsetsZero;
            break;
    }
    
    return edgeInsets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize cellSize = CGSizeZero;
    switch (self.contentType) {
        case kPortraitType:
            cellSize = CGSizeMake(300, 300);
            break;
        case kLibraryType:{
            cellSize = CGSizeMake(144, 144);
            break;
        }
        case kPhotoType:{
            cellSize = CGSizeMake(1024, 654);
            break;
        }
    }
    
    return cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat space = 0.0f;
    switch (self.contentType) {
        case kPortraitType:
            space = 100.0f;
            break;
        case kLibraryType:
            space = 20.0f;
            break;
        case kPhotoType:
            break;
    }
    return space;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat space = 0.0f;
    switch (self.contentType) {
        case kPortraitType:
            space = 50.0f;
            break;
        case kLibraryType:
            space = 10.0f;
            break;
        case kPhotoType:
            space = 0.0f;
            break;
    }
    return space;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentMaxItem = -1;
    switch (self.contentType) {
        case kPortraitType:{
            
            self.shouldFlyCell = YES;
            self.shouldMoveToOriginal = NO;
            self.shouldMoveToAssemblePosition = NO;
            UICollectionViewLayoutAttributes *attr = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
            CGPoint cellPosition = attr.center;
            cellPosition.y = cellPosition.y - 150;
            self.startPoint = [self.view convertPoint:cellPosition fromView:self.galleryView];
            //self.startPoint = cellPosition;
            if (!self.tabBarController.tabBar.hidden) {
                self.tabBarController.tabBar.hidden = YES;
            }
            //self.librarySwitch.hidden = NO;
            [UIView animateWithDuration:0.5 animations:^{
                self.librarySwitch.alpha = 1.0f;
            }];
            self.portraitIndex = indexPath.item;
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            
            self.contentType = kLibraryType;
            self.libraryVC = (SDESpecialItemVC *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
            self.libraryVC.collectionView.frame = self.galleryView.frame;
            HorizontalCollectionViewLayout *springboardLayout = [[HorizontalCollectionViewLayout alloc] init];
            [self.libraryVC.collectionView setCollectionViewLayout:springboardLayout];
            self.libraryVC.collectionView.dataSource = self;
            self.libraryVC.collectionView.delegate = self;
            [self.libraryVC.collectionView setBackgroundColor:[UIColor clearColor]];
            self.galleryView.hidden = YES;
            
            [self addChildViewController:self.libraryVC];
            [self.view addSubview:self.libraryVC.collectionView];
            [self.libraryVC didMoveToParentViewController:self];
            [self.libraryVC.collectionView addGestureRecognizer:self.pinchGestureRecognizer];
            break;
        }
        case kLibraryType:{
            self.contentType = kPhotoType;
            [UIView animateWithDuration:0.5 animations:^{
                self.librarySwitch.alpha = 0;
            }];
            self.actionCenterButton.hidden = YES;

            /*
            //this works too.
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
            SDESpecialItemVC *detailVC = (SDESpecialItemVC *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
            detailVC.collectionView.frame = self.galleryView.frame;
            CGRect frame = self.galleryView.frame;
            detailVC.collectionView.dataSource = self;
            detailVC.collectionView.delegate = self;
            [detailVC.collectionView setBackgroundColor:[UIColor clearColor]];
            [detailVC.collectionView reloadData];
            [detailVC specifyStartIndexPath:indexPath];
            
            [self addChildViewController:detailVC];
            [self.view addSubview:detailVC.collectionView];
            [detailVC didMoveToParentViewController:self];
            
            [detailVC viewWillAppear:YES];
            */
            
            NSLog(@"Select item: %ld",(long)indexPath.item);
            //HorizontalCollectionViewLayout *detailLayout = [[HorizontalCollectionViewLayout alloc] init];
            
            LineLayout *detailLayout = [[LineLayout alloc] init];
            [self.libraryVC.collectionView setCollectionViewLayout:detailLayout animated:NO];
            [self.libraryVC.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            
            break;
        }
        case kPhotoType:{
            break;
        }
    }
}

- (void)animateCell:(UICollectionViewCell *)cell
{
    [UIView animateWithDuration:1 animations:^{
        cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }];
}

#pragma mark - UITabBarDelegate Method
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    
    //Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.portraitIndex]];
    //[self updateHeaderView:faceItem];
    LibraryType index = (LibraryType)[tabBar.items indexOfObject:item];
    switch (index) {
        case kFaceType:
            self.libraryType = kFaceType;
            [self.libraryVC.collectionView reloadData];
            break;
        case kThumbnailType:
            self.libraryType = kThumbnailType;
            [self.libraryVC.collectionView reloadData];
            break;
    }
}

#pragma mark - Gesture Method
- (void)controlShowOfTabBar:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.galleryView];
    
    switch (self.contentType) {
        case kPortraitType:{
            NSIndexPath *indexPath = [self.galleryView indexPathForItemAtPoint:location];
            if (!indexPath) {
                self.tabBarController.tabBar.hidden = !self.tabBarController.tabBar.hidden;
            }else{
                [self collectionView:self.galleryView didSelectItemAtIndexPath:indexPath];
            }
            break;
        }
        case kLibraryType:{
            NSIndexPath *indexPath = [self.libraryVC.collectionView indexPathForItemAtPoint:location];
            if (indexPath) {
                [self collectionView:self.libraryVC.collectionView didSelectItemAtIndexPath:indexPath];
            }
        }
        default:
            break;
    }
    
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecongnizer
{
    if (self.libraryVC) {
        self.libraryVC.collectionView.allowsSelection = NO;
    }
    if ([gestureRecongnizer numberOfTouches] > 2) {
        NSLog(@"More than 2");
        return;
    }
    switch (gestureRecongnizer.state) {
        case UIGestureRecognizerStatePossible:
            NSLog(@"Possible");
            break;
        case UIGestureRecognizerStateBegan:
            NSLog(@"Begin");
            break;
        case UIGestureRecognizerStateChanged:
            NSLog(@"Change");
            break;
        case UIGestureRecognizerStateEnded:
            NSLog(@"End");
            break;
        case UIGestureRecognizerStateFailed:
            NSLog(@"Failed");
            break;
        case UIGestureRecognizerStateCancelled:
            NSLog(@"Cancelled");
            break;
        default:
            NSLog(@"I have no idea");
            break;
    }
    
    if (gestureRecongnizer.state == UIGestureRecognizerStateBegan || gestureRecongnizer.state == UIGestureRecognizerStateChanged) {
        switch (self.contentType) {
            case kPortraitType:{
                CGPoint centroid = [gestureRecongnizer locationInView:self.galleryView];
                NSInteger number = [self.galleryView numberOfItemsInSection:0];
                for (NSInteger i = 0; i < number; i++) {
                    UICollectionViewLayoutAttributes *attributes = [self.galleryView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                    if (attributes) {
                        if (CGRectContainsPoint(attributes.frame, centroid)) {
                            NSLog(@"Centroid at Item: %ld", (long)i);
                            break;
                        }
                    }
                }
                break;
            }
            case kLibraryType:{
                if (gestureRecongnizer.scale > 0.8f) {
                    self.didCrossThreshold = NO;
                }
                if (gestureRecongnizer.scale < 0.5f) {
                    self.didCrossThreshold = YES;
                }
                HorizontalCollectionViewLayout *layout = (HorizontalCollectionViewLayout *)self.libraryVC.collectionView.collectionViewLayout;
                NSArray *visibleIndexPaths = [self.libraryVC.collectionView indexPathsForVisibleItems];
                NSArray *sortedArray = [visibleIndexPaths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item" ascending:YES]]];
                NSIndexPath *currentItemInPage = sortedArray.lastObject;
                NSInteger pageIndex = currentItemInPage.item / numberOfItemsInPage;
                CGPoint relativeStartPoint;
                relativeStartPoint.x = self.startPoint.x + pageIndex * 1024;
                relativeStartPoint.y = self.startPoint.y;
                [layout relocateVisibleItems:visibleIndexPaths withAssemblePosition:relativeStartPoint Scale:gestureRecongnizer.scale];
                [layout invalidateLayout];
                
                if (gestureRecongnizer.scale > 0.8f && gestureRecongnizer.scale < 1.0f) {
                     NSLog(@"Scale: %f", gestureRecongnizer.scale);
                    self.galleryView.alpha = 1 - gestureRecongnizer.scale;
                }else if (gestureRecongnizer.scale > 1.0f){
                     NSLog(@"Scale: %f", gestureRecongnizer.scale);
                    self.galleryView.hidden = YES;
                    self.galleryView.alpha = 0;
                }else if (gestureRecongnizer.scale < 0.5f){
                     NSLog(@"Scale: %f", gestureRecongnizer.scale);
                    self.galleryView.hidden = NO;
                    self.galleryView.alpha = 1 - gestureRecongnizer.scale;
                }

                break;
            }
            case kPhotoType:
                DLog(@"Scale Cell");
                break;
        }
    }
    
    if (gestureRecongnizer.state == UIGestureRecognizerStateEnded || gestureRecongnizer.state == UIGestureRecognizerStateCancelled ||gestureRecongnizer.state == UIGestureRecognizerStateFailed) {
        //[self performSelector:@selector(enableLibraryCellSelection) withObject:nil afterDelay:0.5];
        self.libraryVC.collectionView.allowsSelection = YES;
        
        switch (self.contentType) {
            case kLibraryType:{
                NSArray *visibleIndexPaths = [self.libraryVC.collectionView indexPathsForVisibleItems];
                NSArray *sortedArray = [visibleIndexPaths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item" ascending:YES]]];
                self.lastVisibleIndexPath = sortedArray.lastObject;
                
                if (self.didCrossThreshold) {
                    self.shouldMoveToAssemblePosition = YES;
                    self.shouldMoveToOriginal = NO;
                }else{
                    self.shouldMoveToAssemblePosition = NO;
                    self.shouldMoveToOriginal = YES;
                }
                self.didCrossThreshold = NO;
                [self.libraryVC.collectionView reloadItemsAtIndexPaths:visibleIndexPaths];
                break;
                
            }
            case kPhotoType:{
                HorizontalCollectionViewLayout *springboardLayout = [[HorizontalCollectionViewLayout alloc] init];
                [self.libraryVC.collectionView setCollectionViewLayout:springboardLayout];
                self.contentType = kLibraryType;
                [UIView animateWithDuration:0.5 animations:^{
                    self.librarySwitch.alpha = 1.0f;
                }];
                [self.libraryVC.collectionView reloadData];
                break;
            }
                
            default:
                break;
        }

        /*
        if (gestureRecongnizer.scale < 0.5f) {
            NSLog(@"scanle < 0.5");
            switch (self.contentType) {
                case kPortraitType:
                    break;
                case kLibraryType:{
                    NSLog(@"Go back to PortraitType");
                    self.contentType = kPortraitType;
                    self.librarySwitch.hidden = YES;
                    [self.libraryVC.collectionView removeGestureRecognizer:self.pinchGestureRecognizer];
                    self.libraryVC.collectionView.dataSource = nil;
                    self.libraryVC.collectionView.delegate = nil;
                    [self.libraryVC.collectionView removeFromSuperview];
                    
                    [self.libraryVC removeFromParentViewController];
                    self.libraryVC = nil;
                    self.galleryView.hidden = NO;
                    break;
                }
                case kPhotoType:
                    self.contentType = kLibraryType;
                    self.librarySwitch.hidden = NO;
                    self.actionCenterButton.hidden = NO;
                    HorizontalCollectionViewLayout *libraryLayout = [[HorizontalCollectionViewLayout alloc] init];
                    [self.libraryVC.collectionView setCollectionViewLayout:libraryLayout animated:YES];
                    break;
            }
            
        }
         */
        
    }

}

- (void)dismissLibraryVC
{
    self.librarySwitch.alpha = 0;
    [self.libraryVC.collectionView removeGestureRecognizer:self.pinchGestureRecognizer];
    [self.libraryVC.collectionView removeFromSuperview];
    [self.libraryVC removeFromParentViewController];
    self.libraryVC = nil;
    
    self.contentType = kPortraitType;
    self.shouldMoveToAssemblePosition = NO;
    
    /*
    UICollectionViewCell *cell = [self.galleryView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.portraitIndex inSection:0]];
    CAKeyframeAnimation *shine = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    shine.keyTimes = @[@0, @(1/6.0), @(3/6.0), @(5/6.0), @1];
    shine.values = @[@0.8, @0.5, @0.8, @0.5, @0.8];
    shine.duration = 1;
    [cell.layer addAnimation:shine forKey:@"shine"];
     */
    
}

#pragma mark - IBAction Method
- (IBAction)scanPhotoLibrary:(id)sender
{
    DLog(@"Scan Library");
    if ([self.newerPhotoDetector shouldScanPhotoLibrary]) {
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
    self.contentType = kPortraitType;
    
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
    
    self.librarySwitch.hidden = YES;
    self.actionCenterButton.hidden = NO;
    [self.actionCenterButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
    self.galleryView.hidden = NO;
    
}

- (void)handleDeletedPhotos
{
    DLog(@"Handle for Delete");
    NSArray *deletedAssetsURLString = [self.newerPhotoDetector notexistedAssetsURLString];
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
    
    NSArray *gobackAssetsURLString = [self.newerPhotoDetector againStoredAssetsURLString];
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
    
    [self.newerPhotoDetector cleanData];
}

- (IBAction)popMenu:(id)sender
{
    if (![self.newerPhotoDetector shouldScanPhotoLibrary]) {
        self.scanRoomButton.hidden = YES;
    }else
        self.scanRoomButton.hidden = NO;
    if ([[self.newerPhotoDetector notexistedAssetsURLString] count] > 0) {
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
