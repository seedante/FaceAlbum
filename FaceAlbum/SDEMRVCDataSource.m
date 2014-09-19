//
//  SDCollectionViewDataSource.m
//  FaceAlbum
//
//  Created by seedante on 14-7-23.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEMRVCDataSource.h"
#import "Face.h"
#import "Person.h"
#import "Store.h"
#import "SDEAvatorCell.h"
#import "SDEPersonProfileHeaderView.h"

static NSString * const cellIdentifier = @"avatorCell";

@interface SDEMRVCDataSource ()
{
    NSMutableArray *sectionChanges;
    NSMutableArray *objectChanges;
}

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL blendBatchUpdateMode;

@end

@implementation SDEMRVCDataSource

- (instancetype)init
{
    self = [super init];
    sectionChanges = [[NSMutableArray alloc] init];
    objectChanges = [[NSMutableArray alloc] init];
    self.blendBatchUpdateMode = NO;
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
            NSLog(@"ADD New Section At Index: %d", sectionIndex);
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"Delete Section: %d", sectionIndex);
            change[@(type)] = @(sectionIndex);
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
            NSLog(@"Insert Cell At Section: %d Index: %d", newIndexPath.section, newIndexPath.item);
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"Delete Cell At Section: %d Index: %d", newIndexPath.section, newIndexPath.item);
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            NSLog(@"Update Cell At Section: %d Index: %d", newIndexPath.section, newIndexPath.item);
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"Move Cell From S%dI%d To S%dI%d", indexPath.section, indexPath.item, newIndexPath.section, newIndexPath.item);
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"Process IV: Batch Update");
    //NSLog(@"Section change: %@", sectionChanges);
    //NSLog(@"Content Change: %@", objectChanges);
    if ([sectionChanges count] > 0)
    {
        NSDictionary *firstJob = sectionChanges[0];
        NSNumber * changeTypeNumber = (NSNumber *)firstJob.allKeys[0];
        NSFetchedResultsChangeType changeType = [changeTypeNumber unsignedIntegerValue];
        
        switch (changeType) {
            case NSFetchedResultsChangeDelete:{
                NSLog(@"Section Change Type: Delete Section");
                for (NSDictionary *change in sectionChanges) {
                    NSNumber * section = (NSNumber *)[change objectForKey:@(NSFetchedResultsChangeDelete)];
                    //NSLog(@"section: %@", section);
                    NSUInteger itemNumberInSection = [self.collectionView numberOfItemsInSection:[section unsignedIntegerValue]];
                    //NSLog(@"Item Number: %d", itemNumberInSection);
                    for (NSUInteger i = 0; i < itemNumberInSection; i++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:[section unsignedIntegerValue]];
                        NSDictionary *deletedItemInfo = @{@(NSFetchedResultsChangeDelete):indexPath};
                        [objectChanges removeObject:deletedItemInfo];
                    }
                }
                if (objectChanges.count > 0) {
                    self.blendBatchUpdateMode = YES;
                    NSLog(@"Blend Change");
                }else{
                    self.blendBatchUpdateMode = NO;
                    NSLog(@"Regular Change");
                }
                break;
            }
            case NSFetchedResultsChangeInsert:
                NSLog(@"Section Change Type: Insert Section. Ignored.");
                break;
            case NSFetchedResultsChangeUpdate:
                NSLog(@"Section Change Type: Insert Section. Ignored.");
                break;
            case NSFetchedResultsChangeMove:
                NSLog(@"Section Change Type: Insert Section. Ignored.");
                break;
            default:
                NSLog(@"Impossible");
                break;
        }
    }
    //NSLog(@"Section change: %@", sectionChanges);
    //NSLog(@"Content Change: %@", objectChanges);
    
    if (self.blendBatchUpdateMode)
    {
        [self blendBatchUpdate];
    }else{
        if (sectionChanges.count > 0) {
            NSLog(@"Regular Update Section");
            [self batchUpdateSection];
        }
        
        if (objectChanges.count > 0 && sectionChanges.count == 0) {
            NSLog(@"Regular Update Content");
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
                        NSLog(@"ADD Section: %d", [obj unsignedIntegerValue]);
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        NSLog(@"Delete Section: %d", [obj unsignedIntegerValue]);
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        NSLog(@"Update Section: %d", [obj unsignedIntegerValue]);
                        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeMove:
                        NSLog(@"MOVE Section. NOT FINISHED NOW.");
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
                        NSLog(@"ADD CELL AT %@", (NSIndexPath *)obj);
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        NSLog(@"Delete Cell AT %@", (NSIndexPath *)obj);
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        NSIndexPath *fromIndex = (NSIndexPath *)obj[0];
                        NSIndexPath *toIndex = (NSIndexPath *)obj[1];
                        NSLog(@"Move Cell From Section: %d Index: %d To Section: %d Index: %d", fromIndex.section, fromIndex.item, toIndex.section, toIndex.item);
                        break;
                }
            }];
        }
    } completion:nil];
}

- (void)blendBatchUpdate
{
    [self.collectionView performBatchUpdates:^{
        NSLog(@"BlendBatchUpdate:");
        NSLog(@"First: objectChanges: %@", objectChanges);
        for (NSDictionary *change in objectChanges) {
            NSLog(@"object change: %@", change);
            [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        NSLog(@"Blend update: ADD CELL");
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        NSLog(@"Blend update: Delete CELL");
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        NSLog(@"Blend update: Update Cell");
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        NSIndexPath *fromIndex = (NSIndexPath *)obj[0];
                        NSIndexPath *toIndex = (NSIndexPath *)obj[1];
                        NSLog(@"Blend update: Move Cell From Section: %d Index: %d To Section: %d Index: %d", fromIndex.section, fromIndex.item, toIndex.section, toIndex.item);
                        break;
                }
            }];
        }
        
        NSLog(@"Then SectionChanges: %@", sectionChanges);
        for (NSDictionary *sectionChange in sectionChanges)
        {
            NSLog(@"Section Change: %@", sectionChange);
            [sectionChange enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        NSLog(@"Blend update: ADD New Section");
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        NSLog(@"xxxBlend update: Delete Section %d", [obj unsignedIntegerValue]);
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        NSLog(@"Blend update: Update Section %d", [obj unsignedIntegerValue]);
                        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
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
    NSLog(@"Section Number: %lu", (unsigned long)[[self.faceFetchedResultsController sections] count]);
    return [[self.faceFetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:section];
    //NSLog(@"cell number: %lu in section: %d", (unsigned long)[sectionInfo numberOfObjects], section+1);
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDEAvatorCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.layer.cornerRadius = cell.avatorCornerRadius;
    cell.clipsToBounds = YES;
    Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    UIImage *headImage = [UIImage imageWithContentsOfFile:face.pathForBackup];
    
    cell.avatorView.image = headImage;
    cell.order.hidden = YES;
    
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
        UIImage *headImage = face.avatorImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.avatorView setImage:headImage];
            [cell setNeedsDisplay];
        });
    });
     */

    //cell.order.text = [NSString stringWithFormat:@"%.2f", face.order];
    return cell;
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"HeaderView Indexpath: %@", indexPath);
    SDEPersonProfileHeaderView *personProfileHeaderView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PersonProfile" forIndexPath:indexPath];
    NSInteger number = [self collectionView:collectionView numberOfItemsInSection:indexPath.section];
    personProfileHeaderView.numberLabel.text = [NSString stringWithFormat:@"%d avators", number];
    //personProfileHeaderView.GoBackButton.hidden = YES;
    return personProfileHeaderView;
}

@end
