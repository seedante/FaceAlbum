//
//  SDCollectionViewDataSource.h
//  FaceAlbum
//
//  Created by seedante on 14-7-23.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDEReorderableCollectionViewFlowLayout.h"

@interface SDEMRVCDataSource : NSObject<UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

+ (instancetype)sharedDataSource;

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;

@end
