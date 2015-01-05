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
@property (nonatomic) UIBarButtonItem *showFaceRoomBarButton;
@property (nonatomic) UIBarButtonItem *moveBarButton;
@property (nonatomic) UIBarButtonItem *hiddenBarButton;
@property (nonatomic) UIBarButtonItem *addBarButton;

@property (nonatomic) NSMutableSet *selectedFacesSet;
@property (nonatomic) NSMutableSet *includedSectionsSet;
@property (nonatomic) NSMutableSet *triggeredDeletedSectionsSet;
@property (nonatomic) NSMutableSet *guardObjectIDsSet;

@property (nonatomic) UICollectionView  *candidateView;
@property (nonatomic) UIImageView *maskImageView;

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
    [self.goBackUpButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
    [self.goBackUpButton sizeToFit];
    self.goBackUpButton.center = CGPointMake(1000, self.view.center.y);
    self.goBackUpButton.hidden = YES;
    [self.goBackUpButton addTarget:self action:@selector(goBackToTop) forControlEvents:UIControlEventTouchUpInside];
    
    [self.navigationItem setLeftBarButtonItem:self.selectBarButton];
    [self.navigationItem setRightBarButtonItem:self.showFaceRoomBarButton];
    [self registerForKeyboardNotifications];
    
    self.selectedFacesSet = [[NSMutableSet alloc] init];
    self.includedSectionsSet = [[NSMutableSet alloc] init];
    self.triggeredDeletedSectionsSet = [NSMutableSet new];
    self.guardObjectIDsSet = [NSMutableSet new];
    
    self.collectionView.allowsSelection = NO;
    self.maskImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-100, -100, 44, 44)];
    [self.view addSubview:self.maskImageView];
    
    self.dataSource = [SDEMRVCDataSource sharedDataSource];
    self.collectionView.dataSource = self.dataSource;
    self.dataSource.collectionView = self.collectionView;
    self.faceFetchedResultsController = self.dataSource.faceFetchedResultsController;
    self.managedObjectContext = self.faceFetchedResultsController.managedObjectContext;
    
    NSError *error;
    if (![self.faceFetchedResultsController performFetch:&error]) {
        NSLog(@"Face Fetch Fail: %@", error);
    }

    //NSLog(@"FetchedObjects include %lu objects", (unsigned long)[[self.faceFetchedResultsController fetchedObjects] count]);
}

-(void)goBackToTop
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    self.goBackUpButton.hidden = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.tabBarController.tabBar.hidden = YES;
    [self registerAsObserver];
    [self checkRightBarButtionItem];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.dataSource fetchDataAtBackground];
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

- (void)viewWillDisappear:(BOOL)animated
{
    [self cancelObserver];
    [super viewWillDisappear:animated];
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
- (void)addSelectedFacesSet:(NSSet *)objects
{
    [self.selectedFacesSet unionSet:objects];
}

- (void)removeSelectedFacesSet:(NSSet *)objects
{
    [self.selectedFacesSet minusSet:objects];
}

#pragma mark - KVO Notification and Response
- (void)registerAsObserver
{
    [self addObserver:self forKeyPath:@"selectedFacesSet" options:0 context:NULL];
    //[self addObserver:self forKeyPath:@"isChoosingAvator" options:0 context:NULL];
}

- (void)cancelObserver
{
    [self removeObserver:self forKeyPath:@"selectedFacesSet"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedFacesSet"]) {
        [self updateTitle];
    }
}

- (void)updateTitle
{
    NSString *newTitle;
    if (self.selectedFacesSet.count > 1) {
        newTitle = [NSString stringWithFormat:@"Select %lu avators", (unsigned long)self.selectedFacesSet.count];
        [self.DoneBarButton setTitle:@"Cancel"];
    }else if (self.selectedFacesSet.count == 1){
        newTitle = [NSString stringWithFormat:@"Select 1 avator"];
        [self.DoneBarButton setTitle:@"Cancel"];
    }else{
        newTitle = @"";
        [self.DoneBarButton setTitle:@"Confirm"];
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
    [self.triggeredDeletedSectionsSet removeAllObjects];
    [self.guardObjectIDsSet removeAllObjects];
    [self removeSelectedFacesSet:[self.selectedFacesSet copy]];
    [self.includedSectionsSet removeAllObjects];
    
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
    DLog(@"STEP 1: filter selected items.");
    [self.guardObjectIDsSet removeAllObjects];
    [self.triggeredDeletedSectionsSet removeAllObjects];
    
    NSPredicate *targetViewSectionPredicate = [NSPredicate predicateWithFormat:@"section != %@", @(targetViewSection)];
    [self.selectedFacesSet filterUsingPredicate:targetViewSectionPredicate];
    [self.includedSectionsSet removeObject:@(targetViewSection)];
    
    //if selected items include a whole section's items, handle it.
    for (NSNumber *sectionNumber in self.includedSectionsSet) {
        NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"section == %@", sectionNumber];
        NSArray *matchedItems = [self.selectedFacesSet.allObjects filteredArrayUsingPredicate:sectionPredicate];
        if (matchedItems.count > 0) {
            NSInteger section = [sectionNumber integerValue];
            NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
            if (itemCount == matchedItems.count) {
                DLog(@"All items at section: %d are choiced. This will trigger detele section.", (int)section+1);
                [self.triggeredDeletedSectionsSet addObject:sectionNumber];
                [self.selectedFacesSet removeObject:[NSIndexPath indexPathForItem:0 inSection:section]];
            }
        }
    }
    [self.includedSectionsSet removeAllObjects];
}

- (void)manageSelectedItemsWithTargetDataSection:(NSInteger)targetDataSection
{
    DLog(@"STEP 2: create copy items in target section.");
    if (self.triggeredDeletedSectionsSet.count > 0) {
        for (NSNumber *sectionNumber in self.triggeredDeletedSectionsSet) {
            NSInteger section = sectionNumber.integerValue;
            if (section == targetDataSection) {
                DLog(@"It's impossible!!!");
            }else{
                Face *copyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
                copyFaceItem.section = (int)targetDataSection;
                copyFaceItem.whetherToDisplay = YES;
            }
        }
    }else{
        if (self.selectedFacesSet.count > 0) {
            NSIndexPath *anyIndexPath = self.selectedFacesSet.anyObject;
            DLog(@"Index: %@", anyIndexPath);
            Face *anyFace = [self.faceFetchedResultsController objectAtIndexPath:anyIndexPath];
            if (anyFace.section == targetDataSection) {
                DLog(@"Something is wrong, indexpath: %@ should be filterd at previous step.", anyIndexPath);
                //[self filterSelectedItemsInSection:targetDataSection];
            }else{
                Face *singleCopyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:anyIndexPath];
                singleCopyFaceItem.section = (int)targetDataSection;
                singleCopyFaceItem.whetherToDisplay = YES;
            }
            [self.selectedFacesSet removeObject:anyIndexPath];
        }
    }
    
    [self performSelector:@selector(moveOtherItemsToSection:) withObject:@(targetDataSection) afterDelay:0.1];
}

- (void)filterSelectedItemsInSection:(NSInteger)section
{
    NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"section != %@", @(section)];
    [self.selectedFacesSet filterUsingPredicate:sectionPredicate];
}

- (NSManagedObject *)copyManagedObjectAtIndexPath:(NSIndexPath *)indexPath;
{
    Face *originalFaceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID *objectID = originalFaceItem.objectID;
    [self.guardObjectIDsSet addObject:objectID];
    Face *copyFaceItem = [Face insertNewObjectInManagedObjectContext:self.managedObjectContext];
    copyFaceItem.avatorImage = originalFaceItem.avatorImage;
    copyFaceItem.storeFileName = originalFaceItem.storeFileName;
    copyFaceItem.portraitAreaRect = originalFaceItem.portraitAreaRect;
    copyFaceItem.faceID = originalFaceItem.faceID;
    copyFaceItem.order = originalFaceItem.order;
    copyFaceItem.assetURLString = originalFaceItem.assetURLString;
    copyFaceItem.tag = originalFaceItem.tag;
    copyFaceItem.isMyStar = originalFaceItem.isMyStar;
    copyFaceItem.personOwner = originalFaceItem.personOwner;
    copyFaceItem.photoOwner = originalFaceItem.photoOwner;
    
    return copyFaceItem;
}

- (void)moveOtherItemsToSection:(NSNumber *)targetSectionNumber
{
    if (self.selectedFacesSet.count > 0) {
        DLog(@"STEP 3: move left items to target section.");
        NSInteger targetSection = [targetSectionNumber integerValue];
        for (NSIndexPath *indexPath in self.selectedFacesSet) {
            Face *selectedFace = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            if (selectedFace.section != (int)targetSection) {
                selectedFace.section = (int)targetSection;
            }
        }
        [self.selectedFacesSet removeAllObjects];
    }else
        DLog(@"There is no item need to move.");

    [self performSelector:@selector(deleteOriginalItems) withObject:nil afterDelay:0.1];
}

- (void)deleteOriginalItems
{
    if (self.guardObjectIDsSet.count > 0) {
        DLog(@"STEP 4: delete original items.");
        for (NSManagedObjectID *objectID in self.guardObjectIDsSet) {
            Face *originalFace = (Face *)[self.managedObjectContext existingObjectWithID:objectID error:nil];
            [self.faceFetchedResultsController.managedObjectContext deleteObject:originalFace];
        }
        [self.guardObjectIDsSet removeAllObjects];
    }else
        DLog(@"There is no item to delete.");
    
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
    self.navigationItem.title = @"";
    self.navigationItem.rightBarButtonItem = self.DoneBarButton;
    
    NSArray *leftBarButtonItems = @[self.hiddenBarButton, self.addBarButton, self.moveBarButton];
    self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    
    //[self.selectedFaces removeAllObjects];
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Selected Faces" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"Sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        for (NSIndexPath *indexPath in self.selectedFacesSet) {
            Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            face.whetherToDisplay = NO;
            [self.dataSource removeCachedImageWithKey:face.storeFileName];
        }
        
        [self cleanUsedData];
        [self unenableLeftBarButtonItems];
    }];
    [alert addAction:OKAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - add a new person
- (UIBarButtonItem *)addBarButton
{
    if (_addBarButton) {
        return _addBarButton;
    }
    _addBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addPerson.png"] style:UIBarButtonItemStylePlain target:self action:@selector(addNewPerson)];
    _addBarButton.enabled = NO;
    return _addBarButton;
}

- (void)addNewPerson
{
    NSInteger sectionCount = [self.collectionView numberOfSections];
    Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount-1]];
    NSInteger newSection = firstItemInSection.section + 1;
    [self filterSelectedItemSetWithTargetViewSection:sectionCount];
    Person *newPerson;
    if (self.selectedFacesSet.count > 0) {
        newPerson = [Person insertNewObjectInManagedObjectContext:self.managedObjectContext];
        newPerson.whetherToDisplay = YES;
        for (NSIndexPath *indexPath in self.selectedFacesSet) {
            Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            selectedFaceItem.personOwner = newPerson;
            selectedFaceItem.name = nil;
        }
    }
    
    [self manageSelectedItemsWithTargetDataSection:newSection];
    
    if (newPerson) {
        newPerson.order = (int)newSection;
        Face *anyFaceItem = (Face *)newPerson.ownedFaces.anyObject;
        NSString *storeFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *avatorStorePath = [storeFolder stringByAppendingPathComponent:anyFaceItem.storeFileName];
        UIImage *avatorImage = [UIImage imageWithContentsOfFile:avatorStorePath];
        /*
        UIGraphicsBeginImageContext(CGSizeMake(44.0f, 44.0f));
        [avatorImage drawInRect:CGRectMake(0, 0, 44.0f, 44.0f)];
        UIImage *thubnailImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
         */
        if (!avatorImage) {
            avatorImage = anyFaceItem.avatorImage;
        }
        newPerson.avatorImage = avatorImage;
        
        NSString *portraitName = [[[NSUUID alloc] init] UUIDString];
        portraitName = [portraitName stringByAppendingPathExtension:@"jpg"];
        newPerson.portraitFileString = portraitName;
        NSString *savePath = [storeFolder stringByAppendingPathComponent:portraitName];
        
        [self createPosterFileFromAsset:anyFaceItem.assetURLString WithArea:anyFaceItem.portraitAreaRect AtPath:savePath];
        
    }
    NSLog(@"New person get %lu avators", (unsigned long)newPerson.ownedFaces.count);
    [self saveEdit];
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    
    self.goBackUpButton.hidden = NO;
    //奇怪，记得当时是因为正常的调用不起作用，才使用 performSelector 的，这里完全可以正常调用啊。是不是当时写迷糊了？
    //[self performSelector:@selector(unenableLeftBarButtonItems) withObject:nil afterDelay:0.1];
    [self unenableLeftBarButtonItems];
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionCount]];
}

- (BOOL)createPosterFileFromAsset:(NSString *)assetURLString WithArea:(NSValue *)portraitAreaRect AtPath:(NSString *)storePath
{
    __block BOOL success = NO;
    [[[ALAssetsLibrary alloc] init] assetForURL:[NSURL URLWithString:assetURLString] resultBlock:^(ALAsset *asset){
        if (asset) {
            CGImageRef sourceCGImage = [asset.defaultRepresentation fullScreenImage];
            CGImageRef portraitCGImage = CGImageCreateWithImageInRect(sourceCGImage, portraitAreaRect.CGRectValue);
            UIImage *portraitUIImage = [UIImage imageWithCGImage:portraitCGImage];
            NSData *imageData = UIImageJPEGRepresentation(portraitUIImage, 1.0f);
            
            BOOL isExisted = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
            if (isExisted) {
                BOOL deleteResult = [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
                if (!deleteResult) {
                    NSLog(@"Delete File Error.");
                }else
                    NSLog(@"Delete Success.");
            }
            
            success = [imageData writeToFile:storePath atomically:YES];
            if (!success) {
                NSLog(@"Create Portrait Image File Error");
            }
            //NSLog(@"Write Portrait Image File to Path: %@", storePath);
            CGImageRelease(portraitCGImage);
            //CGImageRelease(sourceCGImage);
        }else
            NSLog(@"Access Asset Failed");
    }failureBlock:^(NSError *error){
        NSLog(@"Authorizate Failed");
    }];
    
    return success;
}

#pragma mark - move some faces
- (UIBarButtonItem *)moveBarButton
{
    if (_moveBarButton) {
        return _moveBarButton;
    }
    _moveBarButton = [[UIBarButtonItem alloc] initWithTitle:@"MoveTo" style:UIBarButtonItemStyleBordered target:self action:@selector(moveSelectedFacesToPerson)];
    _moveBarButton.enabled = NO;
    return _moveBarButton;
}

- (void)moveSelectedFacesToPerson
{
    //[self.view addSubview:self.candidateView];
    CGRect frame = self.collectionView.frame;
    frame.size.height = 120.0f;
    frame.origin.y = 44.0f;
    [UIView animateWithDuration:0.3 animations:^{
        [self.candidateView setFrame:frame];
    }completion:^(BOOL isFinished){
        [self.candidateView reloadData];
    }];
    
    [self unenableLeftBarButtonItems];
    
    self.collectionView.bounces = YES;
    [self.collectionView setContentInset:UIEdgeInsetsMake(164.0f, 0.0f, 0.0f, 0.0f)];
}

- (UICollectionView *)candidateView
{
    if (_candidateView) {
        return _candidateView;
    }
    
    CGRect frame = self.collectionView.frame;
    frame.size.height = 0.0f;
    frame.origin.y = 44.0f;
    UICollectionViewFlowLayout *lineLayout = [[UICollectionViewFlowLayout alloc] init];
    lineLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    lineLayout.itemSize = CGSizeMake(100.0f, 100.0f);
    lineLayout.sectionInset = UIEdgeInsetsMake(10.0f, 25.0f, 10.0f, 25.0f);
    _candidateView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:lineLayout];
    [_candidateView registerClass:[SDECandidateCell class] forCellWithReuseIdentifier:@"candidateCell"];
    _candidateView.dataSource = self;
    _candidateView.delegate = self;
    [self.view addSubview:_candidateView];
    return _candidateView;
}

- (void)hiddenCandidateView
{
    CGRect frame = self.collectionView.frame;
    frame.size.height = 0.0f;
    frame.origin.y = 44.0f;
    [UIView animateWithDuration:0.3 animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [self.candidateView setFrame:frame];
    }];
}

#pragma mark - done and save
- (UIBarButtonItem *)DoneBarButton
{
    if (_DoneBarButton) {
        return _DoneBarButton;
    }
    _DoneBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(doneEdit)];
    return _DoneBarButton;
}


- (void)doneEdit
{
    if ([self.view.subviews containsObject:self.candidateView]) {
        [self hiddenCandidateView];
        [self.collectionView setContentInset:UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f)];
    }
    
    self.navigationItem.title = @"";
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = self.selectBarButton;
    self.navigationItem.rightBarButtonItem = self.showFaceRoomBarButton;
    [self.DoneBarButton setTitle:@"Cancel"];
    
    [self unenableLeftBarButtonItems];
    self.collectionView.allowsSelection = NO;
    [self.selectedFacesSet removeAllObjects];
    [self.includedSectionsSet removeAllObjects];
    [self.triggeredDeletedSectionsSet removeAllObjects];
    [self.guardObjectIDsSet removeAllObjects];
    
    [self saveEdit];
    [self checkRightBarButtionItem];
}

#pragma mark - go to FaceRoom Scene
- (UIBarButtonItem *)showFaceRoomBarButton
{
    if (_showFaceRoomBarButton) {
        return _showFaceRoomBarButton;
    }
    _showFaceRoomBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(showFaceRoomScene)];
    return _showFaceRoomBarButton;
}

- (void)showFaceRoomScene
{
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    BOOL ThreeScene = [defaultConfig boolForKey:@"isGalleryOpened"];
    NSUInteger count = [[self.faceFetchedResultsController sections] count];
    if (!ThreeScene){
        DLog(@"No Three.");
        if (count > 1) {
            [defaultConfig setBool:YES forKey:@"isGalleryOpened"];
            [defaultConfig synchronize];
            DLog(@"Open Three");
        }else if (count == 1){
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (faceItem.section != 0) {
                [defaultConfig setBool:YES forKey:@"isGalleryOpened"];
                [defaultConfig synchronize];
                DLog(@"Open Three.");
            }
        }
    }else{
        DLog(@"Yeah, Three");
        if (count == 1) {
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (faceItem.section == 0) {
                [defaultConfig setBool:NO forKey:@"isGalleryOpened"];
                [defaultConfig synchronize];
                DLog(@"Close Three.");
            }
        }else if (count == 0){
            [defaultConfig setBool:NO forKey:@"isGalleryOpened"];
            [defaultConfig synchronize];
            DLog(@"Close Three.");
        }
    }

    //DLog(@"NV VC Count: %d", self.navigationController.viewControllers.count);
    [self.navigationController popToRootViewControllerAnimated:YES];
    //NSLog(@"NV VC Count: %lu", (unsigned long)self.navigationController.viewControllers.count);
}

#pragma mark - Select Candidate UICollectionView Data Source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger sectionNumber = [self.collectionView numberOfSections];
    return sectionNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDECandidateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"candidateCell" forIndexPath:indexPath];
    Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
    if (firstItemInSection.section == 0) {
        [cell setCellImage:[UIImage imageNamed:@"FacelessManAvator.png"]];
        cell.backgroundColor = [UIColor whiteColor];
    }else
        [cell setCellImage:firstItemInSection.avatorImage];
    return cell;
}

#pragma mark - UICollectionView Delegate Method
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.collectionView]) {
        [self processCellAtIndexPath:indexPath type:@"Select"];
        self.collectionView.bounces = NO;
        if (![self.includedSectionsSet containsObject:[NSNumber numberWithInteger:indexPath.section]]) {
            [self.includedSectionsSet addObject:@(indexPath.section)];
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
            if (self.selectedFacesSet.count > 0) {
                for (NSIndexPath *itemIndexPath in self.selectedFacesSet) {
                    Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:itemIndexPath];
                    if (![selectedFaceItem.personOwner.objectID isEqual:selectedPerson.objectID]) {
                        selectedFaceItem.personOwner = selectedPerson;
                        if (selectedPerson.name.length > 0) {
                            selectedFaceItem.name = selectedPerson.name;
                        }
                    }
                }
            }
        }
        
        [self hiddenCandidateView];
        
        [self filterSelectedItemSetWithTargetViewSection:indexPath.item];
        [self manageSelectedItemsWithTargetDataSection:targetSection];
        
        [self unenableLeftBarButtonItems];
        [self.collectionView setContentInset:UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f)];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
        
        self.goBackUpButton.hidden = NO;
    }
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self processCellAtIndexPath:indexPath type:@"Deselect"];
}

- (void)processCellAtIndexPath:(NSIndexPath *)indexPath type:(NSString *)type
{
    if ([type isEqual:@"Select"]) {
        [self addSelectedFacesSet:[NSSet setWithObject:indexPath]];
        [self enableLeftBarButtonItems];
    }
    
    if ([type isEqual:@"Deselect"]) {
        [self removeSelectedFacesSet:[NSSet setWithObject:indexPath]];
        
        if (self.selectedFacesSet.count == 0) {
            [self unenableLeftBarButtonItems];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Hold on");
    return YES;
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activedField = textField;
    self.oldContent = textField.text;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.activedField.text.length > 0 && ![self.activedField.text isEqualToString:self.oldContent]) {
        NSUInteger section = [[self.faceFetchedResultsController sections] count];
        CGRect rectInCollectionView = [textField convertRect:textField.frame toView:self.collectionView];
        //DLog(@"Text Field Frame: %f, %f, %f, %f", rectInCollectionView.origin.x, rectInCollectionView.origin.y, textField.frame.size.width, textField.frame.size.height);
        for (int i = 0; i<section; i++) {
            NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            CGRect frame = [[self.dataSource collectionView:self.collectionView viewForSupplementaryElementOfKind:nil atIndexPath:currentIndexPath] frame];
            //DLog(@"HeadView Frame: %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
            if (CGRectIntersectsRect(frame, rectInCollectionView)) {
                //DLog(@"Match at IndexPath: %@", currentIndexPath);
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
    DLog(@"register for keyboard notification.");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardDidShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIEdgeInsets edgeInsets = self.collectionView.contentInset;
    float kbHeight = (kbSize.width > kbSize.height)?kbSize.height:kbSize.width;
    edgeInsets.bottom = kbHeight + 140;
    UIEdgeInsets contentInsets = edgeInsets;
    self.collectionView.contentInset = contentInsets;
    //self.collectionView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    //I found the follow code effect nothing.
    //CGRect aRect = self.collectionView.frame;
    //aRect.size.height -= kbSize.width;
    //if (!CGRectContainsPoint(aRect, textFiledRect.origin) ) {
    //    DLog(@"I am hidden.");
    //    [self.collectionView scrollRectToVisible:textFiledRect animated:YES];
    //}
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(44.0, 0.0, 0.0, 0.0);
    self.collectionView.contentInset = contentInsets;
}


@end
