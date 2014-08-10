//
//  FaceCell.h
//  LayoutSample
//
//  Created by seedante on 14-8-5.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FaceCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *faceView;

- (CGFloat)faceViewCornerRadius;
@end
