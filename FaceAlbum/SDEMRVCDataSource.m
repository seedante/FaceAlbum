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
#import "AvatorCell.h"
#import "SDEPersonProfileHeader.h"

static NSString * const cellIdentifier = @"avatorCell";

@interface SDEMRVCDataSource ()
{
    NSMutableArray *sectionChange;
    NSMutableArray *objectChange;
}

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation SDEMRVCDataSource

- (instancetype)init
{
    self = [super init];
    sectionChange = [[NSMutableArray alloc] init];
    objectChange = [[NSMutableArray alloc] init];
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
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Face"];
    [fetchRequest setFetchBatchSize:100];
    
    NSSortDescriptor *SectionOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *ItemOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:@[SectionOrderDescriptor, ItemOrderDescriptor]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whetherToDisplay == YES"];
    [fetchRequest setPredicate:predicate];
    
    _faceFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"allFaces"];
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
    
    [sectionChange addObject:change];
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
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            NSLog(@"Move Cell From S%dI%d To S%dI%d", indexPath.section, indexPath.item, newIndexPath.section, newIndexPath.item);
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [objectChange addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"Process IV: Batch Update");
    //NSLog(@"Section change: %@", sectionChange);
    //NSLog(@"Content Change: %@", objectChange);
    if ([sectionChange count] > 0)
    {
        //[self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView performBatchUpdates:^{
            for (NSDictionary *change in sectionChange)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            NSLog(@"ADD Person");
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:^(BOOL finished){
            [self.collectionView.collectionViewLayout invalidateLayout];
        }];
        
    }
    
    if ([objectChange count] > 0 )
    {
        NSLog(@"Update Content");
        if ([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.collectionView reloadData];
        }
        if (YES) {
            //NSLog(@"UPDATE SCREEN");
            [self.collectionView performBatchUpdates:^{
                for (NSDictionary *change in objectChange)
                {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch (type)
                        {
                            case NSFetchedResultsChangeInsert:
                                NSLog(@"ADD CELL");
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                NSLog(@"Delete CELL");
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
    }
    
    [sectionChange removeAllObjects];
    [objectChange removeAllObjects];
    
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in objectChange) {
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


#pragma mark - LXReorderableCollectionViewDataSource
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;
{
    if ([fromIndexPath isEqual:toIndexPath]) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    Face *movedFace = [self.faceFetchedResultsController objectAtIndexPath:fromIndexPath];
    
    double lowerBound = 0.0;
    double upperBound = 0.0;
    double newOrder = 0.0;
    
    if (toIndexPath.section == fromIndexPath.section) {
        if (toIndexPath.item < fromIndexPath.item) {
            if (toIndexPath.item > 0) {
                lowerBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item - 1 inSection:toIndexPath.section]] order];
                NSLog(@"lowerBound: %f", lowerBound);
            }else{
                lowerBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:toIndexPath.section]] order] - 2.0;
                NSLog(@"lowerBound: %f", lowerBound);
            }
            
            if (toIndexPath.item < [self collectionView:collectionView numberOfItemsInSection:toIndexPath.section]-1) {
                upperBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item inSection:toIndexPath.section]] order];
                NSLog(@"upperBound: %f", upperBound);
            }else{
                upperBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item - 1 inSection:toIndexPath.section]] order] + 2.0;
                NSLog(@"upperBound: %f", upperBound);
            }
            
            newOrder = (lowerBound + upperBound)/2.0;
            NSLog(@"New Order:%f", newOrder);
        }else{
            lowerBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item inSection:toIndexPath.section]] order];
            NSLog(@"lowerBound: %f", lowerBound);
            
            
            id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:toIndexPath.section];
            NSUInteger number = [sectionInfo numberOfObjects];
            if (toIndexPath.item < number - 1) {
                upperBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item + 1 inSection:toIndexPath.section]] order];
                NSLog(@"upperBound: %f", upperBound);
            }else{
                upperBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item - 1 inSection:toIndexPath.section]] order] + 2.0;
                NSLog(@"upperBound: %f", upperBound);
            }
            
            newOrder = (lowerBound + upperBound)/2.0;
            NSLog(@"New Order:%f", newOrder);
        }
        
        movedFace.order = newOrder;
    }else{
        Face *toItem = [self.faceFetchedResultsController objectAtIndexPath:toIndexPath];
        
        if (toIndexPath.item == 0) {
            newOrder = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:toIndexPath.section]] order] - 1;
        }else{
            lowerBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item - 1 inSection:toIndexPath.section]] order];
            upperBound = [(Face *)[self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:toIndexPath.item inSection:toIndexPath.section]] order];
            newOrder = (lowerBound + upperBound)/2.0;
        }
        
        movedFace.section = toItem.section;
        movedFace.order = newOrder;
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    NSLog(@"Cell Remove Finish.");
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSLog(@"Section Number: %d", [[self.faceFetchedResultsController sections] count]);
    return [[self.faceFetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:section];
    NSLog(@"cell number: %d in section: %d", [sectionInfo numberOfObjects], section+1);
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AvatorCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.layer.cornerRadius = cell.avatorCornerRadius;
    cell.clipsToBounds = YES;
    Face *face = [self.faceFetchedResultsController objectAtIndexPath:indexPath];
    UIImage *headImage = face.avatorImage;
    [cell.avatorView setImage:headImage];
    
    cell.order.text = [NSString stringWithFormat:@"%.2f", face.order];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    SDEPersonProfileHeader *personProfile = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PersonProfile" forIndexPath:indexPath];
    
    return personProfile;
}


@end
