#import "LineLayoutWithAnimation.h"

#define ITEM_SIZE 300.0

@interface LineLayoutWithAnimation ()

@property (nonatomic, assign) NSInteger cellCount;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic) NSIndexPath *pinchedIndexPath;
@property (nonatomic, assign) CGPoint centroid;

@property (nonatomic) NSMutableDictionary *originalLayoutData;

@end

@implementation LineLayoutWithAnimation

-(id)init
{
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(ITEM_SIZE, ITEM_SIZE);
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        self.minimumLineSpacing = 0.0;
        self.minimumInteritemSpacing = 0.0;
        self.originalLayoutData = [NSMutableDictionary new];
        self.centroid = CGPointZero;
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    if (!CGSizeEqualToSize(oldBounds.size, newBounds.size)) {
        return YES;
    }
    return NO;
}

- (void)prepareLayout
{
    self.cellCount = [self.collectionView numberOfItemsInSection:0];
    NSLog(@"cellCount: %ld", (long)self.cellCount);
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
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

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (self.pinchedIndexPath && [self.pinchedIndexPath isEqual:indexPath]) {
        CGSize size = CGSizeZero;
        size.height = attributes.size.height * self.scale;
        size.width = attributes.size.width * self.scale;
        attributes.size = size;
        
        if(!CGPointEqualToPoint(self.centroid, CGPointZero)){
            NSLog(@"centroid: %f, %f", self.centroid.x, self.centroid.y);
            attributes.center = self.centroid;
        }
    }
    
    return attributes;
}

- (void)resizeItemAtIndexPath:(NSIndexPath *)indexPath withScale:(CGFloat)scale
{
    self.pinchedIndexPath = indexPath;
    self.scale = scale;
}

- (void)resizeItemAtIndexPath:(NSIndexPath*)indexPath withScale:(CGFloat)scale withcentroid:(CGPoint)centroid
{
    self.pinchedIndexPath = indexPath;
    self.scale = scale;
    self.centroid = centroid;
}

- (void)resetPinchedItem
{
    self.pinchedIndexPath = nil;
    [self invalidateLayout];
}

@end