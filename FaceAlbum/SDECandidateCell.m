//
//  SDESelectPersonCell.m
//  FaceAlbum
//
//  Created by seedante on 14-8-23.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDECandidateCell.h"

@interface SDECandidateCell ()

@property (nonatomic) UIImageView *imageView;

@end

@implementation SDECandidateCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)setCellImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (UIImageView *)imageView
{
    if (_imageView) {
        return _imageView;
    }
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
    return _imageView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
