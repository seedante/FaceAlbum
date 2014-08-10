//
//  SDCollectionViewDataSource.h
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDEFaceVCDataSource : NSObject<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, weak) UICollectionView *collectionView;

+ (instancetype)sharedDataSource;
- (NSArray *)allFaces;
- (NSUInteger)numberOfFace;
- (void)addFaces:(NSArray *)array;
- (void)removeAllFaces;
- (void)removeFirstFace;

@end
