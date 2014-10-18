//
//  SDMontageRoomViewController.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEMontageRoomViewController.h"
#import "SDEMRVCDataSource.h"
#import "SDEPersonProfileHeaderView.h"
#import "PhotoScanManager.h"
#import "Store.h"
#import "Person.h"
#import "Face.h"
#import "Reachability.h"
#import "FaceppAPI.h"
#import "APIKey+APISecret.h"

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

@property (nonatomic) UITextField *activedField;
@property (nonatomic) UIButton *goBackUpButton;
@property (nonatomic) NSString *oldContent;

@property (nonatomic)FaceppDetection *onlineDetector;
@property (nonatomic) BOOL onLine;

@end

@implementation SDEMontageRoomViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.goBackUpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.view addSubview:self.goBackUpButton];
    [self.goBackUpButton setTitle:@"UP" forState:UIControlStateNormal];
    [self.goBackUpButton sizeToFit];
    self.goBackUpButton.center = CGPointMake(0, -50);
    [self.goBackUpButton addTarget:self action:@selector(goBackToTop) forControlEvents:UIControlEventTouchUpInside];
    
    [self.navigationItem setLeftBarButtonItem:self.selectBarButton];
    [self.navigationItem setRightBarButtonItem:self.showGalleryBarButton];
    [self registerForKeyboardNotifications];
    
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
    
    NSError *error;
    if (![self.faceFetchedResultsController performFetch:&error]) {
        NSLog(@"Face Fetch Fail: %@", error);
    }

    NSLog(@"FetchedObjects include %lu objects", (unsigned long)[[self.faceFetchedResultsController fetchedObjects] count]);
}

- (void)autoGroupAvator
{
    [[[UIAlertView alloc] initWithTitle:@"AutoGroup" message:@"It's fake" delegate:self cancelButtonTitle:@"Hehe" otherButtonTitles:nil] show];
}

-(void)goBackToTop
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    self.goBackUpButton.center = CGPointMake(-100, -100);
}

- (void)checkFacelessMan
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Face"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"section == 0"];
    [fetchRequest setPredicate:predicate];
    
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects && fetchedObjects.count > 0) {
        UIButton *groupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [groupButton setTitle:@"AutoGroup" forState:UIControlStateNormal];
        [groupButton setCenter:CGPointMake(500, 22)];
        [groupButton addTarget:self action:@selector(autoGroupAvator) forControlEvents:UIControlEventTouchUpInside];
        Reachability *internetReachableCheck = [Reachability reachabilityWithHostName:@"www.baidu.com"];
        internetReachableCheck.reachableBlock =  ^(Reachability *reach){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Internet is OK.");
                [groupButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
                groupButton.hidden = NO;
                self.onlineDetector = [FaceppAPI detection];
                self.onLine = YES;
            });
        };
        
        internetReachableCheck.unreachableBlock = ^(Reachability *reach){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"No Internet");
                [groupButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                groupButton.hidden = YES;
                self.onlineDetector = nil;
                self.onLine = NO;

            });
        };
        
        [internetReachableCheck startNotifier];
        
        self.navigationItem.titleView = groupButton;
    }else
        NSLog(@"FacelessMan is gone.");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self registerAsObserver];
    [self checkFacelessMan];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self cancelObserver];
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

- (void)cancelObserver
{
    [self removeObserver:self forKeyPath:@"selectedFaces"];
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
        newTitle = [NSString stringWithFormat:@"已选择%lu个头像", (unsigned long)self.selectedFaces.count];
        [self.DoneBarButton setTitle:@"确定"];
    }else{
        newTitle = [NSString stringWithFormat:@"已选择%lu个头像", (unsigned long)self.selectedFaces.count];
        [self.DoneBarButton setTitle:@"确定"];
    }
    
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
                NSLog(@"All items at section: %d are choiced. This will trigger detele section.", (int)section+1);
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
                copyFaceItem.section = (int)targetDataSection;
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
                singleCopyFaceItem.section = (int)targetDataSection;
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
            if (selectedFace.section != (int)targetSection) {
                selectedFace.section = (int)targetSection;
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
    _selectBarButton = [[UIBarButtonItem alloc] initWithTitle:@"选 择" style:UIBarButtonItemStyleBordered target:self action:@selector(selectFaces)];
    return _selectBarButton;
}

- (void)selectFaces
{
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.navigationItem.title = @"尚未选择头像";
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
    //_hiddenBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove_user-32.png"] style:UIBarButtonItemStylePlain target:self action:@selector(hiddenSelectedFaces)];
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
    //_addBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewPerson)];
    _addBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_user-32.png"] style:UIBarButtonItemStylePlain target:self action:@selector(addNewPerson)];
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
    Person *newPerson;
    if (self.selectedFaces.count > 0) {
        newPerson = [Person insertNewObjectInManagedObjectContext:self.managedObjectContext];
        newPerson.name = @"";
        newPerson.whetherToDisplay = YES;
        for (NSIndexPath *indexPath in self.selectedFaces) {
            Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            selectedFaceItem.personOwner = newPerson;
            selectedFaceItem.name = @"";
        }
    }
    
    [self manageSelectedItemsWithTargetDataSection:newSection];
    
    if (newPerson) {
        newPerson.order = (int)newSection;
    }
    [self saveEdit];
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    self.goBackUpButton.center = CGPointMake(1000, self.view.center.y);
    [self performSelector:@selector(unenableLeftBarButtonItems) withObject:nil afterDelay:0.1];
}

#pragma mark - move some faces
- (UIBarButtonItem *)moveBarButton
{
    if (_moveBarButton) {
        return _moveBarButton;
    }
    _moveBarButton = [[UIBarButtonItem alloc] initWithTitle:@"移到" style:UIBarButtonItemStyleBordered target:self action:@selector(moveSelectedFacesToPerson)];
    _moveBarButton.enabled = NO;
    return _moveBarButton;
}

- (void)moveSelectedFacesToPerson
{
    [self.view addSubview:self.candidateView];
    [self.candidateView reloadData];
    [self unenableLeftBarButtonItems];
    
    [self.collectionView setContentInset:UIEdgeInsetsMake(164.0f, 0.0f, 0.0f, 0.0f)];
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
    //_DoneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEdit)];
    _DoneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleBordered target:self action:@selector(doneEdit)];
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
    
    self.navigationItem.title = @"";
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
    _showGalleryBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showGalleryScene)];
    return _showGalleryBarButton;
}

- (void)showGalleryScene
{
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    BOOL ThreeScene = [defaultConfig boolForKey:@"isGalleryOpened"];
    NSUInteger count = [[self.faceFetchedResultsController sections] count];
    if (!ThreeScene){
        NSLog(@"No Three.");
        if (count > 1) {
            [defaultConfig setBool:YES forKey:@"isGalleryOpened"];
            [defaultConfig synchronize];
            NSLog(@"Open Three");
        }else if (count == 1){
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (faceItem.section != 0) {
                [defaultConfig setBool:YES forKey:@"isGalleryOpened"];
                [defaultConfig synchronize];
                NSLog(@"Open Three.");
            }
        }
    }else{
        NSLog(@"Yeah, Three");
        if (count == 1) {
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (faceItem.section == 0) {
                [defaultConfig setBool:NO forKey:@"isGalleryOpened"];
                [defaultConfig synchronize];
                NSLog(@"Close Three.");
            }
        }else if (count == 0){
            [defaultConfig setBool:NO forKey:@"isGalleryOpened"];
            [defaultConfig synchronize];
            NSLog(@"Close Three.");
        }
    }

    //NSLog(@"NV VC Count: %d", self.navigationController.viewControllers.count);
    [self.navigationController popToRootViewControllerAnimated:YES];
    //NSLog(@"NV VC Count: %d", self.navigationController.viewControllers.count);
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
        [cell setCellImage:[UIImage imageNamed:@"group-100.png"]];
        cell.backgroundColor = [UIColor whiteColor];
    }else
        [cell setCellImage:[UIImage imageWithContentsOfFile:firstItemInSection.pathForBackup]];
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
        
        Person *selectedPerson;
        NSFetchRequest *personFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"order == %@", @(targetSection)];
        [personFetchRequest setPredicate:predicate];
        NSArray *Persons = [self.managedObjectContext executeFetchRequest:personFetchRequest error:nil];
        if (Persons && Persons.count > 0) {
            selectedPerson = (Person *)Persons.firstObject;
            if (self.selectedFaces.count > 0) {
                for (NSIndexPath *itemIndexPath in self.selectedFaces) {
                    Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:itemIndexPath];
                    if (![selectedFaceItem.personOwner.objectID isEqual:selectedPerson.objectID]) {
                        NSLog(@"JUST FOR TEST");
                        selectedFaceItem.personOwner = selectedPerson;
                        if (selectedPerson.name.length > 0) {
                            selectedFaceItem.name = selectedPerson.name;
                        }
                    }
                }
            }
        }
        
        [self filterSelectedItemSetWithTargetViewSection:indexPath.item];
        [self manageSelectedItemsWithTargetDataSection:targetSection];
        
        [self unenableLeftBarButtonItems];
        [self.candidateView removeFromSuperview];
        [self.collectionView setContentInset:UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f)];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
        
        self.goBackUpButton.center = CGPointMake(1000, self.view.center.y);
    }
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self processCellAtIndexPath:indexPath type:@"Deselect"];
}

- (void)processCellAtIndexPath:(NSIndexPath *)indexPath type:(NSString *)type
{
    //UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if ([type isEqual:@"Select"]) {
        NSLog(@"Select Cell: %ld, %ld", (long)indexPath.section, (long)indexPath.item);
        [self addSelectedFaces:[NSSet setWithObject:indexPath]];
        
        [self enableLeftBarButtonItems];
        //cell.layer.borderColor = [[UIColor greenColor] CGColor];
        //cell.layer.borderWidth = 3.0f;
        //cell.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }
    
    if ([type isEqual:@"Deselect"]) {
        NSLog(@"Deselect Cell: %ld, %ld", (long)indexPath.section, (long)indexPath.item);
        //cell.layer.borderWidth = 0.0f;
        //cell.transform = CGAffineTransformMakeScale(1.0, 1.0);
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

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    self.activedField = textField;
    self.oldContent = textField.text;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    if (self.activedField.text.length > 0 && ![self.activedField.text isEqualToString:self.oldContent]) {
        NSLog(@"Change Name");
        NSUInteger section = [[self.faceFetchedResultsController sections] count];
        CGRect rectInCollectionView = [textField convertRect:textField.frame toView:self.collectionView];
        //NSLog(@"Text Field Frame: %f, %f, %f, %f", rectInCollectionView.origin.x, rectInCollectionView.origin.y, textField.frame.size.width, textField.frame.size.height);
        for (int i = 0; i<section; i++) {
            NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            CGRect frame = [[self.dataSource collectionView:self.collectionView viewForSupplementaryElementOfKind:nil atIndexPath:currentIndexPath] frame];
            //NSLog(@"HeadView Frame: %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
            if (CGRectIntersectsRect(frame, rectInCollectionView)) {
                //NSLog(@"Match at IndexPath: %@", currentIndexPath);
                Person *personItem = [[self.faceFetchedResultsController objectAtIndexPath:currentIndexPath] personOwner];
                personItem.name = self.activedField.text;
                for (Face *faceItem in personItem.ownedFaces) {
                    faceItem.name = personItem.name;
                }
                [self saveEdit];
                break;
            }
        }
    }
    self.activedField = nil;
}


#pragma mark - Handle keyboard show and dismiss
// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    NSLog(@"register for keyboard notification.");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"Keyboard show");
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    //CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    //NSLog(@"Keyboard Frame: %f, %f", kbRect.origin.x, kbRect.origin.y);
    NSLog(@"Keyboard Size: %fx%f", kbSize.height, kbSize.width);
    
    UIEdgeInsets edgeInsets = self.collectionView.contentInset;
    //NSLog(@"EdgeInsets: %f, %f, %f, %f", edgeInsets.top, edgeInsets.left, edgeInsets.bottom, edgeInsets.right);
    //CGRect textFiledRect = [self.collectionView convertRect:self.activedField.frame fromView:self.activedField.superview];
    //NSLog(@"Active TextField Frame: %f %f", textFiledRect.origin.x, textFiledRect.origin.y);
    edgeInsets.bottom = kbSize.width + 140;
    UIEdgeInsets contentInsets = edgeInsets;
    self.collectionView.contentInset = contentInsets;
    //self.collectionView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    //I found the follow code effect nothing.
    //CGRect aRect = self.collectionView.frame;
    //aRect.size.height -= kbSize.width;
    //if (!CGRectContainsPoint(aRect, textFiledRect.origin) ) {
    //    NSLog(@"I am hidden.");
    //    [self.collectionView scrollRectToVisible:textFiledRect animated:YES];
    //}
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSLog(@"Keyboard hidden.");
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(44.0, 0.0, 0.0, 0.0);
    self.collectionView.contentInset = contentInsets;
    //self.collectionView.scrollIndicatorInsets = contentInsets;
}

- (void)trainModelAtSection:(NSInteger)section
{
    if (self.onLine) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"order == %@", @(section)];
        [fetchRequest setPredicate:predicate];
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        if (fetchedObjects && fetchedObjects.count == 1) {
            Person *personItem = (Person *)fetchedObjects.firstObject;
            if (personItem.personID) {
                for (Face *faceItem in personItem.ownedFaces) {
                    if (faceItem.faceID) {
                        [[FaceppAPI person] addFaceWithPersonName:nil orPersonId:personItem.personID andFaceId:@[faceItem.faceID]];
                    }else{
                        if (faceItem.uploaded && !faceItem.accepted) {
                            ;
                        }else{
                            UIImage *faceImage = [UIImage imageWithContentsOfFile:faceItem.pathForBackup];
                            NSData *faceData = UIImageJPEGRepresentation(faceImage, 0.0);
                            FaceppResult *uploadResult = [self.onlineDetector detectWithURL:nil orImageData:faceData];
                            if (uploadResult.success) {
                                NSArray *detectResult = uploadResult.content[@"face"];
                                if ([detectResult count] != 0) {
                                    faceItem.faceID = detectResult[0][@"face_id"];
                                    NSLog(@"faceID is %@", faceItem.faceID);
                                    [[FaceppAPI person] addFaceWithPersonName:nil orPersonId:personItem.personID andFaceId:@[faceItem.faceID]];
                                }else{
                                    faceItem.uploaded = YES;
                                    faceItem.accepted = NO;
                                }
                            }
                        }
                    }
                }
            }else{
                FaceppResult *result = [[FaceppPerson alloc] create];
                personItem.personID = (NSString *)[result.content valueForKey:@"person_id"];
                [self saveEdit];
                NSLog(@"Person_ID: %@",personItem.personID);
                for (Face *faceItem in personItem.ownedFaces) {
                    if (faceItem.faceID) {
                        [[FaceppAPI person] addFaceWithPersonName:nil orPersonId:personItem.personID andFaceId:@[faceItem.faceID]];
                    }else{
                        if (faceItem.uploaded && !faceItem.accepted) {
                            ;
                        }else{
                            UIImage *faceImage = [UIImage imageWithContentsOfFile:faceItem.pathForBackup];
                            NSData *faceData = UIImageJPEGRepresentation(faceImage, 0.0);
                            FaceppResult *uploadResult = [self.onlineDetector detectWithURL:nil orImageData:faceData];
                            if (uploadResult.success) {
                                NSArray *detectResult = uploadResult.content[@"face"];
                                if ([detectResult count] != 0) {
                                    faceItem.faceID = detectResult[0][@"face_id"];
                                    NSLog(@"faceID is %@", faceItem.faceID);
                                    [[FaceppAPI person] addFaceWithPersonName:nil orPersonId:personItem.personID andFaceId:@[faceItem.faceID]];
                                }else{
                                    faceItem.uploaded = YES;
                                    faceItem.accepted = NO;
                                }
                            }
                        }
                    }
                }
            }
        }
    }else
        NSLog(@"No Internet.");
}


@end
