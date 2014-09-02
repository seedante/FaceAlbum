//
//  SDEGridLayout.m
//  FaceAlbum
//
//  Created by seedante on 9/1/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEHorizontalGridLayout.h"

#define ITEM_SIZE_WIDTH 150.0
#define ITEM_SIZE_HEIGHT 150.0

@implementation SDEHorizontalGridLayout

-(id)init
{
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(ITEM_SIZE_WIDTH, ITEM_SIZE_HEIGHT);
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.sectionInset = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
        self.minimumLineSpacing = 20.0;
        self.minimumInteritemSpacing = 15.0;
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end
