//
//  FaceCell.m
//  LayoutSample
//
//  Created by seedante on 14-8-5.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "FaceCell.h"

@implementation FaceCell

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

- (CGFloat)faceViewCornerRadius
{
    CGSize avatorSize = self.frame.size;
    CGFloat diameter = MAX(avatorSize.height, avatorSize.width);
    return diameter/2.0;
}

@end
