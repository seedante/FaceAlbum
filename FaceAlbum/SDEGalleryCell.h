//
//  SDEPortraitCell.h
//  FaceAlbum
//
//  Created by seedante on 9/1/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEGalleryCell : UICollectionViewCell

@property (nonatomic) IBOutlet UIImageView *galleryContentView;

- (void)setShowContent:(UIImage *)protraitImage;

@end
