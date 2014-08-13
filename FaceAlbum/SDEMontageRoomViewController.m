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
@property (nonatomic) NSMutableArray *selectedFaces;

@end

@implementation SDEMontageRoomViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    changedAlbumGroups = [[NSMutableSet alloc] init];
    self.selectedFaces = [[NSMutableArray alloc] init];
    
    self.dataSource = [SDEMRVCDataSource sharedDataSource];
    self.collectionView.dataSource = self.dataSource;
    self.dataSource.collectionView = self.collectionView;
    
    self.photoScaner = [PhotoScanManager sharedPhotoScanManager];
    
    self.faceFetchedResultsController = self.dataSource.faceFetchedResultsController;
    [self.navigationItem setRightBarButtonItem:self.selectBarButton];
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

- (void)selectFaces
{
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.navigationItem.title = @"Select Faces";
    self.navigationItem.rightBarButtonItem = self.cancelBarButton;
    
    UIBarButtonItem *deleteBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelectedFaces)];
    deleteBarButton.enabled = NO;
    UIBarButtonItem *addPersonBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewPerson)];
    addPersonBarButton.enabled = NO;
    UIBarButtonItem *moveBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Move To" style:UIBarButtonItemStyleBordered target:self action:@selector(moveSelectedFacesToAnotherPerson)];
    moveBarButton.enabled = NO;
    NSArray *leftBarButtonItems = @[deleteBarButton, addPersonBarButton, moveBarButton];
    self.navigationItem.leftBarButtonItems = leftBarButtonItems;
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
    self.navigationItem.title = @"Montage Room";
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = self.selectBarButton;
    
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    if (selectedItems.count > 0) {
        for (NSIndexPath *indexPath in selectedItems) {
            UICollectionViewCell *selectedCell = [self.collectionView cellForItemAtIndexPath:indexPath];
            selectedCell.layer.borderWidth = 0.0f;
            selectedCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }
    }
    self.collectionView.allowsSelection = NO;
    self.collectionView.allowsMultipleSelection = NO;
}


- (void)addNewPerson
{
    
}

- (void)moveSelectedFacesToAnotherPerson
{
    
}

- (void)deleteSelectedFaces
{
    
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
    UICollectionViewCell *selectedCell = [collectionView cellForItemAtIndexPath:indexPath];
    //
    //selectedCell.layer.backgroundColor = [[UIColor blueColor] CGColor];
    selectedCell.layer.borderWidth = 3.0f;
    selectedCell.layer.borderColor = [[UIColor greenColor] CGColor];
    
    selectedCell.transform = CGAffineTransformMakeScale(1.2, 1.2);
    //selectedCell.alpha = 0.9f;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *selectedCell = [collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.layer.borderWidth = 0.0f;
    selectedCell.transform = CGAffineTransformMakeScale(1.0, 1.0);
}

@end
