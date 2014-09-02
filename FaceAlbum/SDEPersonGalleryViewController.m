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
    ProtraitLayout,
    HorizontalGridLayout
} LayoutType;

@interface SDEPersonGalleryViewController ()

@property (nonatomic) LayoutType currentLayout;
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
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    self.currentLayout = ProtraitLayout;
    self.collectionView.collectionViewLayout = [[SDEPortraitLayout alloc] init];
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
        section = [[self.faceFetchedResultsController sections] count];
    }
    return section;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger itemNumber;
    if (self.currentLayout == ProtraitLayout) {
        NSLog(@"There are %lu person.", (unsigned long)[[self.faceFetchedResultsController sections] count]);
        itemNumber = [[self.faceFetchedResultsController sections] count];
    }else{
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:section];
        itemNumber = [sectionInfo numberOfObjects];
        NSLog(@"Person No.%d has %d avators.", section, itemNumber);
    }
    
    return itemNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDEPortraitCell *portraitCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PortraitCell" forIndexPath:indexPath];
    switch (self.currentLayout) {
        case ProtraitLayout:{
            Face *firstFaceInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
            [portraitCell setProtrait:firstFaceInSection.posterImage];
            break;
        }
        case HorizontalGridLayout:{
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            [portraitCell setProtrait:faceItem.avatorImage];
            break;
        }
        default:
            NSLog(@"Impossible!!!");
            break;
    }
    
    return portraitCell;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentLayout == ProtraitLayout) {
        self.currentLayout = HorizontalGridLayout;
        [self.collectionView setCollectionViewLayout:[[SDEHorizontalGridLayout alloc] init] animated:YES];
    }else if (self.currentLayout == HorizontalGridLayout){
        self.currentLayout = ProtraitLayout;
        [self.collectionView setCollectionViewLayout:[[SDEPortraitLayout alloc] init] animated:YES];
    }else
        NSLog(@"No More Options.");
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize itemSize = CGSizeZero;
    switch (self.currentLayout) {
        case ProtraitLayout:
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
    
    return itemSize;
}

@end