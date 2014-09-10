//
//  SDEPortraitCell.h
//  FaceAlbum
//
//  Created by seedante on 9/1/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPortraitCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *PortraitView;

- (void)setPortrait:(UIImage *)protraitImage;

@end
