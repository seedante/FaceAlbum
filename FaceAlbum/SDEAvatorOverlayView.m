//
//  SDEAvatorOverlayView.m
//  FaceAlbum
//
//  Created by seedante on 9/20/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEAvatorOverlayView.h"
#import "SDEAvatorCheckmarkView.h"

@implementation SDEAvatorOverlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // View settings
        //self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        self.backgroundColor = [UIColor clearColor];
        // Create a checkmark view
        SDEAvatorCheckmarkView *checkmarkView = [[SDEAvatorCheckmarkView alloc] initWithFrame:CGRectMake(self.bounds.size.width - (4.0 + 24.0), self.bounds.size.height - (4.0 + 24.0), 24.0, 24.0)];
        checkmarkView.autoresizingMask = UIViewAutoresizingNone;
        
        [self addSubview:checkmarkView];
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

@end
