//
//  SDEPAVCDataSource.h
//  FaceAlbum
//
//  Created by seedante on 14-8-10.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDEPAVCDataSource : NSObject<UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;
@property (nonatomic) NSFetchedResultsController *personFetchedResultsController;

+ (instancetype)sharedDataSource;

@end
