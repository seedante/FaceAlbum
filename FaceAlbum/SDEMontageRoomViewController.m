//
//  SDMontageRoomViewController.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEMontageRoomViewController.h"
#import "SDEMRVCDataSource.h"
#import "SDEPhotoScanManager.h"
#import "SDEStore.h"
#import "Person.h"
#import "Face.h"
#import "Reachability.h"
#import "FaceppAPI.h"
#import "APIKey+APISecret.h"
#import "SDECandidateCell.h"

@interface SDEMontageRoomViewController ()<UIAlertViewDelegate>

@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) SDEMRVCDataSource *dataSource;

@property (nonatomic) UIBarButtonItem *selectBarButton;
@property (nonatomic) UIBarButtonItem *DoneBarButton;
@property (nonatomic) UIBarButtonItem *jumpToFaceRoomBarButton;
@property (nonatomic) UIBarButtonItem *moveBarButton;
@property (nonatomic) UIBarButtonItem *hiddenBarButton;
@property (nonatomic) UIBarButtonItem *addBarButton;

@property (nonatomic) NSMutableSet *selectedFacesSet;
@property (nonatomic) NSMutableSet *includedSectionsSet;
@property (nonatomic) NSMutableSet *triggeredDeletedSectionsSet;
@property (nonatomic) NSMutableSet *guardObjectIDsSet;

@property (nonatomic) UICollectionView  *candidateView;

@property (nonatomic) UITextField *activedField;
@property (nonatomic) UIButton *goBackUpButton;
@property (nonatomic, copy) NSString *oldContent;

@property (nonatomic)FaceppDetection *onlineDetector;
@property (nonatomic, assign) BOOL onLine;


@end

@implementation SDEMontageRoomViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.goBackUpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.goBackUpButton setImage:[UIImage imageNamed:@"up.png"] forState:UIControlStateNormal];
    [self.goBackUpButton sizeToFit];
    self.goBackUpButton.center = CGPointMake(1000, self.view.frame.size.height - 70);
    self.goBackUpButton.hidden = YES;
    [self.goBackUpButton addTarget:self action:@selector(goBackToTop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.goBackUpButton];
    
    [self.navigationItem setLeftBarButtonItem:self.selectBarButton];
    [self.navigationItem setRightBarButtonItem:self.jumpToFaceRoomBarButton];
    
    self.selectedFacesSet = [[NSMutableSet alloc] init];
    self.includedSectionsSet = [[NSMutableSet alloc] init];
    self.triggeredDeletedSectionsSet = [NSMutableSet new];
    self.guardObjectIDsSet = [NSMutableSet new];
    
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.tabBarController.tabBar.hidden = YES;
    [self registerAsObserver];
    [self checkPersonNumber];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.dataSource fetchDataAtBackground];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self cancelObserver];
    [super viewWillDisappear:animated];
}

-(void)goBackToTop
{
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    self.goBackUpButton.hidden = YES;
}

- (void)checkPersonNumber
{
    //If there is only FacelessMan, can't jump to FaceRoom Scene
    NSArray *sections = self.faceFetchedResultsController.sections;
    if (sections) {
        if (sections.count > 1) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }else if (sections.count == 1){
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if (faceItem.section == 0) {
                self.navigationItem.rightBarButtonItem.enabled = NO;
            }else
                self.navigationItem.rightBarButtonItem.enabled = YES;
        }else if (sections.count == 0){
            self.jumpToFaceRoomBarButton.enabled = YES;
            self.selectBarButton.enabled = NO;
            self.tabBarController.tabBar.hidden = NO;
            self.navigationItem.title = @"No Face Here.";
        }
    }else{
        self.jumpToFaceRoomBarButton.enabled = NO;
        self.selectBarButton.enabled = NO;
    }

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

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
        [self enableLeftBarButtonItems];
    }else if (self.selectedFacesSet.count == 1){
        newTitle = [NSString stringWithFormat:@"Select 1 avator"];
        [self.DoneBarButton setTitle:@"Cancel"];
        [self enableLeftBarButtonItems];
    }else{
        newTitle = @"";
        [self unenableLeftBarButtonItems];
        [self.DoneBarButton setTitle:@"Confirm"];
    }
    
    self.navigationItem.title = newTitle;
}


#pragma mark - UICollectionViewDelegateFlowLayout
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

- (void)filterSelectedItemSetWithTargetViewSection:(NSInteger)targetViewSection
{
    NSLog(@"STEP 1: filter selected items.");
    [self.guardObjectIDsSet removeAllObjects];
    [self.triggeredDeletedSectionsSet removeAllObjects];
    
    //if a item is in target section, do nothing to it. But remove indexpath from set.
    NSPredicate *targetViewSectionPredicate = [NSPredicate predicateWithFormat:@"section != %@", @(targetViewSection)];
    [self.selectedFacesSet filterUsingPredicate:targetViewSectionPredicate];
    [self.includedSectionsSet removeObject:@(targetViewSection)];
    
    //if all of items in a section are selected, this section will be deleted.
    if (self.includedSectionsSet.count > 0) {
        for (NSNumber *sectionNumber in self.includedSectionsSet) {
            NSPredicate *sectionPredicate = [NSPredicate predicateWithFormat:@"section == %@", sectionNumber];
            NSArray *matchedItems = [self.selectedFacesSet.allObjects filteredArrayUsingPredicate:sectionPredicate];
            if (matchedItems.count > 0) {
                NSInteger section = [sectionNumber integerValue];
                NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
                if (itemCount == matchedItems.count) {
                    //NSLog(@"All items at section: %d are choiced. This will trigger section deletion.", (int)section+1);
                    [self.triggeredDeletedSectionsSet addObject:sectionNumber];
                    NSSet *removedIndexPathSet = [NSSet setWithObject:[NSIndexPath indexPathForItem:0 inSection:section]];
                    [self removeSelectedFacesSet:removedIndexPathSet];
                }
            }
        }
        [self.includedSectionsSet removeAllObjects];
    }

}

- (void)processSelectedItemsWithTargetDataSection:(int)targetDataSection
{
    NSLog(@"STEP 2: move a part of items to target section.");
    if (self.triggeredDeletedSectionsSet.count > 0) {
        for (NSNumber *sectionNumber in self.triggeredDeletedSectionsSet) {
            NSInteger section = sectionNumber.integerValue;
            if (section != targetDataSection) {
                Face *copyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
                copyFaceItem.section = targetDataSection;
                copyFaceItem.whetherToDisplay = YES;
            }else
                NSLog(@"It's impossible!!!");
        }
        [self.triggeredDeletedSectionsSet removeAllObjects];
    }else{
        if (self.selectedFacesSet.count > 0) {
            NSIndexPath *anyIndexPath = self.selectedFacesSet.anyObject;
            Face *anyFaceItem = [self.faceFetchedResultsController objectAtIndexPath:anyIndexPath];
            if (anyFaceItem.section != targetDataSection) {
                Face *singleCopyFaceItem = (Face *)[self copyManagedObjectAtIndexPath:anyIndexPath];
                singleCopyFaceItem.section = (int)targetDataSection;
                singleCopyFaceItem.whetherToDisplay = YES;
                NSSet *indexPathSet = [NSSet setWithObject:anyIndexPath];
                [self removeSelectedFacesSet:indexPathSet];
            }else
                NSLog(@"Something is wrong, indexpath: %@ should be filterd at previous step.", anyIndexPath);
        }
    }
    
    self.collectionView.allowsSelection = NO;
    [self performSelector:@selector(moveOtherItemsToSection:) withObject:@(targetDataSection) afterDelay:0.01];
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
    originalFaceItem.personOwner = nil;
    copyFaceItem.photoOwner = originalFaceItem.photoOwner;
    originalFaceItem.photoOwner = nil;
    
    return copyFaceItem;
}

- (void)moveOtherItemsToSection:(NSNumber *)targetSectionNumber
{
    if (self.selectedFacesSet.count > 0) {
        NSLog(@"STEP 3: move remainder items to target section.");
        int targetSection = [targetSectionNumber intValue];
        for (NSIndexPath *indexPath in self.selectedFacesSet) {
            Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            if (selectedFaceItem.section != targetSection) {
                selectedFaceItem.section = targetSection;
            }
        }
        
        [self removeSelectedFacesSet:[self.selectedFacesSet copy]];
    }
    
    self.collectionView.allowsSelection = YES;
    if (self.guardObjectIDsSet.count > 0) {
        [self performSelector:@selector(deleteOriginalItems) withObject:nil afterDelay:0.001];
    }
}

- (void)deleteOriginalItems
{
    if (self.guardObjectIDsSet.count > 0) {
        NSLog(@"STEP 4: delete original items.");
        for (NSManagedObjectID *objectID in self.guardObjectIDsSet) {
            Face *originalFace = (Face *)[self.managedObjectContext existingObjectWithID:objectID error:nil];
            [self.managedObjectContext deleteObject:originalFace];
        }
        [self.guardObjectIDsSet removeAllObjects];
    }
}

- (void)cleanUsedData
{
    [self.triggeredDeletedSectionsSet removeAllObjects];
    [self.guardObjectIDsSet removeAllObjects];
    [self removeSelectedFacesSet:[self.selectedFacesSet copy]];
    [self.includedSectionsSet removeAllObjects];
    
    [self saveEdit];
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
    self.collectionView.bounces = NO;
    self.navigationItem.title = @"";
    self.navigationItem.rightBarButtonItem = self.DoneBarButton;
    
    NSArray *leftBarButtonItems = @[self.hiddenBarButton, self.addBarButton, self.moveBarButton];
    self.navigationItem.leftBarButtonItems = leftBarButtonItems;
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
    NSArray *versionArray = [[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."];
    if ([versionArray[0] intValue] >= 8) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Selected Avators" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"Sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            for (NSIndexPath *indexPath in self.selectedFacesSet) {
                Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
                faceItem.whetherToDisplay = NO;
                faceItem.personOwner = nil;
                [self.dataSource removeCachedImageWithKey:faceItem.storeFileName];
            }
            
            [self cleanUsedData];
        }];
        [alert addAction:OKAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Selected Avators" message:@"" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Sure", nil];
        alertView.delegate = self;
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        for (NSIndexPath *indexPath in self.selectedFacesSet) {
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            faceItem.whetherToDisplay = NO;
            faceItem.personOwner = nil;
            [self.dataSource removeCachedImageWithKey:faceItem.storeFileName];
        }
        
        [self cleanUsedData];
    }
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
    [self filterSelectedItemSetWithTargetViewSection:sectionCount];
    
    Person *newPerson;
    if (self.selectedFacesSet.count > 0) {
        newPerson = [Person insertNewObjectInManagedObjectContext:self.managedObjectContext];
        newPerson.whetherToDisplay = YES;
        newPerson.personID = @"";
        for (NSIndexPath *indexPath in self.selectedFacesSet) {
            Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            selectedFaceItem.personOwner = newPerson;
            selectedFaceItem.name = @"";
        }
        
        if (self.triggeredDeletedSectionsSet.count > 0) {
            for (NSNumber *sectionNumber in self.triggeredDeletedSectionsSet) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionNumber.integerValue];
                Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
                faceItem.personOwner = newPerson;
            }
        }
    }else if (self.triggeredDeletedSectionsSet.count > 0){
        newPerson = [Person insertNewObjectInManagedObjectContext:self.managedObjectContext];
        newPerson.whetherToDisplay = YES;
        for (NSNumber *sectionNumber in self.triggeredDeletedSectionsSet) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionNumber.integerValue];
            Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
            faceItem.personOwner = newPerson;
        }
    }
    
    Face *firstItemInLastSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount-1]];
    int newSection = firstItemInLastSection.section + 1;
    [self processSelectedItemsWithTargetDataSection:newSection];
    
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
    
    [self saveEdit];
    
    self.goBackUpButton.hidden = NO;

    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionCount] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
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
                [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
            }
            
            success = [imageData writeToFile:storePath atomically:YES];
            //NSLog(@"Write Portrait Image File to Path: %@", storePath);
            CGImageRelease(portraitCGImage);
            //CGImageRelease(sourceCGImage);
        }
    }failureBlock:nil];
    
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
    
    self.collectionView.bounces = YES;
    self.navigationItem.title = @"";
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.leftBarButtonItem = self.selectBarButton;
    self.navigationItem.rightBarButtonItem = self.jumpToFaceRoomBarButton;
    [self.DoneBarButton setTitle:@"Cancel"];
    
    [self unenableLeftBarButtonItems];
    self.collectionView.allowsSelection = NO;
    [self.selectedFacesSet removeAllObjects];
    [self.includedSectionsSet removeAllObjects];
    [self.triggeredDeletedSectionsSet removeAllObjects];
    [self.guardObjectIDsSet removeAllObjects];
    
    [self saveEdit];
    [self checkPersonNumber];
}

#pragma mark - jump to FaceRoom Scene
- (UIBarButtonItem *)jumpToFaceRoomBarButton
{
    if (_jumpToFaceRoomBarButton) {
        return _jumpToFaceRoomBarButton;
    }
    _jumpToFaceRoomBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(jumpToFaceRoomScene)];
    return _jumpToFaceRoomBarButton;
}

- (void)jumpToFaceRoomScene
{
    [self deleteEmptyPersonItems];
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    [defaultConfig setBool:NO forKey:@"isNeedEdited"];
    [defaultConfig synchronize];

    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)deleteEmptyPersonItems
{
    NSFetchRequest *personFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(personID != %@) AND (ownedFaces.@count == 0)", @"FacelessMan"];
    [personFetchRequest setPredicate:predicate];
    NSArray *emptyPersonItems = [self.managedObjectContext executeFetchRequest:personFetchRequest error:nil];
    if (emptyPersonItems.count > 0) {
        NSString *storeDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        for (Person *personItem in emptyPersonItems) {
            //NSLog(@"delete person %@", personItem);
            NSString *storePath = [storeDirectory stringByAppendingPathComponent:personItem.portraitFileString];
            BOOL isExisted = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
            if (isExisted) {
                BOOL deleteResult = [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
                if (!deleteResult) {
                    NSLog(@"Delete File Error.");
                }
            }
            [self.managedObjectContext deleteObject:personItem];
        }
        [self saveEdit];
    }
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
        [self addSelectedFacesSet:[NSSet setWithObject:indexPath]];
        if (![self.includedSectionsSet containsObject:[NSNumber numberWithInteger:indexPath.section]]) {
            [self.includedSectionsSet addObject:@(indexPath.section)];
        }
    }else{
        self.goBackUpButton.hidden = NO;
        [self hiddenCandidateView];
        [self unenableLeftBarButtonItems];
        [self.collectionView setContentInset:UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f)];
        
        Face *firstItemInSection = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item]];
        int targetSection = firstItemInSection.section;
        [self filterSelectedItemSetWithTargetViewSection:indexPath.item];
        
        Person *selectedPerson;
        NSFetchRequest *personFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(order == %@) AND (whetherToDisplay == YES) AND (ownedFaces.@count > 0)", @(targetSection)];
        [personFetchRequest setPredicate:predicate];
        NSArray *Persons = [self.managedObjectContext executeFetchRequest:personFetchRequest error:nil];
        if (Persons && Persons.count > 0) {
            selectedPerson = (Person *)Persons.firstObject;
            if (self.selectedFacesSet.count > 0) {
                for (NSIndexPath *itemIndexPath in self.selectedFacesSet) {
                    Face *selectedFaceItem = [self.faceFetchedResultsController objectAtIndexPath:itemIndexPath];
                    selectedFaceItem.personOwner = selectedPerson;
                    if (selectedPerson.name.length > 0) {
                        selectedFaceItem.name = selectedPerson.name;
                    }
                }
            }
            
            if (self.triggeredDeletedSectionsSet.count > 0) {
                for (NSNumber *sectionNumber in self.triggeredDeletedSectionsSet) {
                    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionNumber.integerValue]];
                    faceItem.personOwner = selectedPerson;
                }
            }
        }
        
        [self processSelectedItemsWithTargetDataSection:targetSection];
        
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.item] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    }
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeSelectedFacesSet:[NSSet setWithObject:indexPath]];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


#pragma mark - Handle keyboard show and dismiss
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
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(44.0, 0.0, 0.0, 0.0);
    self.collectionView.contentInset = contentInsets;
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
        for (int i = 0; i<section; i++) {
            NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            CGRect frame = [[self.dataSource collectionView:self.collectionView viewForSupplementaryElementOfKind:nil atIndexPath:currentIndexPath] frame];
            if (CGRectIntersectsRect(frame, rectInCollectionView)) {
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

@end
