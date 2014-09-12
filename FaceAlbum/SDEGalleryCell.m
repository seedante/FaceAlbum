//
//  SDEPortraitCell.m
//  FaceAlbum
//
//  Created by seedante on 9/1/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEGalleryCell.h"

@implementation SDEGalleryCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)setShowContent:(UIImage *)protraitImage
{
    self.galleryContentView.image = protraitImage;
}

@end
