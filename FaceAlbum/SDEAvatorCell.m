//
//  AvatorCell.m
//  FaceAlbum
//
//  Created by seedante on 14-7-24.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEAvatorCell.h"

@implementation SDEAvatorCell

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code

    }
    return self;
}

- (CGFloat)avatorCornerRadius
{
    CGSize avatorSize = self.frame.size;
    CGFloat diameter = MAX(avatorSize.height, avatorSize.width);
    return diameter/2.0;
}


- (void)setCellCornerRadius:(CGSize)imageSize
{
    
}

@end
