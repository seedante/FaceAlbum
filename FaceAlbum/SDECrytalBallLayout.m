//
//  SDECrytalBallLayout.m
//  FaceAlbum
//
//  Created by seedante on 12/31/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDECrytalBallLayout.h"

static CGFloat const kItemSizeWidth = 100.0f;
static CGFloat const kItemSizeHeight = 100.0f;

@interface SDECrytalBallLayout ()
@property (nonatomic, assign) NSInteger cellCount;
@property (nonatomic) NSMutableArray *layoutDataArray;
@property (nonatomic, assign) CGPoint appearPoint;

//@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
//@property (nonatomic, weak) UIGravityBehavior *gravityBehaviour;
//@property (nonatomic, weak) UICollisionBehavior *collisionBehaviour;

@end

@implementation SDECrytalBallLayout

- (id)init
{
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.itemSize = (CGSize){100, 100};
        self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.minimumLineSpacing = 20.0;
        self.minimumInteritemSpacing = 30.0;
        self.layoutDataArray = [NSMutableArray new];
        
    }
    
    return self;
}

- (CGSize)collectionViewContentSize
{
    return self.collectionView.bounds.size;
}

- (void)prepareLayout
{
    NSLog(@"prepareLayout");
    self.cellCount = [self.collectionView numberOfItemsInSection:0];
    self.appearPoint = CGPointMake(self.collectionView.bounds.size.width/2, self.collectionView.bounds.size.width/2);
    NSLog(@"cellCount: %ld", (long)self.cellCount);
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSLog(@"Ask for LayoutAttributes in Rect");
    
    if (self.layoutDataArray.count == 0) {
        for (NSUInteger i=0; i<self.cellCount; ++i)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
            if (CGRectIntersectsRect(attr.frame, rect)) {
                [self.layoutDataArray addObject:attr];
            }
        }
    }else{
        if (self.layoutDataArray.count < self.cellCount) {
            //NSLog(@"calculate new item layout attributes");
            for (NSUInteger j=self.layoutDataArray.count; j<self.cellCount; j++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:0];
                UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
                [self.layoutDataArray addObject:attributes];
            }
        }else if (self.layoutDataArray.count > self.cellCount){
            //NSLog(@"previous count: %lu new count: %ld", (unsigned long)self.layoutDataArray.count, (long)self.cellCount);
            NSInteger length = self.layoutDataArray.count - self.cellCount;

            NSRange deleteRange;
            deleteRange.location = 0;
            deleteRange.length = length;
            [self.layoutDataArray removeObjectsInRange:deleteRange];
            
            NSArray *attributesArray = [self.layoutDataArray copy];
            [self.layoutDataArray removeAllObjects];
            
            for (NSInteger i = 0; i<attributesArray.count; i++) {
                UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                attributes.center = [(UICollectionViewLayoutAttributes *)attributesArray[i] center];
                [self.layoutDataArray addObject:attributes];
            }
            
        }else
            NSLog(@"It can't be impossible.");
    }
    
    return self.layoutDataArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"layout for %@", indexPath);
    UICollectionViewLayoutAttributes *atttibutes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    int width = self.collectionView.bounds.size.width;
    int height = self.collectionView.bounds.size.height;
    
    CGFloat randomWidth =  arc4random() % width;
    CGFloat randomHeight = arc4random() % height;
    if (randomWidth < kItemSizeWidth) {
        randomWidth += kItemSizeWidth;
    }else if (randomWidth > self.collectionView.bounds.size.width - kItemSizeWidth){
        randomWidth -= kItemSizeWidth;
    }
    
    if (randomHeight > self.collectionView.bounds.size.height - kItemSizeHeight) {
        randomHeight -= kItemSizeHeight;
    }else if (randomHeight < kItemSizeHeight){
        randomHeight += kItemSizeHeight;
    }
    
    atttibutes.center = CGPointMake(randomWidth, randomHeight);
    atttibutes.size = CGSizeMake(100, 100);
    return atttibutes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    attributes.center = self.appearPoint;
    
    return attributes;
}

@end
