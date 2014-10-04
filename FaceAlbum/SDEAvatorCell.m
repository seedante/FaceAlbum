//
//  AvatorCell.m
//  FaceAlbum
//
//  Created by seedante on 14-7-24.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEAvatorCell.h"
#import "SDEAvatorOverlayView.h"

@interface SDEAvatorCell ()
@property (nonatomic) SDEAvatorOverlayView *overlayView;

@end

@implementation SDEAvatorCell

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code
        NSLog(@"ITSHOULDBE");
    }
    return self;
}

- (void)awakeFromNib
{
    //NSLog(@"ITSHOULDBE");
    [super awakeFromNib];
    self.showOverlayViewWhenSelected = YES;
    
    // Create a image view
    self.overlayView = [[SDEAvatorOverlayView alloc] initWithFrame:self.contentView.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.contentView addSubview:self.overlayView];
    self.overlayView.alpha = 0.f;
}

- (CGFloat)avatorCornerRadius
{
    CGSize avatorSize = self.frame.size;
    CGFloat diameter = MAX(avatorSize.height, avatorSize.width);
    return diameter/5.0;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    // Show/hide overlay view
    if (selected && self.showOverlayViewWhenSelected) {
        [self showOverlayView];
    } else {
        [self hideOverlayView];
    }
}

- (void)showOverlayView
{
    self.overlayView.alpha = 1.f;
}

- (void)hideOverlayView
{
    self.overlayView.alpha = 0.f;
}

- (void)setCellCornerRadius:(CGSize)imageSize
{
    
}

@end
