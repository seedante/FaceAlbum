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

#import "SDECandidateCell.h"

@interface SDEMontageRoomViewController ()

@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) SDEMRVCDataSource *dataSource;
@property (nonatomic) PhotoScanManager *photoScaner;
@property (nonatomic) ALAssetsLibrary *photoLibrary;
@property (nonatomic) NSMutableArray *changedAlbumGroups;

@property (nonatomic) UIBarButtonItem *selectBarButton;
@property (nonatomic) UIBarButtonItem *DoneBarButton;
@property (nonatomic) UIBarButtonItem *moveBarButton;
@property (nonatomic) UIBarButtonItem *hiddenBarButton;
@property (nonatomic) UIBarButtonItem *addBarButton;

@property (nonatomic) NSMutableSet *selectedFaces;
@property (nonatomic) NSMutableSet *includedSections;
@property (nonatomic) NSMutableSet *triggeredDeletedSections;
@property (nonatomic) NSMutableSet *guardObjectIDs;

@property (nonatomic) UICollectionView  *candidateView;

@end

@implementation SDEMontageRoomViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setRightBarButtonItem:self.selectBarButton];
    
    self.changedAlbumGroups = [NSMutableArray new];
    self.selectedFaces = [[NSMutableSet alloc] init];
    self.includedSections = [[NSMutableSet alloc] init];
    self.triggeredDeletedSections = [NSMutableSet new];
    self.guardObjectIDs = [NSMutableSet new];
    
    self.collectionView.allowsSelection = NO;
    
    self.dataSource = [SDEMRVCDataSource sharedDataSource];
    self.collectionView.dataSource = self.dataSource;
    self.dataSource.collectionView = self.collectionView;
    self.faceFetchedResultsController = self.dataSource.faceFetchedResultsController;
    self.managedObjectContext = self.faceFetchedResultsController.managedObjectContext;
    
    self.photoScaner = [PhotoScanManager sharedPhotoScanManager];
    
    NSError *error;
    if (![self.faceFetchedResultsController performFetch:&error]) {
        NSLog(@"Face Fetch Fail: %@", error);
    }
    
    NSLog(@"FetchedObjects include %lu objects", (unsigned long)[[self.faceFetchedResultsController fetchedObjects] count]);
}

- (void)saveEdit
{
    NSError *error = nil;
    NSManagedObjectContext *moc = self.faceFetchedResultsController.managedObjectContext;
    if (moc != nil) {
        if ([moc hasChanges] && ![moc save:&error]) {
            NSLog(@"Edit Save error %@, %@", error, [error userInfo]);
        }
    }
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

#pragma mark - Fundamental Method of BarButton Action
- (void)enableLeftBarButtonItems
{
    self.hiddenBarButton.enabled = YES;
    self.addBarButton.enabled = YES;
    
    BOOL isFirstSectionZero = YES;
    Face *firstItemInFirstSecion = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    if (firstItemInFirstSecion.section == 0) {
        isFirstSectionZero = YES;
    }else
        isFirstSectionZero = NO;
    
    if (isFirstSectionZero && [self.collectionView numberOfSections] == 1) {
        self.moveBarButton.enabled = NO;
    }else
        self.moveBarButton.enabled = YES;
}

- (void)unenableLeftBarButtonItems
{
    self.hiddenBarButton.enabled = NO;
    self.addBarButton.enabled = NO;
    self.moveBarButton.enabled = NO;
}

- (void)deselectAllSelectedItems
{
    self.collectionView.allowsSelection = NO;
    
    [self performSelector:@selector(enableSelect) withObject:nil afterDelay:0.1];
    
}

- (void)enableSelect
{
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
}

- (void)cleanUsedData
{
    [self.triggeredDeletedSections removeAllObjects];
    [self.guardObjectIDs removeAllObjects];
    [self.selectedFaces removeAllObjects];
    [self.includedSections removeAllObjects];
    
    [self saveEdit];
    [self performSelector:@selector(deselectAllSelectedItems) withObject:nil afterDelay:0.1];
}

- (void)filterSelectedItemSet
{
    NSLog(@"STEP 1: filter selected items.");
    [self.guardObjectIDs removeAllObjects];
    [self.triggeredDeletedSections removeAllObjects];
    
    for (NSNumber *sectionNumber in self.includedSections) {
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"section == %@", sectionNumber];
        NSArray *matchedItems = [self.selectedFaces.allObjects filteredArrayUsingPredicate:sectionPredicate];
        if (matchedItems.count > 0) {
            NSInteger section = [sectionNumber integerValue];
            NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
            if (itemCount == matchedItems.count) {
                NSLog(@"All items at section: %d are choiced. This will trigger detele section.", section+1);
                [self.triggeredDeletedSections addObject:sectionNumber];
                [self.selectedFaces removeObject:[NSIndexPath indexPathForItem:0 inSection:section]];
            }
        }
    }
    [self.includedSections removeAllObjects];
}

- (void)createCopyItemInTargetSection:(NSInteger)targetSection
{
    NSLog(@"STEP 2: create copy items in target section.");
    if (self.triggeredDeletedSections.count > 0) {
        for (NSNumber *sectionNumber in self.triggeredDeletedSections) {
            NSInteger section = sectionNumber.integerValue;
            if (section == targetSection) {
                NSLog(@"Items in section:%d don't need to move.", section);
                [self filterSelectedItemsInSection:targetSection];
            }else{
                Face *copyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
                copyFaceItem.section = targetSection;
                copyFaceItem.whetherToDisplay = YES;
            }
        }
    }else{
        NSIndexPath *anyIndexPath = self.selectedFaces.anyObject;
        if (anyIndexPath.section == targetSection) {
            NSLog(@"Don't move this item");
            [self filterSelectedItemsInSection:targetSection];
        }else{
            Face *singleCopyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:anyIndexPath];
            singleCopyFaceItem.section = targetSection;
            singleCopyFaceItem.whetherToDisplay = YES;
        }
        [self.selectedFaces removeObject:anyIndexPath];
    }
    
    [self performSelector:@selector(moveOtherItemsToSection:) withObject:@(targetSection) afterDelay:0.1];
}

- (void)filterSelectedItemsInSection:(NSInteger)section
{
    NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"section != %@", @(section)];
    [self.selectedFaces filterUsingPredicate:sectionPredicate];
}

- (NSManagedObject *)copyManagedObjectAtIndexPath:(NSIndexPath *)indexPath;
{
    Face *originalFaceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID *objectID = originalFaceItem.objectID;
    [self.guardObjectIDs addObject:objectID];
    Face *copyFaceItem = [Face insertNewObjectInManagedObjectContext:self.managedObjectContext];
    copyFaceItem.avatorImage = originalFaceItem.avatorImage;
    copyFaceItem.pathForBackup = originalFaceItem.pathForBackup;
    copyFaceItem.detectedFaceImage = originalFaceItem.detectedFaceImage;
    copyFaceItem.detectedFaceRect = originalFaceItem.detectedFaceRect;
    copyFaceItem.faceID = originalFaceItem.faceID;
    copyFaceItem.order = originalFaceItem.order;
    copyFaceItem.posterImage = originalFaceItem.posterImage;
    copyFaceItem.tag = originalFaceItem.tag;
    copyFaceItem.isMyStar = originalFaceItem.isMyStar;
    copyFaceItem.personOwner = originalFaceItem.personOwner;
    copyFaceItem.photoOwner = originalFaceItem.photoOwner;
    
    return copyFaceItem;
}

- (void)moveOtherItemsToSection:(NSNumber *)targetSectionNumber
{
    NSLog(@"STEP 3: move left items to target section.");
    if (self.selectedFaces.count > 0) {
        NSInteger targetSection = [targetSectionNumber integerValue];
        for (NSIndexPath *indexPath in self.selectedFaces) {
            Face *selectedFace = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            if (selectedFace.section != targetSection) {
                selectedFace.section = targetSection;
            }
        }
        
        [self.selectedFaces removeAllObjects];
    }else
        NSLog(@"There is no item to be move.");

    [self performSelector:@selector(deleteOriginalItems) withObject:nil afterDelay:0.1];
}

- (void)deleteOriginalItems
{
    NSLog(@"STEP 4: delete original items.");
    if (self.guardObjectIDs.count > 0) {
        for (NSManagedObjectID *objectID in self.guardObjectIDs) {
            Face *originalFace = (Face *)[self.managedObjectContext existingObjectWithID:objectID error:nil];
            [self.faceFetchedResultsController.managedObjectContext deleteObject:originalFace];
        }
        [self.guardObjectIDs removeAllObjects];
    }else
        NSLog(@"There is no item to delete.");
    
    [self performSelector:@selector(cleanUsedData) withObject:nil afterDelay:0.1];
}


#pragma mark - select Method

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
    self.navigationItem.rightBarButtonItem = self.DoneBarButton;
    
    NSArray *leftBarButtonItems = @[self.hiddenBarButton, self.addBarButton, self.moveBarButton];
    self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    
    [self.selectedFaces removeAllObjects];
}

#pragma mark - hidden somebody
- (UIBarButtonItem *)hiddenBarButton
{
    if (_hiddenBarButton) {
        return _hiddenBarButton;
    }
    _hiddenBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(hiddenSelectedFaces)];
    _hiddenBarButton.enabled = NO;
    return _hiddenBarButton;
}

- (void)hiddenSelectedFaces
{
    for (NSIndexPath *indexPath in self.selectedFaces) {
        Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
        face.whetherToDisplay = NO;
    }

    [self cleanUsedData];
    [self unenableLeftBarButtonItems];
}

#pragma mark - add a new person
- (UIBarButtonItem *)addBarButton
{
    if (_addBarButton) {
        return _addBarButton;
    }
    _addBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewPerson)];
    _addBarButton.enabled = NO;
    return _addBarButton;
}

- (void)addNewPerson
{
    NSLog(@"add New Person");
    [self filterSelectedItemSet];
    NSInteger sectionCount = [self.collectionView numberOfSections];
    Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount-1]];
    NSInteger newSection = firstItemInSection.section + 1;
    [self createCopyItemInTargetSection:newSection];
    
    [self performSelector:@selector(unenableLeftBarButtonItems) withObject:nil afterDelay:0.1];
}


#pragma mark - move some faces
- (UIBarButtonItem *)moveBarButton
{
    if (_moveBarButton) {
        return _moveBarButton;
    }
    _moveBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Move To" style:UIBarButtonItemStyleBordered target:self action:@selector(moveSelectedFacesToPerson)];
    _moveBarButton.enabled = NO;
    return _moveBarButton;
}

- (void)moveSelectedFacesToPerson
{
    [self.view addSubview:self.candidateView];
    [self.candidateView reloadData];
    [self unenableLeftBarButtonItems];
    
    [self.collectionView setContentInset:UIEdgeInsetsMake(164.0f, 0.0f, 0.0f, 0.0f)];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
}

- (UICollectionView *)candidateView
{
    if (_candidateView) {
        return _candidateView;
    }
    
    CGRect frame = self.collectionView.frame;
    frame.size.height = 120.0f;
    frame.origin.y = 44.0f;
    UICollectionViewFlowLayout *lineLayout = [[UICollectionViewFlowLayout alloc] init];
    lineLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    lineLayout.itemSize = CGSizeMake(100.0f, 100.0f);
    lineLayout.sectionInset = UIEdgeInsetsMake(10.0f, 25.0f, 10.0f, 25.0f);
    _candidateView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:lineLayout];
    [_candidateView registerClass:[SDECandidateCell class] forCellWithReuseIdentifier:@"candidateCell"];
    _candidateView.dataSource = self;
    _candidateView.delegate = self;
    return _candidateView;
}

#pragma mark - done and save
- (UIBarButtonItem *)DoneBarButton
{
    if (_DoneBarButton) {
        return _DoneBarButton;
    }
    _DoneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEdit)];
    return _DoneBarButton;
}

- (void)doneEdit
{
    if (self.selectedFaces.count > 0) {
        for (NSIndexPath *indexPath in self.selectedFaces) {
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            cell.transform = CGAffineTransformMakeScale(1.0, 1.0);
            cell.layer.borderWidth = 0.0f;
        }
    }
    
    if ([self.view.subviews containsObject:self.candidateView]) {
        [self.candidateView removeFromSuperview];
        [self.collectionView setContentInset:UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f)];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }

    self.navigationItem.title = @"Montage Room";
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = self.selectBarButton;
    
    [self unenableLeftBarButtonItems];
    self.collectionView.allowsSelection = NO;
    [self.selectedFaces removeAllObjects];
    [self.includedSections removeAllObjects];
    [self.triggeredDeletedSections removeAllObjects];
    [self.guardObjectIDs removeAllObjects];
    
    [self saveEdit];

}

#pragma mark - check photo change
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
            [self.changedAlbumGroups addObject:groupURL];
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
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *shouldStop){
                NSString *assetURLString = [(NSURL *)[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
                if (![URLArray containsObject:assetURLString]) {
                    NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                    NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
                    NSLog(@"Album Group: %@ change.", groupName);
                    [self.changedAlbumGroups addObject:groupURL];
                    *shouldStop = YES;
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

#pragma mark - Select Candidate UICollectionView Data Source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger sectionNumber = [self.collectionView numberOfSections];
    NSLog(@"Candidate Number: %ld", (long)sectionNumber);
    return sectionNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDECandidateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"candidateCell" forIndexPath:indexPath];
    Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
    if (firstItemInSection.section == 0) {
        [cell setCellImage:[UIImage imageNamed:@"Smartisan.png"]];
    }else
        [cell setCellImage:firstItemInSection.avatorImage];
    return cell;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.collectionView]) {
        [self processCellAtIndexPath:indexPath type:@"Select"];
        if (![self.includedSections containsObject:[NSNumber numberWithInteger:indexPath.section]]) {
            [self.includedSections addObject:@(indexPath.section)];
        }
    }else{
        Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
        int newSection = firstItemInSection.section;
        
        [self filterSelectedItemSet];
        [self createCopyItemInTargetSection:newSection];
        
        [self unenableLeftBarButtonItems];
        [self.candidateView removeFromSuperview];
        [self.collectionView setContentInset:UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f)];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self processCellAtIndexPath:indexPath type:@"Deselect"];
}

- (void)processCellAtIndexPath:(NSIndexPath *)indexPath type:(NSString *)type
{
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if ([type isEqual:@"Select"]) {
        NSLog(@"Select Cell: %ld, %ld", (long)indexPath.section, (long)indexPath.item);
        [self.selectedFaces addObject:indexPath];
        [self.includedSections addObject:[NSNumber numberWithInteger:indexPath.section]];
        [self enableLeftBarButtonItems];

        //selectedCell.layer.backgroundColor = [[UIColor blueColor] CGColor];
        cell.layer.borderColor = [[UIColor greenColor] CGColor];
        cell.layer.borderWidth = 3.0f;
        cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }
    
    if ([type isEqual:@"Deselect"]) {
        NSLog(@"Deselect Cell: %ld, %ld", (long)indexPath.section, (long)indexPath.item);
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
