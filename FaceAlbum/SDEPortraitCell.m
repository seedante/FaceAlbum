//
//  SDEPortraitCell.m
//  FaceAlbum
//
//  Created by seedante on 9/1/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPortraitCell.h"

@implementation SDEPortraitCell

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

- (void)setPortrait:(UIImage *)protraitImage
{
    self.PortraitView.image = protraitImage;
}

@end
