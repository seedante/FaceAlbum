//
//  HorizontalCollectionViewLayout.m
//  Face Album
//
//  Created by seedante on 11/20/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "HorizontalCollectionViewLayout.h"

#define ITEM_SIZE 150.0

@interface HorizontalCollectionViewLayout ()

@property (nonatomic, assign) NSInteger cellCount;
@property (nonatomic, assign) CGSize boundsSize;
@property (nonatomic, assign) CGFloat interItemSpace; //Horizontal space;
@property (nonatomic, assign) CGFloat lineSpace;  //Vertival spcae;
@property (nonatomic, assign) NSInteger verticalItemsCount;// (NSInteger)floorf(bounds.size.height / itemSize.height);
@property (nonatomic, assign) NSInteger horizontalItemsCount; // (NSInteger)floorf(bounds.size.width / itemSize.width);

@end

@implementation HorizontalCollectionViewLayout


- (id)init
{
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.itemSize = (CGSize){ITEM_SIZE, ITEM_SIZE};
        self.sectionInset = UIEdgeInsetsMake(60, 62, 0, 62);
        self.minimumLineSpacing = 20.0;
        self.minimumInteritemSpacing = 30.0;
    }
    
    return self;
}

- (void)prepareLayout
{
    // Get the number of cells and the bounds size
    NSLog(@"Calculate layout");
    self.cellCount = [self.collectionView numberOfItemsInSection:0];
    self.boundsSize = self.collectionView.bounds.size;
    NSLog(@"BoundsSize: %fx%f", self.boundsSize.width, self.boundsSize.height);
    
    id<UICollectionViewDelegateFlowLayout>delegateFlowLayout =  (id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate;
    if ([delegateFlowLayout respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        self.sectionInset = [delegateFlowLayout collectionView:nil layout:nil insetForSectionAtIndex:0];
    }
    
    if ([delegateFlowLayout respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        self.itemSize = [delegateFlowLayout collectionView:nil layout:nil sizeForItemAtIndexPath:nil];
    }
    
    if ([delegateFlowLayout respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        self.minimumInteritemSpacing = [delegateFlowLayout collectionView:nil layout:nil minimumInteritemSpacingForSectionAtIndex:0];
    }
    
    if ([delegateFlowLayout respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        self.minimumLineSpacing = [delegateFlowLayout collectionView:nil layout:nil minimumLineSpacingForSectionAtIndex:0];
    }
    //NSLog(@"%ld", (NSInteger)floorf(-1.5));
    self.horizontalItemsCount = (NSInteger)floorf((self.boundsSize.width - self.sectionInset.left - self.sectionInset.right)/(self.itemSize.width + self.minimumInteritemSpacing));
    self.verticalItemsCount = (NSInteger)floorf((self.boundsSize.height - self.sectionInset.top - self.sectionInset.bottom )/(self.itemSize.height + self.minimumLineSpacing));
    
    CGFloat HorizontalItemSpace = 0.0f;
    if (self.horizontalItemsCount != 1) {
        HorizontalItemSpace = (self.boundsSize.width - self.sectionInset.left - self.sectionInset.right  - self.horizontalItemsCount * self.itemSize.width)/(self.horizontalItemsCount + 1);
    }
    CGFloat VerticalItemSpace = 0.0f;
    if (self.verticalItemsCount != 1) {
        VerticalItemSpace = (self.boundsSize.height - self.sectionInset.top - self.sectionInset.bottom  - self.verticalItemsCount * self.itemSize.height)/(self.verticalItemsCount + 1);
    }
    
    self.interItemSpace = HorizontalItemSpace > self.minimumInteritemSpacing?HorizontalItemSpace:self.minimumInteritemSpacing;
    self.lineSpace = VerticalItemSpace > self.minimumLineSpacing?VerticalItemSpace:self.minimumLineSpacing;
    
}

- (CGSize)collectionViewContentSize
{
    // We should return the content size. Lets do some math:
    /*
    NSInteger verticalItemsCount = (NSInteger)floorf(_boundsSize.height / _itemSize.height);
    NSInteger horizontalItemsCount = (NSInteger)floorf(_boundsSize.width / _itemSize.width);
    
    NSInteger itemsPerPage = verticalItemsCount * horizontalItemsCount;
    NSInteger numberOfItems = _cellCount;
    NSInteger numberOfPages = (NSInteger)ceilf((CGFloat)numberOfItems / (CGFloat)itemsPerPage);
    
    CGSize size = _boundsSize;
    size.width = numberOfPages * _boundsSize.width;
    return size;
     */
    NSInteger itemsPerPage = self.horizontalItemsCount * self.verticalItemsCount;
    CGFloat height = self.collectionView.bounds.size.height;
    NSUInteger pageNumber = [self.collectionView numberOfItemsInSection:0]/itemsPerPage + 1;
    CGFloat width = pageNumber * self.collectionView.bounds.size.width;
    NSLog(@"Content width: %f == %lu pages", width, (unsigned long)pageNumber);
    return CGSizeMake(width, height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // This method requires to return the attributes of those cells that intsersect with the given rect.
    // In this implementation we just return all the attributes.
    // In a better implementation we could compute only those attributes that intersect with the given rect.
    
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:_cellCount];
    
    for (NSUInteger i=0; i<self.cellCount; ++i)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
        
        [allAttributes addObject:attr];
    }
    
    return allAttributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    //CGRect bounds = self.collectionView.bounds;
    CGSize itemSize = self.itemSize;
    
    // Get some info:
    //NSInteger verticalItemsCount = 4;// (NSInteger)floorf(bounds.size.height / itemSize.height);
    //NSInteger horizontalItemsCount = 5;// (NSInteger)floorf(bounds.size.width / itemSize.width);
    NSInteger itemsPerPage = self.verticalItemsCount * self.horizontalItemsCount;
    
    // Compute the column & row position, as well as the page of the cell.
    NSInteger columnPosition = row%self.horizontalItemsCount;
    NSInteger rowPosition = (row/self.horizontalItemsCount)%self.verticalItemsCount;
    NSInteger itemPage = floorf(row/itemsPerPage);
    
    // Creating an empty attribute
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGRect frame = CGRectZero;
    
    // And finally, we assign the positions of the cells
    frame.origin.x = itemPage * self.boundsSize.width + columnPosition * (itemSize.width + self.interItemSpace) + self.sectionInset.left + self.interItemSpace;
    frame.origin.y = rowPosition * (itemSize.height + self.lineSpace) + self.sectionInset.top + self.lineSpace;
    frame.size = self.itemSize;
    
    attr.frame = frame;
    
    return attr;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    // We should do some math here, but we are lazy.
    return NO;
}


@end
