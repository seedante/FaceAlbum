//
//  SDEPortraitLayout.m
//  FaceAlbum
//
//  Created by seedante on 9/1/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPortraitLayout.h"

#define ITEM_SIZE_WIDTH 300.0
#define ITEM_SIZE_HEIGHT 300.0

@implementation SDEPortraitLayout

-(id)init
{
    self = [super init];
    CGRect frame = [[UIScreen mainScreen] bounds];
    if (self) {
        self.itemSize = CGSizeMake(ITEM_SIZE_WIDTH, ITEM_SIZE_HEIGHT);
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sectionInset = UIEdgeInsetsMake(200, frame.size.width/2.0, 200, frame.size.width/2.0);
        self.minimumLineSpacing = 50.0;
        self.minimumInteritemSpacing = 30.0;
    }
    return self;
}

- (void)transformToPortraitLayOut
{
    self.itemSize = CGSizeMake(ITEM_SIZE_WIDTH, ITEM_SIZE_HEIGHT);
    self.sectionInset = UIEdgeInsetsMake(200, 20, 200, 20);
    self.minimumInteritemSpacing = 30.0;
}

- (void)transformToHorizontalGridLayout
{
    self.itemSize = CGSizeMake(150.0, 150.0);
    self.sectionInset = UIEdgeInsetsMake(40.0, 20.0, 40.0, 20.0);
    self.minimumInteritemSpacing = 20.0;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}
@end
