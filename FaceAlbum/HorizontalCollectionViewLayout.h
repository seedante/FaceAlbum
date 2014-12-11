//
//  HorizontalCollectionViewLayout.h
//  Face Album
//
//  Created by seedante on 11/20/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HorizontalCollectionViewLayout : UICollectionViewFlowLayout


- (void)relocateVisibleItems:(NSArray *)indexPaths withAssemblePosition:(CGPoint)center Scale:(CGFloat)scale;
- (void)resetVisibleItems;
- (UICollectionViewLayoutAttributes *)originalLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)cleanBackupLayoutData;

@end
