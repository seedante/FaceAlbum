//
//  SDCollectionViewDataSource.m
//  LayoutSample
//
//  Created by seedante on 14-7-31.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEFaceVCDataSource.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoCell.h"
#import "FaceCell.h"
#import "PhotoScanManager.h"
#import <QuartzCore/QuartzCore.h>

static NSString *cellIdentifier = @"faceCell";

@interface SDEFaceVCDataSource ()

@property (nonatomic)NSMutableArray *showFaces;

@end

@implementation SDEFaceVCDataSource

+ (instancetype)sharedDataSource{
    static SDEFaceVCDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEFaceVCDataSource alloc]init];
    });
    return sharedInstance;
}

- (NSArray *)allFaces
{
    return [self.showFaces copy];
}

- (NSMutableArray *)showFaces
{
    if (_showFaces != nil) {
        return _showFaces;
    }
    _showFaces = [[NSMutableArray alloc] init];
    return _showFaces;
}

- (NSUInteger)numberOfFace
{
    return self.showFaces.count;
}

- (void)addFaces:(NSArray *)array
{
    [self.showFaces addObjectsFromArray:array];
}

- (void)removeAllFaces
{
    if (self.showFaces.count > 0) {
        [self.showFaces removeAllObjects];
    }
}

- (void)removeFirstFace
{
    if (self.showFaces.count > 0) {
        [self.showFaces removeObjectAtIndex:0];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (self.showFaces.count == 0) {
        return 0;
    }else
        return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.showFaces count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FaceCell *faceCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    faceCell.layer.cornerRadius = faceCell.faceViewCornerRadius;
    faceCell.clipsToBounds = YES;
    
    faceCell.faceView.image = self.showFaces[indexPath.item];
    
    return faceCell;
}


@end
