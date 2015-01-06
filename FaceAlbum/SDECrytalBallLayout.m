//
//  SDECrytalBallLayout.m
//  FaceAlbum
//
//  Created by seedante on 12/31/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDECrytalBallLayout.h"

//static CGFloat const kItemSizeWidth = 100.0f;
//static CGFloat const kItemSizeHeight = 100.0f;

@interface SDECrytalBallLayout ()
@property (nonatomic, assign) NSInteger cellCount;
@property (nonatomic) NSMutableArray *layoutDataArray;
@property (nonatomic, assign) CGPoint appearPoint;

@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, weak) UIGravityBehavior *gravityBehaviour;
@property (nonatomic, weak) UICollisionBehavior *collisionBehaviour;

@property (nonatomic, strong) NSMutableSet *visibleIndexPathsSet;
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
        self.visibleIndexPathsSet = [NSMutableSet set];
        
        self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
        
        UIGravityBehavior *gravityBehaviour = [[UIGravityBehavior alloc] initWithItems:@[]];
        gravityBehaviour.gravityDirection = CGVectorMake(0, -3);
        self.gravityBehaviour = gravityBehaviour;
        [self.dynamicAnimator addBehavior:gravityBehaviour];
        
        UICollisionBehavior *collisionBehaviour = [[UICollisionBehavior alloc] initWithItems:@[]];
        [collisionBehaviour setTranslatesReferenceBoundsIntoBoundaryWithInsets:UIEdgeInsetsMake(100, 100, 100, 100)];
        collisionBehaviour.translatesReferenceBoundsIntoBoundary = YES;
        [self.dynamicAnimator addBehavior:collisionBehaviour];
        self.collisionBehaviour = collisionBehaviour;
    }
    
    return self;
}

- (CGPoint)randomCenter
{
    CGPoint position;
    int heightInt = (int)self.collectionView.bounds.size.height;
    position.y = arc4random() % heightInt;
    position.x = arc4random() % 300 + 372;
    return position;
}

- (CGSize)collectionViewContentSize
{
    return self.collectionView.bounds.size;
}

- (void)prepareLayout
{
    //NSLog(@"prepareLayout");
    [super prepareLayout];
    self.cellCount = [self.collectionView numberOfItemsInSection:0];
    self.appearPoint = CGPointMake(self.collectionView.bounds.size.width/2, self.collectionView.bounds.size.width);
    //NSLog(@"cellCount: %ld", (long)self.cellCount);
    
    CGRect visibleRect = self.collectionView.bounds;
    
    if (self.layoutDataArray.count == 0) {
        for (NSUInteger i=0; i<self.cellCount; ++i)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.size = CGSizeMake(100, 100);
            attributes.center = [self randomCenter];
            if (CGRectIntersectsRect(attributes.frame, visibleRect)) {
                [self.layoutDataArray addObject:attributes];
                [self.gravityBehaviour addItem:attributes];
                [self.collisionBehaviour addItem:attributes];

            }
        }
    }else{
        if (self.layoutDataArray.count < self.cellCount) {
            //NSLog(@"calculate new item layout attributes");
            for (NSUInteger j=self.layoutDataArray.count; j<self.cellCount; j++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:0];
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                attributes.size = CGSizeMake(100, 100);
                attributes.center = [self randomCenter];
                [self.layoutDataArray addObject:attributes];
                [self.gravityBehaviour addItem:attributes];
                [self.collisionBehaviour addItem:attributes];
            }
        }else if (self.layoutDataArray.count > self.cellCount){
            //NSLog(@"previous count: %lu new count: %ld", (unsigned long)self.layoutDataArray.count, (long)self.cellCount);
            NSInteger length = self.layoutDataArray.count - self.cellCount;
            
            [self.layoutDataArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger index, BOOL *stop){
                if (*stop != YES) {
                    [self.gravityBehaviour removeItem:attributes];
                    [self.collisionBehaviour removeItem:attributes];
                }
            }];
            NSRange deleteRange;
            deleteRange.location = 0;
            deleteRange.length = length;
            [self.layoutDataArray removeObjectsInRange:deleteRange];
            
            NSArray *attributesArray = [self.layoutDataArray copy];
            [self.layoutDataArray removeAllObjects];
            
            
            for (NSInteger i = 0; i<attributesArray.count; i++) {
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                attributes.center = [(UICollectionViewLayoutAttributes *)attributesArray[i] center];
                attributes.size = CGSizeMake(100, 100);
                //attributes.center = [self randomCenter];
                [self.layoutDataArray addObject:attributes];
                [self.gravityBehaviour addItem:attributes];
                [self.collisionBehaviour addItem:attributes];
            }
            
        }else
            NSLog(@"It can't be impossible.");
    }
    
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.dynamicAnimator itemsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
    /*
    NSLog(@"layout for %@", indexPath);
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
     */
}


@end
