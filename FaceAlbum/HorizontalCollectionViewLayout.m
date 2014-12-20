//
//  HorizontalCollectionViewLayout.m
//  Face Album
//
//  Created by seedante on 11/20/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "HorizontalCollectionViewLayout.h"

static CGFloat const kItemSize = 150.0f;

@interface HorizontalCollectionViewLayout ()

@property (nonatomic, assign) NSInteger cellCount;
@property (nonatomic, assign) CGSize boundsSize;
@property (nonatomic, assign) CGFloat interItemSpace; //Horizontal space;
@property (nonatomic, assign) CGFloat lineSpace;  //Vertival spcae;
@property (nonatomic, assign) NSInteger verticalItemsCount;// (NSInteger)floorf(bounds.size.height / itemSize.height);
@property (nonatomic, assign) NSInteger horizontalItemsCount; // (NSInteger)floorf(bounds.size.width / itemSize.width);

@property (nonatomic) NSArray *visibleItemIndexPath;
@property (nonatomic) CGPoint assemblePoint;
@property (nonatomic, assign) CGFloat scale;

@property (nonatomic) NSMutableDictionary *originalLayoutData;

@end

@implementation HorizontalCollectionViewLayout


- (id)init
{
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.itemSize = (CGSize){kItemSize, kItemSize};
        self.sectionInset = UIEdgeInsetsMake(60, 62, 0, 62);
        self.minimumLineSpacing = 20.0;
        self.minimumInteritemSpacing = 30.0;
        self.originalLayoutData = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)prepareLayout
{
    // Get the number of cells and the bounds size
    //NSLog(@"Calculate layout");
    self.cellCount = [self.collectionView numberOfItemsInSection:0];
    self.boundsSize = self.collectionView.bounds.size;
    //NSLog(@"BoundsSize: %fx%f", self.boundsSize.width, self.boundsSize.height);
    
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
    if (self.horizontalItemsCount > 5) {
        self.horizontalItemsCount = 5;
    }
    self.verticalItemsCount = (NSInteger)floorf((self.boundsSize.height - self.sectionInset.top - self.sectionInset.bottom )/(self.itemSize.height + self.minimumLineSpacing));
    if (self.verticalItemsCount > 4) {
        self.verticalItemsCount = 4;
    }
    
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
    //NSLog(@"Content width: %f == %lu pages", width, (unsigned long)pageNumber);
    return CGSizeMake(width, height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // This method requires to return the attributes of those cells that intsersect with the given rect.
    // In this implementation we just return all the attributes.
    // In a better implementation we could compute only those attributes that intersect with the given rect.
    
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.cellCount];
    
    for (NSUInteger i=0; i<self.cellCount; ++i)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
        if (CGRectIntersectsRect(attr.frame, rect)) {
            [allAttributes addObject:attr];
        }
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
    
    CGPoint center;
    // And finally, we assign the positions of the cells
    center.x = itemPage * self.boundsSize.width + columnPosition * (itemSize.width + self.interItemSpace) + self.sectionInset.left + self.interItemSpace + self.itemSize.width/2.0;
    center.y = rowPosition * (itemSize.height + self.lineSpace) + self.sectionInset.top + self.lineSpace + self.itemSize.height/2.0;
    
    attr.size = self.itemSize;
    attr.center = center;
    if ([self.originalLayoutData objectForKey:indexPath] == nil) {
        [self.originalLayoutData setObject:attr forKey:indexPath];
    }
    
    if (self.visibleItemIndexPath) {
        if ([self.visibleItemIndexPath containsObject:indexPath]) {
            CGPoint location = [self calculateLocationWithAssemblePoint:self.assemblePoint OriginalPoint:center Scale:self.scale];
            attr.center = location;
        }
    }
    
    return attr;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    if (!CGSizeEqualToSize(oldBounds.size, newBounds.size)) {
        return YES;
    }
    
    return NO;
}

- (void)relocateVisibleItems:(NSArray *)indexPaths withAssemblePosition:(CGPoint)center Scale:(CGFloat)scale
{
    self.visibleItemIndexPath = indexPaths;
    self.assemblePoint = center;
    self.scale = scale;
}

- (void)resetVisibleItems
{
    self.visibleItemIndexPath = nil;
    self.assemblePoint = CGPointZero;
    self.scale = 0.0f;
}

- (CGPoint)calculateLocationWithAssemblePoint:(CGPoint)assemblePoint OriginalPoint:(CGPoint)originalPoint Scale:(CGFloat)scale
{
    CGFloat gestureScale = scale;
    if (gestureScale >= 1.0) {
        return originalPoint;
    }

    CGPoint location = CGPointZero;
    CGFloat distance_x = fabsf(assemblePoint.x - originalPoint.x);
    CGFloat distance_y = fabsf(assemblePoint.y - originalPoint.y);
    
    if (assemblePoint.x >= originalPoint.x) {
        location.x = assemblePoint.x - distance_x * gestureScale;
    }else
        location.x = assemblePoint.x + distance_x * gestureScale;
    
    if (assemblePoint.y >= originalPoint.y) {
        location.y = assemblePoint.y - distance_y * gestureScale;
    }else
        location.y = assemblePoint.y + distance_y * gestureScale;
    
    return location;
}

- (UICollectionViewLayoutAttributes *)originalLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.originalLayoutData objectForKey:indexPath];
}

- (void)cleanBackupLayoutData
{
    [self.originalLayoutData removeAllObjects];
}

@end
