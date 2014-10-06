//
//  SDEPageViewLayout.m
//  FaceAlbum
//
//  Created by seedante on 10/5/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPageViewLayout.h"

#define ITEM_SIZE_WIDTH 150.0
#define ITEM_SIZE_HEIGHT 150.0

@implementation SDEPageViewLayout


- (id)init
{
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(ITEM_SIZE_WIDTH, ITEM_SIZE_HEIGHT);
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.sectionInset = UIEdgeInsetsMake(0, 60, 0, 60);
        self.minimumInteritemSpacing = 20.0f;
        self.minimumLineSpacing = 5.0f;
    }
    
    return self;
}

@end
