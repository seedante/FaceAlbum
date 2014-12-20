//
//  SDEPopupPanel.m
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPopupPanel.h"

@implementation SDEPopupPanel

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.popupRect = CGRectMake(764, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        self.hideRect = CGRectMake(self.popupRect.origin.x + self.popupRect.size.width, self.popupRect.origin.y, 0, self.popupRect.size.height);
        self.frame = self.hideRect;
        self.isPopup = NO;
        [self.layer setCornerRadius:10.0];
        [self setClipsToBounds:YES];
        
    }
    return self;
}

-(void)popup{
	self.isPopup = YES;
    if (self.hidden) {
        self.hidden = NO;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [self setFrame:self.popupRect];
    }];
}

- (void)hide{
	self.isPopup = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [self setFrame:self.hideRect];
    }];
}

@end
