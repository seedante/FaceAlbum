//
//  PhotoCell.m
//  LayoutSample
//
//  Created by seedante on 14-8-1.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "PhotoCell.h"

@implementation PhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setAsset:(ALAsset *)asset
{
    _asset = asset;
    self.photoView.image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
}

@end
