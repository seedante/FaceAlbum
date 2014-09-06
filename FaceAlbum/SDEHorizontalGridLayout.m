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

@interface SDEHorizontalGridLayout ()

@property (nonatomic, assign) CGSize boundsSize;

@end

@implementation SDEHorizontalGridLayout

-(id)init
{
    self = [super init];
    if (self) {
        //self.itemSize = CGSizeMake(ITEM_SIZE_WIDTH, ITEM_SIZE_HEIGHT);
        //self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        //self.sectionInset = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
        //self.minimumLineSpacing = 20.0;
        //self.minimumInteritemSpacing = 15.0;
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)prepareLayout
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    //self.cellCount = [self.collectionView numberOfItemsInSection:0];
    self.boundsSize = self.collectionView.bounds.size;
    NSLog(@"collectionview size: witdth-%f, height-%f", self.boundsSize.width, self.boundsSize.height);
}

- (CGSize)collectionViewContentSize
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSInteger verticalItemsCount = (NSInteger)floorf(_boundsSize.height / self.itemSize.height);
    NSInteger horizontalItemsCount = (NSInteger)floorf(_boundsSize.width / self.itemSize.width);
    
    NSInteger itemsPerPage = verticalItemsCount * horizontalItemsCount;
    NSInteger numberOfItems = _cellCount;
    NSInteger numberOfPages = (NSInteger)ceilf((CGFloat)numberOfItems / (CGFloat)itemsPerPage);
    
    CGSize size = _boundsSize;
    size.width = numberOfPages * _boundsSize.width;
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    // This method requires to return the attributes of those cells that intsersect with the given rect.
    // In this implementation we just return all the attributes.
    // In a better implementation we could compute only those attributes that intersect with the given rect.
    
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:_cellCount];
    
    for (NSUInteger i=0; i<_cellCount; ++i)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
        
        [allAttributes addObject:attr];
    }
    
    return allAttributes;
}


- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    // Here we have the magic of the layout.
    
    NSInteger row = indexPath.row;
    
    CGRect bounds = self.collectionView.bounds;
    CGSize itemSize = self.itemSize;
    
    // Get some info:
    NSInteger verticalItemsCount = (NSInteger)floorf(bounds.size.height / itemSize.height);
    NSInteger horizontalItemsCount = (NSInteger)floorf(bounds.size.width / itemSize.width);
    NSInteger itemsPerPage = verticalItemsCount * horizontalItemsCount;
    
    // Compute the column & row position, as well as the page of the cell.
    NSInteger columnPosition = row%horizontalItemsCount;
    NSInteger rowPosition = (row/horizontalItemsCount)%verticalItemsCount;
    NSInteger itemPage = floorf(row/itemsPerPage);
    
    // Creating an empty attribute
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGRect frame = CGRectZero;
    
    // And finally, we assign the positions of the cells
    frame.origin.x = itemPage * bounds.size.width + columnPosition * itemSize.width;
    frame.origin.y = rowPosition * itemSize.height;
    frame.size = self.itemSize;
    
    attr.frame = frame;
    
    return attr;
}


@end
