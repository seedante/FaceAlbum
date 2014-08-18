//
//  SDMontageRoomViewController.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEMontageRoomViewController.h"
#import "SDEMRVCDataSource.h"
#import "PhotoScanManager.h"
#import "Store.h"
#import "Person.h"
#import "Face.h"

@interface SDEMontageRoomViewController ()
{
    NSMutableSet *changedAlbumGroups;
}

@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) SDEMRVCDataSource *dataSource;
@property (nonatomic) PhotoScanManager *photoScaner;
@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) UIBarButtonItem *selectBarButton;
@property (nonatomic) UIBarButtonItem *cancelBarButton;
@property (nonatomic) UIBarButtonItem *moveBarButton;
@property (nonatomic) UIBarButtonItem *hiddenBarButton;
@property (nonatomic) UIBarButtonItem *addBarButton;
@property (nonatomic) NSMutableSet *selectedFaces;

@end

@implementation SDEMontageRoomViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setRightBarButtonItem:self.selectBarButton];

    changedAlbumGroups = [[NSMutableSet alloc] init];
    self.selectedFaces = [[NSMutableSet alloc] init];
    self.collectionView.allowsSelection = NO;
    
    self.dataSource = [SDEMRVCDataSource sharedDataSource];
    self.collectionView.dataSource = self.dataSource;
    self.dataSource.collectionView = self.collectionView;
    self.faceFetchedResultsController = self.dataSource.faceFetchedResultsController;
    
    self.photoScaner = [PhotoScanManager sharedPhotoScanManager];
    
    NSError *error;
    if (![self.faceFetchedResultsController performFetch:&error]) {
        NSLog(@"Face Fetch Fail: %@", error);
    }
    
    NSLog(@"FetchedObjects include %d objects", [[self.faceFetchedResultsController fetchedObjects] count]);
}


- (void)scanPhotoLibrary:(id)sender
{
    if ([self.dataSource numberOfSectionsInCollectionView:self.collectionView] == 0) {
        self.photoScaner.numberOfItemsInFirstSection = 0;
    }else
        self.photoScaner.numberOfItemsInFirstSection = [self.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    //[self.photoScaner scanPhotoLibrary];
}

#pragma mark <UICollectionViewDelegateFlowLayout>
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100.0, 100.0);
}

#pragma mark - LXReorderableCollectionViewDelegateFlowLayout
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Will Begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Dragging");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Will End Drag.");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Drag End.");
}

#pragma mark - BarButton Method
- (UIBarButtonItem *)selectBarButton
{
    if (_selectBarButton) {
        return _selectBarButton;
    }
    _selectBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStyleBordered target:self action:@selector(selectFaces)];
    return _selectBarButton;
}

- (UIBarButtonItem *)hiddenBarButton
{
    if (_hiddenBarButton) {
        return _hiddenBarButton;
    }
    _hiddenBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelectedFaces)];
    _hiddenBarButton.enabled = NO;
    return _hiddenBarButton;
}

- (UIBarButtonItem *)addBarButton
{
    if (_addBarButton) {
        return _addBarButton;
    }
    _addBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewPerson)];
    _addBarButton.enabled = NO;
    return _addBarButton;
}

- (UIBarButtonItem *)moveBarButton
{
    if (_moveBarButton) {
        return _moveBarButton;
    }
    _moveBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Move To" style:UIBarButtonItemStyleBordered target:self action:@selector(moveSelectedFacesToAnotherPerson)];
    _moveBarButton.enabled = NO;
    return _moveBarButton;
}

- (void)selectFaces
{
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.navigationItem.title = @"Select Faces";
    self.navigationItem.rightBarButtonItem = self.cancelBarButton;

    NSArray *leftBarButtonItems = @[self.hiddenBarButton, self.addBarButton, self.moveBarButton];
    self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    
    [self.selectedFaces removeAllObjects];
}

- (void)enableLeftBarButtonItems
{
    self.hiddenBarButton.enabled = YES;
    self.addBarButton.enabled = YES;
    self.moveBarButton.enabled = YES;
}

- (void)unenableLeftBarButtonItems
{
    self.hiddenBarButton.enabled = NO;
    self.addBarButton.enabled = NO;
    self.moveBarButton.enabled = NO;
}

- (UIBarButtonItem *)cancelBarButton
{
    if (_cancelBarButton) {
        return _cancelBarButton;
    }
    _cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelect)];
    return _cancelBarButton;
}

- (void)cancelSelect
{
    if (self.selectedFaces.count > 0) {
        for (NSIndexPath *indexPath in self.selectedFaces) {
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            cell.transform = CGAffineTransformMakeScale(1.0, 1.0);
            cell.layer.borderWidth = 0.0f;
        }
    }
    
    [self.selectedFaces removeAllObjects];
    [self unenableLeftBarButtonItems];
    self.collectionView.allowsSelection = NO;
    self.collectionView.allowsMultipleSelection = NO;
    
    self.navigationItem.title = @"Montage Room";
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = self.selectBarButton;
}


- (void)addNewPerson
{
    NSLog(@"add New Person");
    //Person *newPerson = [Person insertNewObjectInManagedObjectContext:self.faceFetchedResultsController.managedObjectContext];

    NSUInteger sectionForNow = [[self.faceFetchedResultsController sections] count];
    Face *tmporaryFaceUnit = [Face insertNewObjectInManagedObjectContext:self.faceFetchedResultsController.managedObjectContext];
    tmporaryFaceUnit.section = sectionForNow;
    Face *SentryFace = [Face insertNewObjectInManagedObjectContext:self.faceFetchedResultsController.managedObjectContext];
    SentryFace.whetherToDisplay = YES;
    SentryFace.avatorImage = [UIImage imageNamed:@"avator@weibo.jpg"];
    SentryFace.section = sectionForNow;
    SentryFace.order = 1000.0f;
    //SentryFace.personOwner = newPerson;
    
    /*
    for (NSIndexPath *indexPath in self.selectedFaces) {
        Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
        face.section = sectionForNow;
        face.order = (double)indexPath.item;
        [newPerson addOwnedFacesObject:face];
    }
    UIImage *profileAvatorImage = [[self.faceFetchedResultsController objectAtIndexPath:(NSIndexPath *)self.selectedFaces.firstObject ] avatorImage];
    [newPerson setAvatorImage:profileAvatorImage];
     */
}

- (void)moveSelectedFacesToAnotherPerson
{
    NSLog(@"Check selectedFaces: %@", self.selectedFaces);
    [self.collectionView reloadData];
}

- (void)deleteSelectedFaces
{
    for (NSIndexPath *indexPath in self.selectedFaces) {
        Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
        face.whetherToDisplay = NO;
        //[self.faceFetchedResultsController.managedObjectContext deleteObject:face];
    }
    [self.selectedFaces removeAllObjects];
    [self unenableLeftBarButtonItems];
}

- (void)hiddenSelectedFaces
{
    
}


- (void)checkPhotoLibraryChange
{
    NSLog(@"Check PhotoLibrary change.");
    NSFetchRequest *albumFetchQuest = [[NSFetchRequest alloc] initWithEntityName:@"AlbumGroup"];
    [albumFetchQuest setResultType:NSDictionaryResultType];
    NSEntityDescription *AlbumGroupDescription = [NSEntityDescription entityForName:@"AlbumGroup" inManagedObjectContext:self.faceFetchedResultsController.managedObjectContext];
    NSPropertyDescription *persistentIDDescription = [[AlbumGroupDescription propertiesByName] objectForKey:@"persistentID"];
    NSPropertyDescription *photoCountDescription = [[AlbumGroupDescription propertiesByName] objectForKey:@"photoCount"];
    [albumFetchQuest setPropertiesToFetch:@[persistentIDDescription, photoCountDescription]];
    NSArray *queryResult = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:albumFetchQuest error:nil];
    NSMutableDictionary *albumGroupInfo = [NSMutableDictionary new];
    
    for (NSDictionary *result in queryResult) {
        [albumGroupInfo setObject:result[@"photoCount"] forKey:result[@"persistentID"]];
    }
    
    //Now, just check if there is a different photo and tell the app the photo library is changed, just scan.
    ALAssetsLibraryGroupsEnumerationResultsBlock groupBlock = ^(ALAssetsGroup *group, BOOL *stop){
        NSInteger currentCount = [group numberOfAssets];
        NSString *persistentIDString = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
        if ([albumGroupInfo valueForKey:persistentIDString] == nil || (NSInteger)albumGroupInfo[persistentIDString] != currentCount) {
            NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
            NSLog(@"Album Group: %@ change.", groupName);
            [changedAlbumGroups addObject:groupURL];
            *stop = YES;
            return;
        }
        
        NSFetchRequest *assetFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
        [assetFetchRequest setResultType:NSDictionaryResultType];
        
        NSSortDescriptor *URLStringDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"uniqueURLString" ascending:YES];
        [assetFetchRequest setPropertiesToFetch:@[URLStringDescriptor]];
        NSArray *array = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:assetFetchRequest error:nil];
        NSArray *URLArray = [array valueForKeyPath:@"allValues.firstObject"];
        if (URLArray != nil && URLArray.count > 0) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
                NSString *assetURLString = [(NSURL *)[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
                if (![URLArray containsObject:assetURLString]) {
                    NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                    NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
                    NSLog(@"Album Group: %@ change.", groupName);
                    [changedAlbumGroups addObject:groupURL];
                    *stop = YES;
                }
            }];
        }
        
        /*
         __block NSFetchRequest *assetFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
         [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
         NSString *URLString = [(NSURL *)[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueURLString == %@", URLString];
         [assetFetchRequest setPredicate:predicate];
         NSArray *array = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:assetFetchRequest error:nil];
         if (array != nil && array.count > 0) {
         ;
         }else{
         *stop = YES;
         NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
         NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
         NSLog(@"Album Group:%@ Change.", groupName);
         [changedAlbumGroups addObject:groupURL];
         return;
         }
         }];
         */
    };
    
    NSUInteger groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupTypes usingBlock:groupBlock failureBlock:nil];
}

#pragma mark - UICollectionView Delegate Method
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self processCellAtIndexPath:indexPath type:@"Select"];
    //selectedCell.alpha = 0.9f;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self processCellAtIndexPath:indexPath type:@"Deselect"];
}

- (void)processCellAtIndexPath:(NSIndexPath *)indexPath type:(NSString *)type
{
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if ([type isEqual:@"Select"]) {
        NSLog(@"Select Cell: %d, %d", indexPath.section, indexPath.item);
        [self.selectedFaces addObject:indexPath];
        [self enableLeftBarButtonItems];

        //selectedCell.layer.backgroundColor = [[UIColor blueColor] CGColor];
        cell.layer.borderColor = [[UIColor greenColor] CGColor];
        cell.layer.borderWidth = 3.0f;
        cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }
    
    if ([type isEqual:@"Deselect"]) {
        NSLog(@"Deselect Cell: %d, %d", indexPath.section, indexPath.item);
        cell.layer.borderColor = [[UIColor blueColor] CGColor];
        cell.layer.borderWidth = 3.0f;
        cell.transform = CGAffineTransformMakeScale(1.0, 1.0);
        
        [self.selectedFaces removeObject:indexPath];
        if (self.selectedFaces.count == 0) {
            [self unenableLeftBarButtonItems];
        }
    }
}



@end
