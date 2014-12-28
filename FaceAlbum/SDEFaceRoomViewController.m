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
#import "SDEPhotoFileFilter.h"
#import "Face.h"
#import "Photo.h"
#import "Store.h"
#import "Person.h"
#import "LineLayoutWithAnimation.h"
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

static NSString * const cellIdentifier = @"photoCell";
static NSUInteger const numberOfItemsInPage = 20;
static CGFloat const kPhotoWidth = 1024.0;
static CGFloat const kPhotoHeight = 654.0;

@interface SDEFaceRoomViewController ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSString *storeFolder;

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
@property (nonatomic) BOOL shouldScaleAndBack;
@property (nonatomic) NSIndexPath *lastVisibleIndexPath;
@property (nonatomic) CGPoint assemblePoint;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic) SDEPhotoFileFilter *photoFileFilter;
@property (nonatomic) NSIndexPath *specialIndexPath;
@property (nonatomic) SDESpecialItemVC *libraryVC;
@property (nonatomic) SDESpecialItemVC *photoVC;

@end

@implementation SDEFaceRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self.navigationController setNavigationBarHidden:YES];
    
    self.assetsDictionary = [[[SDEPhotoSceneDataSource sharedData] assetsDictionary] copy];
    self.portraitIndex = -1;
    self.contentType = kPortraitType;
    self.libraryType = kFaceType;
    self.librarySwitch.alpha = 0;
    self.librarySwitch.delegate = self;
    UITabBarItem *item = [self.librarySwitch.items objectAtIndex:self.libraryType];
    [self.librarySwitch setSelectedItem:item];
    self.photoFileFilter = [SDEPhotoFileFilter sharedPhotoFileFilter];
    
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
    [self registerAsObserver];
    self.actionCenterButton.layer.cornerRadius = 22.0f;
    self.actionCenterButton.layer.masksToBounds = YES;
    
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

- (NSString *)storeFolder
{
    if (!_storeFolder) {
        _storeFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    }
    
    return _storeFolder;
}

- (void)registerAsObserver
{
    [self addObserver:self forKeyPath:@"contentType" options:0 context:NULL];
    //[self addObserver:self forKeyPath:@"libraryType" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentType"] || [keyPath isEqualToString:@"libraryType"]) {
        [self updateHeaderView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"show portrait");
    [self.photoFileFilter comparePhotoDataBetweenLocalAndDataBase];
    self.tabBarController.tabBar.hidden = YES;
    [self.navigationController setNavigationBarHidden:YES];
    self.buttonPanel.hidden = YES;
    //由于没有引入NSFetchedresultscontroller 后必须设置 delegate 才能更新 person，故在这里采用手动刷新内容。
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

#pragma mark - Fetch Person
- (void)fetchPerson
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    [fetchRequest setFetchBatchSize:10];
    
    NSSortDescriptor *orderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:@[orderDescriptor]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(whetherToDisplay == YES) AND (ownedFaces.@count > 0)"];
    [fetchRequest setPredicate:predicate];
    
    NSMutableArray *personItemsMutableArray = [NSMutableArray new];
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    if (faceItem.section == 0) {
        [personItemsMutableArray addObject: [[Store sharedStore] FacelessMan]];
    }
    //错误处理还不知怎么做
    //NSError *error;
    NSArray *personItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (personItems && personItems.count > 0) {
        [personItemsMutableArray addObjectsFromArray:personItems];
    }
    self.numberOfPerson = personItemsMutableArray.count;
    self.personItemsArray = [personItemsMutableArray copy];
    
}

- (void)checkRightBarButtionItem
{
    NSArray *sections = self.faceFetchedResultsController.sections;
    if (sections.count > 1) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else if (sections.count == 1){
        Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        if (faceItem.section == 0) {
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }else
            self.navigationItem.rightBarButtonItem.enabled = YES;
    }else
        self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark - UICollectionView Data Source Method
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems;
    switch (self.contentType) {
        case kPortraitType:{
            [self fetchPerson];
            numberOfItems = self.numberOfPerson;
            break;
        }
        case kLibraryType:
        case kPhotoType:{
            id<NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.portraitIndex];
            numberOfItems = [sectionInfo numberOfObjects];
            self.itemNumber = numberOfItems;
            break;
        }
    }
    //NSLog(@"Cell Number: %ld in section: %ld", (long)numberOfItems, (long)section);
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
                NSString *imagePath = [self.storeFolder stringByAppendingPathComponent:personItem.portraitFileString];
                UIImage *avatorImage = [UIImage imageWithContentsOfFile:imagePath];
                if (avatorImage) {
                    [photoView setImage:avatorImage];
                }else
                    [photoView setImage:personItem.avatorImage];
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
                //cell.userInteractionEnabled = NO;//不知道这行代码有啥效果
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
                    }else{
                        NSLog(@"asset cache error");
                        //[photoView setImage:faceItem.photoOwner.thumbnail];
                        NSURL *assetURL = [NSURL URLWithString:faceItem.assetURLString];
                        [self.photoLibrary assetForURL:assetURL resultBlock:^(ALAsset *assetForURL){
                            if (assetForURL) {
                                [photoView setImage:[UIImage imageWithCGImage:assetForURL.aspectRatioThumbnail]];
                            }else
                                [photoView setImage:nil];
                        }failureBlock:^(NSError *error){
                            [photoView setImage:[UIImage imageNamed:@"AccessDenied.png"]];
                        }];
                    }
                    break;
                }
            }
            
            BOOL shouldAnimation = NO;
            if (indexPath.item > self.currentMaxItem) {
                shouldAnimation = YES;
                if (indexPath.item == self.itemNumber - 1 || indexPath.item == self.currentMaxItem + numberOfItemsInPage) {
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
                fly.fromValue = [NSValue valueWithCGPoint:self.assemblePoint];
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
                CGPoint relativeAssemblePoint = [self.libraryVC.collectionView convertPoint:self.assemblePoint fromView:self.view];
                [UIView animateWithDuration:0.5
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     cell.center = relativeAssemblePoint;
                                     self.galleryView.alpha = 1.0f;
                                     self.librarySwitch.alpha = 0;
                }completion:nil];
                
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
                //NSLog(@"asset cache");
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
            
            [self updateHeaderViewAtIndexPath:indexPath];
            //set shadow
            CALayer *layer = cell.layer;
            [layer setShadowOffset:CGSizeMake(0, 5)];
            [layer setShadowColor:[[UIColor blackColor] CGColor]];
            [layer setShadowOpacity:0.5];
            layer.masksToBounds = NO;
            
            if (self.shouldScaleAndBack) {
                NSArray *indexPaths = [self.libraryVC.collectionView indexPathsForVisibleItems];
                NSArray *sortedArray = [indexPaths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item" ascending:YES]]];
                NSIndexPath *libraryVCMaxIndexPath = sortedArray.lastObject;
                NSIndexPath *libraryVCMinIndexPath = sortedArray.firstObject;
                //NSLog(@"min: %ld max:%ld", (long)libraryVCMinIndexPath.item, (long)libraryVCMaxIndexPath.item);
                NSIndexPath *targetIndexPath;
                if (indexPath.item > libraryVCMaxIndexPath.item || indexPath.item < libraryVCMinIndexPath.item) {
                    NSInteger item = indexPath.item % numberOfItemsInPage + libraryVCMinIndexPath.item;
                    //NSLog(@"item: %ld", (long)item);
                    targetIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
                }else
                    targetIndexPath = indexPath;
                //NSLog(@"target: %ld", (long)targetIndexPath.item);
                
                CABasicAnimation *move = [CABasicAnimation animationWithKeyPath:@"position"];
                UICollectionViewCell *libraryCell = [self.libraryVC.collectionView cellForItemAtIndexPath:targetIndexPath];
                CGPoint pointOnRootView = [self.view convertPoint:libraryCell.center fromView:self.libraryVC.collectionView];
                CGPoint pointOnPhotoVCView = [self.photoVC.collectionView convertPoint:pointOnRootView fromView:self.view];
                move.toValue = [NSValue valueWithCGPoint:pointOnPhotoVCView];
                
                CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
                switch (self.libraryType) {
                    case kFaceType:
                        scale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, -2)];
                        break;
                    case kThumbnailType:{
                        CGFloat scaleFactor;
                        if(photoView.image.size.width > photoView.image.size.height){
                            scaleFactor = 144/cell.bounds.size.width;
                        }else
                            scaleFactor = 144/cell.bounds.size.height;
                        scale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleFactor, scaleFactor, 1)];
                        break;
                    }
                }

                CAAnimationGroup *group = [CAAnimationGroup animation];
                group.animations = @[move, scale];
                group.duration = 0.5;
                group.fillMode = kCAFillModeForwards;
                group.removedOnCompletion = NO;

                [layer addAnimation:group forKey:@"scaleback"];
                
                self.actionCenterButton.hidden = NO;
                self.libraryVC.collectionView.hidden = NO;
                [self.libraryVC.collectionView addGestureRecognizer:self.pinchGestureRecognizer];
                [UIView animateWithDuration:0.5 animations:^{
                    self.librarySwitch.alpha = 1.0f;
                    self.libraryVC.collectionView.alpha = 1.0f;
                }];
                
            }
            break;
        }
    }
    return cell;
}


#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentMaxItem = -1;
    switch (self.contentType) {
        case kPortraitType:{
            if (!self.buttonPanel.hidden) {
                self.buttonPanel.hidden = YES;
            }
            
            self.shouldFlyCell = YES;
            self.shouldMoveToOriginal = NO;
            self.shouldMoveToAssemblePosition = NO;
            
            self.portraitIndex = indexPath.item;
            if (!self.tabBarController.tabBar.hidden) {
                self.tabBarController.tabBar.hidden = YES;
            }
            UICollectionViewLayoutAttributes *attr = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
            self.assemblePoint = [self.view convertPoint:attr.center fromView:self.galleryView];

            [UIView animateWithDuration:0.5 animations:^{
                self.librarySwitch.alpha = 1.0f;
                self.galleryView.alpha = 0;
            }];
            
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
            if (!self.buttonPanel.hidden) {
                self.buttonPanel.hidden = YES;
            }
            
            self.shouldScaleAndBack = NO;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            
            CABasicAnimation *move = [CABasicAnimation animationWithKeyPath:@"position"];
            CGPoint point = [self.libraryVC.collectionView convertPoint:self.view.center fromView:self.view];
            move.toValue = [NSValue valueWithCGPoint:point];
            
            CABasicAnimation *zMove = [CABasicAnimation animationWithKeyPath:@"zPosition"];
            zMove.toValue = [NSNumber numberWithFloat:1.0];
            
            CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
            
            CGFloat time = 0.2f;
            CGFloat delay = 0.0f;
            switch (self.libraryType) {
                case kFaceType:{
                    scale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2, 2, -2)];
                    delay = -0.1f;
                    break;
                }
                case kThumbnailType:{
                    CGRect bounds = cell.bounds;
                    CGFloat scaleFactor;
                    
                    UIImageView *photoView = (UIImageView *)[cell viewWithTag:10];
                    if (photoView.image) {
                        //NSLog(@"image exist");
                        CGFloat hight = photoView.image.size.height;
                        CGFloat width = photoView.image.size.width;
                        if (hight >= width) {
                            scaleFactor = kPhotoHeight/bounds.size.height;
                        }else
                            scaleFactor = kPhotoWidth/bounds.size.width;
                    }else{
                        CGFloat scale_x = kPhotoWidth/bounds.size.width;
                        CGFloat scale_y = kPhotoHeight/bounds.size.height;
                        scaleFactor = (scale_x < scale_y)?scale_y:scale_x;
                    }
                    
                    scale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleFactor, scaleFactor, 1)];
                    break;
                }
            }
            
            CAAnimationGroup *group = [CAAnimationGroup animation];
            group.animations = @[move, zMove, scale];
            group.duration = time;
            group.fillMode = kCAFillModeForwards;
            group.removedOnCompletion = NO;
            [cell.layer addAnimation:group forKey:@"scale"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((time + delay) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showPhotoAtIndexPath:indexPath];
            });

            break;
        }
        case kPhotoType:{
            break;
        }
    }
}
- (void)showPhotoAtIndexPath:(NSIndexPath *)indexPath
{
    self.contentType = kPhotoType;
    [UIView animateWithDuration:0.2 animations:^{
        self.librarySwitch.alpha = 0;
        self.libraryVC.collectionView.alpha = 0;;
    }completion:^(BOOL finished){
        UICollectionViewCell *cell = [self.libraryVC.collectionView cellForItemAtIndexPath:indexPath];
        [cell.layer removeAnimationForKey:@"scale"];
        self.libraryVC.collectionView.hidden = YES;
    }];
    //self.actionCenterButton.hidden = YES;
    [self.libraryVC.collectionView removeGestureRecognizer:self.pinchGestureRecognizer];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    self.photoVC= (SDESpecialItemVC *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoVC"];
    LineLayoutWithAnimation *lineLayout = [[LineLayoutWithAnimation alloc] init];
    [self.photoVC.collectionView setCollectionViewLayout:lineLayout];
    self.photoVC.collectionView.frame = self.galleryView.frame;
    self.photoVC.collectionView.dataSource = self;
    self.photoVC.collectionView.delegate = self;
    [self.photoVC.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.photoVC specifyStartIndexPath:indexPath];
    
    [self.photoVC viewWillAppear:NO];
    [self addChildViewController:self.photoVC];
    [self.view addSubview:self.photoVC.collectionView];
    [self.photoVC didMoveToParentViewController:self];
    [self.photoVC.collectionView addGestureRecognizer:self.pinchGestureRecognizer];
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
            switch (self.libraryType) {
                case kFaceType:
                    cellSize = CGSizeMake(144, 144);
                    break;
                case kThumbnailType:
                    cellSize = CGSizeMake(144, 144);
                    break;
            }
            
            break;
        }
        case kPhotoType:{
            cellSize = CGSizeMake(kPhotoWidth, kPhotoHeight);
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

#pragma mark - UITabBarDelegate Method
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    
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
        default:
            break;
    }
    
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecongnizer
{
    /*
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
     */
    
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
                CGPoint relativeAssemblePoint = [self.libraryVC.collectionView convertPoint:self.assemblePoint fromView:self.view];
                [layout relocateVisibleItems:visibleIndexPaths withAssemblePosition:relativeAssemblePoint Scale:gestureRecongnizer.scale];
                [layout invalidateLayout];
                
                //NSLog(@"Scale: %f", gestureRecongnizer.scale);
                //为了能让 gallery不在缩放刚开始就从背景中显露出来，必须结合 hidden 属性， 只有在 scale 下探到0.5之后才在允许从背景中渗透出来
                if (gestureRecongnizer.scale > 0.8f && gestureRecongnizer.scale < 1.0f) {
                    self.galleryView.alpha = (1 - gestureRecongnizer.scale)/2;
                }else if (gestureRecongnizer.scale > 1.0f){
                    self.galleryView.hidden = YES;
                    self.galleryView.alpha = 0;
                }else if (gestureRecongnizer.scale < 0.5f){
                    self.galleryView.hidden = NO;
                    self.galleryView.alpha = (1 - gestureRecongnizer.scale)/2;
                }

                break;
            }
            case kPhotoType:{
                LineLayoutWithAnimation *lineLayout = (LineLayoutWithAnimation *)self.photoVC.collectionView.collectionViewLayout;
                NSArray *visibleIndexPaths = [self.photoVC.collectionView indexPathsForVisibleItems];
                NSIndexPath *indexPath = visibleIndexPaths.firstObject;
                [lineLayout resizeItemAtIndexPath:indexPath withScale:gestureRecongnizer.scale];
                [lineLayout invalidateLayout];
                break;
            }
        }
    }
    
    if (gestureRecongnizer.state == UIGestureRecognizerStateEnded || gestureRecongnizer.state == UIGestureRecognizerStateCancelled ||gestureRecongnizer.state == UIGestureRecognizerStateFailed) {
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
                if (gestureRecongnizer.scale < 0.5f) {
                    NSArray *visibleIndexPaths = [self.photoVC.collectionView indexPathsForVisibleItems];
                    self.shouldScaleAndBack = YES;
                    [self.photoVC.collectionView reloadItemsAtIndexPaths:visibleIndexPaths];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((0.5) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.photoVC.collectionView removeGestureRecognizer:self.pinchGestureRecognizer];
                        [self.photoVC.collectionView removeFromSuperview];
                        [self.photoVC removeFromParentViewController];
                        self.photoVC = nil;
                        self.contentType = kLibraryType;
                        
                        NSArray *indexPaths = [self.libraryVC.collectionView indexPathsForVisibleItems];
                        NSArray *sortedArray = [indexPaths sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"item" ascending:YES]]];
                        NSIndexPath *libraryVCMaxIndexPath = sortedArray.lastObject;
                        NSIndexPath *libraryVCMinIndexPath = sortedArray.firstObject;
                        NSIndexPath *photoVCCurrentIndexPath = visibleIndexPaths.firstObject;
                        //NSLog(@"end at:%ld", (long)photoVCCurrentIndexPath.item);
                        
                        if (photoVCCurrentIndexPath.item > libraryVCMaxIndexPath.item) {
                            if (photoVCCurrentIndexPath.item % (numberOfItemsInPage + 2) == 0 ||
                                photoVCCurrentIndexPath.item % (numberOfItemsInPage + 2) == 5) {
                                [self.libraryVC.collectionView scrollToItemAtIndexPath:photoVCCurrentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                            }else{
                                NSIndexPath *targetIndexPath;
                                NSInteger item = libraryVCMaxIndexPath.item;
                                if (photoVCCurrentIndexPath.item - item > numberOfItemsInPage) {
                                    item = (photoVCCurrentIndexPath.item / numberOfItemsInPage) * numberOfItemsInPage;
                                }
                                NSInteger numberOfItems = [self.libraryVC.collectionView numberOfItemsInSection:0];
                                if (item + 3 <= numberOfItems - 1) {
                                    targetIndexPath = [NSIndexPath indexPathForItem:item + 3 inSection:0];
                                }else
                                    targetIndexPath = [NSIndexPath indexPathForItem:item + 1 inSection:0];
                                
                                [self.libraryVC.collectionView scrollToItemAtIndexPath:targetIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                            }
                        }else if (photoVCCurrentIndexPath.item < libraryVCMinIndexPath.item){
                            if (photoVCCurrentIndexPath.item % (numberOfItemsInPage + 2) == 0 ||
                                photoVCCurrentIndexPath.item % (numberOfItemsInPage + 2) == 5) {
                                [self.libraryVC.collectionView scrollToItemAtIndexPath:photoVCCurrentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                            }else{
                                NSIndexPath *targetIndexPath;
                                NSInteger item = libraryVCMinIndexPath.item;
                                if (item - photoVCCurrentIndexPath.item > numberOfItemsInPage) {
                                    item = (photoVCCurrentIndexPath.item / numberOfItemsInPage) * numberOfItemsInPage + 3;
                                }else
                                    item = libraryVCMinIndexPath.item - 3;
                                targetIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
                                
                                [self.libraryVC.collectionView scrollToItemAtIndexPath:targetIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                            }
                        }
                    });

                }else{
                    LineLayoutWithAnimation *lineLayout = (LineLayoutWithAnimation *)self.photoVC.collectionView.collectionViewLayout;
                    [lineLayout resetPinchedItem];
                }
                break;
            }
                
            default:
                break;
        }
        
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
}

#pragma mark - IBAction Method
- (IBAction)scanPhotoLibrary:(id)sender
{
    DLog(@"Scan Library");
    if ([self.photoFileFilter shouldScanPhotoLibrary]) {
        UIViewController *scanVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ScanRoom"];
        [self.navigationController pushViewController:scanVC animated:YES];
    }
    
}

- (IBAction)editAlbum:(id)sender
{
    DLog(@"Need a little change.");
    DLog(@"Check for deleted photos");
    [self handleDeletedPhotos];
    [self resetFaceRoomScene];
    [self performSegueWithIdentifier:@"enterMontageRoom" sender:self];
}

- (void)resetFaceRoomScene
{
    self.nameTitle.text = @"";
    self.infoTitle.text = @"";
    
    if (self.libraryVC) {
        [self.libraryVC.collectionView removeGestureRecognizer:self.pinchGestureRecognizer];
        [self.libraryVC.collectionView removeFromSuperview];
        [self.libraryVC removeFromParentViewController];
        self.libraryVC = nil;
        self.galleryView.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            self.librarySwitch.alpha = 0;
            self.galleryView.alpha = 1.0f;
        }];
    }
    
    [self.actionCenterButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
    self.contentType = kPortraitType;
}

- (void)handleDeletedPhotos
{
    //NSLog(@"Handle for Delete");
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(defaultQueue, ^{
        NSArray *deletedAssetsURLString = [self.photoFileFilter notexistedAssetsURLString];
        if (deletedAssetsURLString.count > 0) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
            for (NSString *URLString in deletedAssetsURLString) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(isExisted == YES) AND (uniqueURLString like %@)", URLString];
                [fetchRequest setPredicate:predicate];
                NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
                if (result.count == 1) {
                    Photo *deletedPhoto = (Photo *)result.firstObject;
                    deletedPhoto.isExisted = NO;
                    for (Face *faceItem in deletedPhoto.faceset) {
                        faceItem.whetherToDisplay = NO;
                    }
                }
            }
            [self.managedObjectContext save:nil];
        }
        
        NSArray *gobackAssetsURLString = [self.photoFileFilter againStoredAssetsURLString];
        if (gobackAssetsURLString.count > 0) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
            for (NSString *URLString in gobackAssetsURLString) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(isExisted == NO) AND (uniqueURLString like %@)", URLString];
                [fetchRequest setPredicate:predicate];
                NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
                if (result.count == 1) {
                    Photo *gobackPhoto = (Photo *)result.firstObject;
                    gobackPhoto.isExisted = YES;
                    for (Face *faceItem in gobackPhoto.faceset) {
                        faceItem.whetherToDisplay = YES;
                    }
                }
            }
            [self.managedObjectContext save:nil];
        }
        
        [self.photoFileFilter cleanData];
    });

}

- (IBAction)popMenu:(id)sender
{
    if (![self.photoFileFilter shouldScanPhotoLibrary]) {
        self.scanRoomButton.hidden = YES;
    }else
        self.scanRoomButton.hidden = NO;
    if ([[self.photoFileFilter notexistedAssetsURLString] count] > 0) {
        self.MontageRoomButton.highlighted = YES;
    }else
        self.MontageRoomButton.highlighted = NO;
    
    if (self.buttonPanel.hidden) {
        self.buttonPanel.hidden = NO;
        if (!self.buttonPanel.isPopup) {
            [self.buttonPanel popup];
        }
    }else{
        if (self.buttonPanel.isPopup) {
            [self.buttonPanel hide];
        }else
            [self.buttonPanel popup];
    }
    

}

#pragma mark - Update headerView Info
- (void)updateHeaderView
{
    switch (self.contentType) {
        case kPortraitType:
            self.nameTitle.text = @"";
            self.infoTitle.text = @"";
            self.buttonPanel.hidden = YES;
            [self.actionCenterButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
            break;
        case kLibraryType:{
            id<NSFetchedResultsSectionInfo>sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.portraitIndex];
            int avatorCount = (int)[sectionInfo numberOfObjects];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.portraitIndex]];
            
            Person *personItem = faceItem.personOwner;
            if (personItem.name.length == 0) {
                self.nameTitle.text = [NSString stringWithFormat:@"Count：%d", avatorCount];
                self.infoTitle.text = @"";
            }else{
                self.nameTitle.text = [NSString stringWithFormat:@"%@", personItem.name];
                self.infoTitle.text = [NSString stringWithFormat:@"Count: %d", avatorCount];
            }
            
            if (personItem) {
                [self.actionCenterButton setImage:personItem.avatorImage forState:UIControlStateNormal];
            }else
                [self.actionCenterButton setImage:[UIImage imageNamed:@"face.png"] forState:UIControlStateNormal];

            break;
        }
        case kPhotoType:{
            break;
        }
    }
}

- (void)updateHeaderViewAtIndexPath:(NSIndexPath *)indexPath
{
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    Photo *photoItem = faceItem.photoOwner;
    NSMutableString *commentString = [NSMutableString new];
    for (Face *face in photoItem.faceset) {
        if (face.name && face.name.length > 0) {
            [commentString appendString:[NSString stringWithFormat:@"%@ ", faceItem.name]];
        }else
            [commentString appendString:@"* "];
    }
    
    id<NSFetchedResultsSectionInfo>sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.portraitIndex];
    NSUInteger avatorCount = [sectionInfo numberOfObjects];
    self.nameTitle.text = [commentString copy];
    self.infoTitle.text = [NSString stringWithFormat:@"%ld/%lu", (long)indexPath.item + 1, (unsigned long)avatorCount];
}
@end
