//
//  SDPersonAlbumViewController.m
//  FaceAlbum
//
//  Created by seedante on 14-7-29.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEPersonGalleryViewController.h"
#import "SDEPAVCDataSource.h"
#import "SDEPortraitCell.h"
#import "SDEPortraitLayout.h"
#import "SDEHorizontalGridLayout.h"
#import "Store.h"
#import "Face.h"
#import "Person.h"

typedef enum: NSUInteger{
    PortraitLayout,
    HorizontalGridLayout
} LayoutType;


#define ItemCountPerPageAtHorizontalMode 20
#define ItemCountPerPageDoubleValue 20.0

@interface SDEPersonGalleryViewController ()

@property (nonatomic) LayoutType currentLayout;
@property (nonatomic) NSInteger currentPortraitIndex;
@property (nonatomic, weak) SDEHorizontalGridLayout *layout;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSFetchedResultsController *personFetchedResultsController;

@end

@implementation SDEPersonGalleryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.navigationItem.hidesBackButton = YES;
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
    
    self.currentPortraitIndex = 0;
    self.currentLayout = PortraitLayout;
    //self.collectionView.contentOffset = CGPointMake(5, 5);
    //self.collectionView.collectionViewLayout = [[SDEHorizontalGridLayout alloc] init];
    //self.layout = (SDEHorizontalGridLayout *)self.collectionView.collectionViewLayout;
    //self.collectionView.pagingEnabled = YES;
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

#pragma mark - UICollectionView Data Source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger section = 1;
    
    if (self.currentLayout == HorizontalGridLayout) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
        //NSUInteger itemCount = [sectionInfo numberOfObjects];
        section = ceil([sectionInfo numberOfObjects]/ItemCountPerPageDoubleValue);
        //section = 4;
        //NSLog(@"There are %d person.", section);
    }else
        NSLog(@"I have only one Gallery.");
    
    return section;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger itemNumber;
    if (self.currentLayout == PortraitLayout) {
        NSLog(@"There are %lu person.", (unsigned long)[[self.faceFetchedResultsController sections] count]);
        itemNumber = [[self.faceFetchedResultsController sections] count];
    }else{
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.currentPortraitIndex];
        NSUInteger avatorCount = [sectionInfo numberOfObjects];
        if (avatorCount - section * ItemCountPerPageAtHorizontalMode >= ItemCountPerPageAtHorizontalMode) {
            itemNumber = ItemCountPerPageAtHorizontalMode;
        }else
            itemNumber = avatorCount - section * ItemCountPerPageAtHorizontalMode;
        //itemNumber = [sectionInfo numberOfObjects];
        NSLog(@"Person No.%d has %d avators.", self.currentPortraitIndex, itemNumber);
    }

    return itemNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //SDEPortraitCell *portraitCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PortraitCell" forIndexPath:indexPath];
    SDEPortraitCell *cell;
    switch (self.currentLayout) {
        case PortraitLayout:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PortraitCell" forIndexPath:indexPath];
            Face *firstFaceInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
            [cell setPortrait:firstFaceInSection.posterImage];
            break;
        }
        case HorizontalGridLayout:{
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AvatorCell" forIndexPath:indexPath];
            NSInteger itemIndexBase = indexPath.section * ItemCountPerPageAtHorizontalMode;
            NSIndexPath *faceIndexPath = [NSIndexPath indexPathForItem:(indexPath.item + itemIndexBase) inSection:self.currentPortraitIndex];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:faceIndexPath];
            [cell setPortrait:faceItem.avatorImage];
            break;
        }
        default:
            NSLog(@"Impossible!!!");
            break;
    }
    
    return cell;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //[self performSelector:@selector(transformLayout) withObject:nil afterDelay:0.1];
    if (self.currentLayout == PortraitLayout) {
        self.currentPortraitIndex = indexPath.item;
    }
    
    switch (self.currentLayout) {
        case PortraitLayout:
            self.currentLayout = HorizontalGridLayout;
            self.collectionView.pagingEnabled = YES;
            break;
        case HorizontalGridLayout:
            self.currentLayout = PortraitLayout;
            self.collectionView.pagingEnabled = NO;
            break;
        default:
            NSLog(@"SHIT.");
            break;
    }
    

    //[self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView reloadData];
    switch (self.currentLayout) {
        case PortraitLayout:
            NSLog(@"Show Mode: Portrait Mode");
            [self performSelector:@selector(scrollViewToBefore) withObject:nil afterDelay:0.0];
            break;
        case HorizontalGridLayout:
            NSLog(@"Show Mode: Horizontal Mode");
            break;
    }
}

- (void)scrollViewToBefore
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentPortraitIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize itemSize = CGSizeZero;
    switch (self.currentLayout) {
        case PortraitLayout:
            itemSize.height = 300.0;
            itemSize.width = 300.0;
            break;
        case HorizontalGridLayout:
            itemSize.height = 150.0;
            itemSize.width = 150.0;
            break;
        default:
            NSLog(@"No More Item Size Option.");
            break;
    }
    self.layout.itemSize = itemSize;
    return itemSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets edgeInsets;
    switch (self.currentLayout) {
        case PortraitLayout:{
            CGRect frame = [[UIScreen mainScreen] bounds];
            edgeInsets = UIEdgeInsetsMake(200, frame.size.width/2.0, 200, frame.size.width/2.0);
            break;
        }
        case HorizontalGridLayout:{
            edgeInsets = UIEdgeInsetsMake(94.0, 50, 44.0, 50);
            break;
        }
    }
    return edgeInsets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat minimumSpace;
    switch (self.currentLayout) {
        case PortraitLayout:
            minimumSpace = 50.0;
            break;
        case HorizontalGridLayout:
            minimumSpace = 10.0;
            break;
    }
    
    return minimumSpace;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    CGFloat minimumSpace;
    switch (self.currentLayout) {
        case PortraitLayout:
            minimumSpace = 50.0;
            break;
        case HorizontalGridLayout:
            minimumSpace = 43.5;
            break;
    }
    return minimumSpace;
}

@end