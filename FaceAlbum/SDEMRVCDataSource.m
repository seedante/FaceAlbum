//
//  SDCollectionViewDataSource.m
//  FaceAlbum
//
//  Created by seedante on 14-7-23.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEMRVCDataSource.h"
#import "Face.h"
#import "Photo.h"
#import "Person.h"
#import "Store.h"
#import "SDEAvatorCell.h"
#import "SDEPersonProfileHeaderView.h"
#import "SDEMontageRoomViewController.h"

static NSString * const cellIdentifier = @"avatorCell";

@interface SDEMRVCDataSource ()
{
    NSMutableArray *sectionChanges;
    NSMutableArray *objectChanges;
}

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL blendBatchUpdateMode;
@property (nonatomic) NSCache *imageCache;
@property (nonatomic) NSCache *headerViewCache;
@property (nonatomic) dispatch_queue_t imageLoadQueue;
@property (nonatomic, copy) NSString *storeDirectory;

@end

@implementation SDEMRVCDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        sectionChanges = [[NSMutableArray alloc] init];
        objectChanges = [[NSMutableArray alloc] init];
        self.blendBatchUpdateMode = NO;
        self.imageCache = [[NSCache alloc] init];
        self.headerViewCache = [[NSCache alloc] init];
        self.imageLoadQueue = dispatch_queue_create("com.seedante.FaceAlbum", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (instancetype)sharedDataSource{
    static SDEMRVCDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEMRVCDataSource alloc]init];
    });
    return sharedInstance;
}

- (NSString *)storeDirectory
{
    if (!_storeDirectory) {
        _storeDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    }
    
    return _storeDirectory;
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
    _faceFetchedResultsController.delegate = self;
    
    return _faceFetchedResultsController;
}

#pragma mark - Preferences Improve
- (void)fetchDataAtBackground
{
    NSArray *visibleIndexPath = [self.collectionView indexPathsForVisibleItems];
    NSArray *sections = [self.faceFetchedResultsController sections];
    NSString *storeDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(defaultQueue, ^{
        for (NSUInteger sectionIndex = 0; sectionIndex < sections.count; sectionIndex ++) {
            id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
            NSUInteger itemCount = [sectionInfo numberOfObjects];
            for (NSUInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
                if ([visibleIndexPath containsObject:indexPath]) {
                    continue;
                }else{
                    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
                    NSString *cacheKey = faceItem.storeFileName;
                    NSString *imagePath = [storeDirectory stringByAppendingPathComponent:cacheKey];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        UIGraphicsBeginImageContext(CGSizeMake(100.0f, 100.0f));
                        [image drawInRect:CGRectMake(0, 0, 100.0f, 100.0f)];
                        UIImage *thubnailImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        [self.imageCache setObject:thubnailImage forKey:cacheKey];
                    }
                }
            }
        }
    });
    
}

- (UIImage *)cachedAvatorImageForKey:(NSString *)cachedKey
{
    UIImage *avatorImage = nil;
    avatorImage = [self.imageCache objectForKey:cachedKey];
    return avatorImage;
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"Process I: WILL UPDATE SCREEN");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSLog(@"Process II: Record Section Change");
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            //DLog(@"ADD New Section At Index: %lu", (unsigned long)sectionIndex);
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            DLog(@"Delete Section: %lu", (unsigned long)sectionIndex);
            change[@(type)] = @(sectionIndex);
            break;
        default:
            break;
    }
    
    [sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    NSLog(@"Process III: Record Cell Change");
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            NSLog(@"Insert Cell At Section: %ld Index: %ld", (long)newIndexPath.section, (long)newIndexPath.item);
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"Delete Cell At Section: %ld Index: %ld", (long)newIndexPath.section, (long)newIndexPath.item);
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"Update Cell At Section: %ld Index: %ld", (long)newIndexPath.section, (long)newIndexPath.item);
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"Move Cell From S%ldI%ld To S%ldI%ld", (long)indexPath.section, (long)indexPath.item, (long)newIndexPath.section, (long)newIndexPath.item);
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"Process IV: Batch Update");
    if ([sectionChanges count] > 0)
    {
        NSDictionary *firstJob = sectionChanges[0];
        NSNumber * changeTypeNumber = (NSNumber *)firstJob.allKeys[0];
        NSFetchedResultsChangeType changeType = [changeTypeNumber unsignedIntegerValue];
        
        switch (changeType) {
            case NSFetchedResultsChangeDelete:{
                DLog(@"Section Change Type: Delete Section");
                for (NSDictionary *change in sectionChanges) {
                    NSNumber * section = (NSNumber *)[change objectForKey:@(NSFetchedResultsChangeDelete)];
                    //DLog(@"section: %@", section);
                    NSUInteger itemNumberInSection = [self.collectionView numberOfItemsInSection:[section unsignedIntegerValue]];
                    //DLog(@"Item Number: %d", itemNumberInSection);
                    for (NSUInteger i = 0; i < itemNumberInSection; i++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:[section unsignedIntegerValue]];
                        NSDictionary *deletedItemInfo = @{@(NSFetchedResultsChangeDelete):indexPath};
                        [objectChanges removeObject:deletedItemInfo];
                    }
                }
                if (objectChanges.count > 0) {
                    self.blendBatchUpdateMode = YES;
                    DLog(@"Blend Change");
                }else{
                    self.blendBatchUpdateMode = NO;
                    DLog(@"Regular Change");
                }
                break;
            }
            case NSFetchedResultsChangeInsert:
                DLog(@"Section Change Type: Insert Section. Ignored.");
                break;
            case NSFetchedResultsChangeUpdate:
                DLog(@"Section Change Type: Insert Section. Ignored.");
                break;
            case NSFetchedResultsChangeMove:
                DLog(@"Section Change Type: Insert Section. Ignored.");
                break;
            default:
                DLog(@"Impossible");
                break;
        }
    }
    
    if (self.blendBatchUpdateMode)
    {
        [self blendBatchUpdate];
    }else{
        if (sectionChanges.count > 0) {
            DLog(@"Regular Update Section");
            [self batchUpdateSection];
        }
        
        if (objectChanges.count > 0 && sectionChanges.count == 0) {
            DLog(@"Regular Update Content");
            [self batchUpdateCell];
        }
        
        [sectionChanges removeAllObjects];
        [objectChanges removeAllObjects];
    }
    
}

- (void)batchUpdateSection
{
    [self.collectionView performBatchUpdates:^{
        for (NSDictionary *change in sectionChanges)
        {
            [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        DLog(@"ADD Section: %lu", (unsigned long)[obj unsignedIntegerValue]);
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        DLog(@"Delete Section: %lu", (unsigned long)[obj unsignedIntegerValue]);
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        DLog(@"Update Section: %lu", (unsigned long)[obj unsignedIntegerValue]);
                        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeMove:
                        DLog(@"MOVE Section. NOT FINISHED NOW.");
                        break;
                }
            }];
        }
    } completion:nil];
}

- (void)batchUpdateCell
{
    /*
     if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
     // This is to prevent a bug in UICollectionView from occurring.
     // The bug presents itself when inserting the first object or deleting the last object in a collection view.
     // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
     // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
     // http://openradar.appspot.com/12954582
     [self.collectionView reloadData];
     }
     */
    
    [self.collectionView performBatchUpdates:^{
        for (NSDictionary *change in objectChanges)
        {
            [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        DLog(@"ADD CELL AT %@", (NSIndexPath *)obj);
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        DLog(@"Delete Cell AT %@", (NSIndexPath *)obj);
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        break;
                }
            }];
        }
    } completion:nil];
}

- (void)blendBatchUpdate
{
    [self.collectionView performBatchUpdates:^{
        DLog(@"BlendBatchUpdate:");
        DLog(@"First: objectChanges: %@", objectChanges);
        for (NSDictionary *change in objectChanges) {
            DLog(@"object change: %@", change);
            [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        DLog(@"Blend update: ADD CELL");
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        DLog(@"Blend update: Delete CELL");
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        DLog(@"Blend update: Update Cell");
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        break;
                }
            }];
        }
        
        DLog(@"Then SectionChanges: %@", sectionChanges);
        for (NSDictionary *sectionChange in sectionChanges)
        {
            DLog(@"Section Change: %@", sectionChange);
            [sectionChange enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        DLog(@"Blend update: ADD New Section");
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        DLog(@"xxxBlend update: Delete Section %lu", (unsigned long)[obj unsignedIntegerValue]);
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        DLog(@"Blend update: Update Section %lu", (unsigned long)[obj unsignedIntegerValue]);
                        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    default:
                        break;
                }
            }];
        }
    }completion:^(BOOL finished){
        self.blendBatchUpdateMode = NO;
        [sectionChanges removeAllObjects];
        [objectChanges removeAllObjects];
    }];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in objectChanges) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }
    
    return shouldReload;
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.faceFetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDEAvatorCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.layer.cornerRadius = cell.avatorCornerRadius;
    
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    UIImage *avatorImage = (UIImage *)[self.imageCache objectForKey:faceItem.storeFileName];
    if (avatorImage) {
        cell.avatorView.image = avatorImage;
    }else{
        //NSLog(@"No Cache for cell at %@", indexPath);
        __weak SDEAvatorCell *weakCellSelf = cell;
        NSString *cacheKey = faceItem.storeFileName;
        [self fetchImageForCacheKey:cacheKey WithIndexPath:indexPath completionHandler:^(){
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImage *cachedImage = (UIImage *)[self.imageCache objectForKey:cacheKey];
                weakCellSelf.avatorView.image = cachedImage;
            });
            
        }];
        
    }
    
    //cell.order.hidden = YES;
    cell.order.text = [NSString stringWithFormat:@"%ld", (long)indexPath.section];
    return cell;
}

//原来的方法通过 IndexPath来定位需要读取的头像文件时，会出现一个问题，当你新建人物后，界面会跳转至该人物处，可能会有部分 cell 还没有出现过，这时候就会去显示该 cell 的内容，这时候该 cell 的位置相对于原来已经变化了，这时候传递的 IndexPath 是不对的，于是fetch 越界。从程序设计的角度来讲，缓存的键更改为头像文件的文件名更好，缓存的 UIImage不会因为 indexpath 变化而失效，这样是对的，同样，异步读取时也应该传递文件名而不是对应的索引位置，这样也避免了重复 fetch Face。问题的原因是，新建人物后界面跳转，这时候获取的索引位置还是原来的，这应该是是 CoreData内部的机制导致的问题。这样说来，下面备选的索引参数其实是没有必要的，因为这时候依然是错误的，没有意义。无解。
- (void)fetchImageForCacheKey:(NSString *)cacheKey WithIndexPath:(NSIndexPath *)indexPath completionHandler:(void(^)(void))Handler
{
    dispatch_async(self.imageLoadQueue, ^{
        NSString *imagePath = [self.storeDirectory stringByAppendingPathComponent:cacheKey];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        if (image) {
            UIGraphicsBeginImageContext(CGSizeMake(100.0f, 100.0f));
            [image drawInRect:CGRectMake(0, 0, 100.0f, 100.0f)];
            UIImage *thubnailImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [self.imageCache setObject:thubnailImage forKey:cacheKey];
        }else{
            NSLog(@"Read Image File Error");
            if (indexPath) {
                Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
                image = faceItem.avatorImage;
                UIGraphicsBeginImageContext(CGSizeMake(100.0f, 100.0f));
                [image drawInRect:CGRectMake(0, 0, 100.0f, 100.0f)];
                UIImage *thubnailImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                [self.imageCache setObject:thubnailImage forKey:cacheKey];
            }
        }
        
        Handler();
    });
}


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"%@ %@", NSStringFromSelector(_cmd), indexPath);
    SDEPersonProfileHeaderView *personProfileHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PersonProfile" forIndexPath:indexPath];
    //NSLog(@"%@", personProfileHeaderView);
    if (personProfileHeaderView == nil) {
        NSLog(@"Create HeaderView");
        personProfileHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PersonProfile" forIndexPath:indexPath];
        [self.headerViewCache setObject:personProfileHeaderView forKey:indexPath];
    }

    personProfileHeaderView.collectionView = collectionView;
    personProfileHeaderView.delegate = (id<SDEUICollectionSupplementaryViewDelegate>)collectionView.delegate;
    NSInteger number = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    if (number == 1) {
        personProfileHeaderView.numberLabel.text = @"1 avator";
    }else
        personProfileHeaderView.numberLabel.text = [NSString stringWithFormat:@"%ld avators", (long)number];
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    
    //there is a stupid issue, whatever I do, cocoa can't diff first header with other header.
    if (indexPath.section == 0 && faceItem.section == 0) {
        personProfileHeaderView.nameTextField.text = @"FacelessMan";
        personProfileHeaderView.nameTextField.enabled = NO;
        [personProfileHeaderView.avatorImageView setImage:[UIImage imageNamed:@"centerButton.png"]];
    }else{
        personProfileHeaderView.nameTextField.enabled = YES;
        personProfileHeaderView.actionButton.hidden = NO;
        Person *personItem = faceItem.personOwner;
        if (personItem) {
            //[personProfileHeaderView.avatorImageView setImage:personItem.avatorImage];
            if (personItem.name && personItem.name.length > 0) {
                personProfileHeaderView.nameTextField.text = personItem.name;
            }
        }
    }
    
    return personProfileHeaderView;
}

- (void)removeCachedImageWithKey:(id)key
{
    [self.imageCache removeObjectForKey:key];
}

- (void)removeAllCachedImages
{
    [self.imageCache removeAllObjects];
}
@end
