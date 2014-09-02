//
//  SDEPAVCDataSource.m
//  FaceAlbum
//
//  Created by seedante on 14-8-10.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEPAVCDataSource.h"
#import "Store.h"

typedef enum: NSUInteger{
    ProtraitLayout,
    HorizontalGridLayout
} LayoutType;

@interface SDEPAVCDataSource ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation SDEPAVCDataSource

+ (instancetype)sharedDataSource{
    static SDEPAVCDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEPAVCDataSource alloc]init];
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

- (NSFetchedResultsController *)personFetchedResultsController
{
    if (_personFetchedResultsController != nil) {
        return _personFetchedResultsController;
    }
    
    _personFetchedResultsController = [[Store sharedStore] personFetchedResultsController];
    _personFetchedResultsController.delegate = self;
    
    return _personFetchedResultsController;
}

#pragma mark - UICollectionView Data Source
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *portraitCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PortraitCell" forIndexPath:indexPath];
    
    return portraitCell;
}



@end
