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

typedef enum {
    MontageEditTypeAdd,
    MontageEditTypeMove,
} MontageEditType;

@interface SDEMontageRoomViewController ()

@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) SDEMRVCDataSource *dataSource;

@property (nonatomic) UIBarButtonItem *selectBarButton;
@property (nonatomic) UIBarButtonItem *DoneBarButton;
@property (nonatomic) UIBarButtonItem *showGalleryBarButton;
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
    
    [self.navigationItem setLeftBarButtonItem:self.selectBarButton];
    [self.navigationItem setRightBarButtonItem:self.showGalleryBarButton];
    
    self.selectedFaces = [[NSMutableSet alloc] init];
    self.includedSections = [[NSMutableSet alloc] init];
    self.triggeredDeletedSections = [NSMutableSet new];
    self.guardObjectIDs = [NSMutableSet new];
    
    [self registerAsObserver];
    self.collectionView.allowsSelection = NO;
    
    self.dataSource = [SDEMRVCDataSource sharedDataSource];
    self.collectionView.dataSource = self.dataSource;
    self.dataSource.collectionView = self.collectionView;
    self.faceFetchedResultsController = self.dataSource.faceFetchedResultsController;
    self.managedObjectContext = self.faceFetchedResultsController.managedObjectContext;
    
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

#pragma mark - KVC Complaint for @property selectedFaces
- (void)addSelectedFaces:(NSSet *)objects
{
    [self.selectedFaces unionSet:objects];
}

- (void)removeSelectedFaces:(NSSet *)objects
{
    [self.selectedFaces minusSet:objects];
}

#pragma mark - KVO Notification and Response
- (void)registerAsObserver
{
    [self addObserver:self forKeyPath:@"selectedFaces" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedFaces"]) {
        [self updateTitle];
    }
}

- (void)updateTitle
{
    NSString *newTitle;
    if (self.selectedFaces.count > 1) {
        newTitle = [NSString stringWithFormat:@"select %lu faces", (unsigned long)self.selectedFaces.count];
    }else
        newTitle = [NSString stringWithFormat:@"select %d face", self.selectedFaces.count];
    
    self.navigationItem.title = newTitle;
}

#pragma mark <UICollectionViewDelegateFlowLayout>
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100.0, 100.0);
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

- (void)cleanUsedData
{
    [self.triggeredDeletedSections removeAllObjects];
    [self.guardObjectIDs removeAllObjects];
    [self removeSelectedFaces:[self.selectedFaces copy]];
    [self.includedSections removeAllObjects];
    
    [self saveEdit];
    [self performSelector:@selector(deselectAllSelectedItems) withObject:nil afterDelay:0.1];
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

- (void)filterSelectedItemSetWithTargetViewSection:(NSInteger)targetViewSection
{
    NSLog(@"STEP 1: filter selected items.");
    [self.guardObjectIDs removeAllObjects];
    [self.triggeredDeletedSections removeAllObjects];
    
    //remove bordercolor effect.
    for (NSIndexPath *indexPath in self.selectedFaces) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        cell.layer.borderWidth = 0.0f;
        cell.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }
    
    NSPredicate *targetViewSectionPredicate = [NSPredicate predicateWithFormat:@"section != %@", @(targetViewSection)];
    [self.selectedFaces filterUsingPredicate:targetViewSectionPredicate];
    [self.includedSections removeObject:@(targetViewSection)];
    
    //if selected items include a whole section's items, handle it.
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

- (void)manageSelectedItemsWithTargetDataSection:(NSInteger)targetDataSection
{
    NSLog(@"STEP 2: create copy items in target section.");
    if (self.triggeredDeletedSections.count > 0) {
        for (NSNumber *sectionNumber in self.triggeredDeletedSections) {
            NSInteger section = sectionNumber.integerValue;
            if (section == targetDataSection) {
                NSLog(@"It's impossible!!!");
            }else{
                Face *copyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
                copyFaceItem.section = targetDataSection;
                copyFaceItem.whetherToDisplay = YES;
            }
        }
    }else{
        if (self.selectedFaces.count > 0) {
            NSIndexPath *anyIndexPath = self.selectedFaces.anyObject;
            NSLog(@"Index: %@", anyIndexPath);
            Face *anyFace = [self.faceFetchedResultsController objectAtIndexPath:anyIndexPath];
            if (anyFace.section == targetDataSection) {
                NSLog(@"Something is wrong, indexpath: %@ should be filterd at previous step.", anyIndexPath);
                //[self filterSelectedItemsInSection:targetDataSection];
            }else{
                Face *singleCopyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:anyIndexPath];
                singleCopyFaceItem.section = targetDataSection;
                singleCopyFaceItem.whetherToDisplay = YES;
            }
            [self.selectedFaces removeObject:anyIndexPath];
        }
    }
    
    [self performSelector:@selector(moveOtherItemsToSection:) withObject:@(targetDataSection) afterDelay:0.1];
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
    if (self.selectedFaces.count > 0) {
        NSLog(@"STEP 3: move left items to target section.");
        NSInteger targetSection = [targetSectionNumber integerValue];
        for (NSIndexPath *indexPath in self.selectedFaces) {
            Face *selectedFace = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            if (selectedFace.section != targetSection) {
                selectedFace.section = targetSection;
            }
        }
        [self.selectedFaces removeAllObjects];
    }else
        NSLog(@"There is no item need to move.");

    [self performSelector:@selector(deleteOriginalItems) withObject:nil afterDelay:0.1];
}

- (void)deleteOriginalItems
{
    if (self.guardObjectIDs.count > 0) {
        NSLog(@"STEP 4: delete original items.");
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
    self.navigationItem.title = @"Select 0 Face";
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
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount-1]];
    NSInteger newSection = firstItemInSection.section + 1;
    [self filterSelectedItemSetWithTargetViewSection:sectionCount];
    [self manageSelectedItemsWithTargetDataSection:newSection];
    
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
    self.navigationItem.leftBarButtonItem = self.selectBarButton;
    self.navigationItem.rightBarButtonItem = self.showGalleryBarButton;
    
    [self unenableLeftBarButtonItems];
    self.collectionView.allowsSelection = NO;
    [self.selectedFaces removeAllObjects];
    [self.includedSections removeAllObjects];
    [self.triggeredDeletedSections removeAllObjects];
    [self.guardObjectIDs removeAllObjects];
    
    [self saveEdit];
}

#pragma mark - go to Gallery Scene
- (UIBarButtonItem *)showGalleryBarButton
{
    if (_showGalleryBarButton) {
        return _showGalleryBarButton;
    }
    _showGalleryBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(jumpToGalleryScene)];
    return _showGalleryBarButton;
}

- (void)jumpToGalleryScene
{
    //[self performSegueWithIdentifier:@"enterGallery" sender:self];
    [self performSegueWithIdentifier:@"PageGallery" sender:self];
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
        int targetSection = firstItemInSection.section;
        
        [self filterSelectedItemSetWithTargetViewSection:indexPath.item];
        [self manageSelectedItemsWithTargetDataSection:targetSection];
        
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
        [self addSelectedFaces:[NSSet setWithObject:indexPath]];
        
        [self enableLeftBarButtonItems];
        cell.layer.borderColor = [[UIColor greenColor] CGColor];
        cell.layer.borderWidth = 3.0f;
        cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }
    
    if ([type isEqual:@"Deselect"]) {
        NSLog(@"Deselect Cell: %ld, %ld", (long)indexPath.section, (long)indexPath.item);
        cell.layer.borderWidth = 0.0f;
        cell.transform = CGAffineTransformMakeScale(1.0, 1.0);
        //use KVO
        [self removeSelectedFaces:[NSSet setWithObject:indexPath]];
        
        if (self.selectedFaces.count == 0) {
            [self unenableLeftBarButtonItems];
        }
    }
}

#pragma mark - show the edit menu
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return YES;
}

@end
