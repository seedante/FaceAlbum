//
//  SDEPersonProfileHeader.m
//  FaceAlbum
//
//  Created by seedante on 14-8-15.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEPersonProfileHeader.h"

@implementation SDEPersonProfileHeader

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

- (UIImageView *)personAvatorView
{
    _personAvatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    return _personAvatorView;
}

- (void)setAvator:(UIImage *)image
{
    self.personAvatorView.image = image;
}

- (IBAction)selectAllFaces:(id)sender
{
    
}
@end
