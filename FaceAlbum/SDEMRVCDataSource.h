//
//  SDCollectionViewDataSource.h
//  FaceAlbum
//
//  Created by seedante on 14-7-23.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LXReorderableCollectionViewFlowLayout.h"

@interface SDEMRVCDataSource : NSObject<LXReorderableCollectionViewDataSource, NSFetchedResultsControllerDelegate>

+ (instancetype)sharedDataSource;

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;

@end
