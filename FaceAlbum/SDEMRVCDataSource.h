//
//  SDCollectionViewDataSource.h
//  FaceAlbum
//
//  Created by seedante on 14-7-23.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDEReorderableCollectionViewFlowLayout.h"
#ifdef DEBUG_MODE
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

@interface SDEMRVCDataSource : NSObject<UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

+ (instancetype)sharedDataSource;

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic) NSFetchedResultsController *faceFetchedResultsController;

@end
