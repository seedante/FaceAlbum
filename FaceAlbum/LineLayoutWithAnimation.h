#import <UIKit/UIKit.h>

@interface LineLayoutWithAnimation : UICollectionViewFlowLayout

- (void)resizeItemAtIndexPath:(NSIndexPath*)indexPath withScale:(CGFloat)scale;
- (void)resizeItemAtIndexPath:(NSIndexPath*)indexPath withScale:(CGFloat)scale withcentroid:(CGPoint)centroid;
- (void)resetPinchedItem;

@end
