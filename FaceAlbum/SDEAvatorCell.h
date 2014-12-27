//
//  AvatorCell.h
//  FaceAlbum
//
//  Created by seedante on 14-7-24.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEAvatorCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatorView;
@property (weak, nonatomic) IBOutlet UILabel *order;
@property (nonatomic, assign) BOOL showOverlayViewWhenSelected;

- (CGFloat)avatorCornerRadius;

@end
