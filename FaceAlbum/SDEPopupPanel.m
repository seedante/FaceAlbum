//
//  SDEPopupPanel.m
//  FaceAlbum
//
//  Created by seedante on 9/21/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPopupPanel.h"

@implementation SDEPopupPanel
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        ;
    }
    NSLog(@"HeHe");
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.popupRect = CGRectMake(764, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
        //NSLog(@"Frame: %f, %f", self.popupRect.origin.x, self.popupRect.origin.y);
        self.hideRect = CGRectMake(self.popupRect.origin.x + self.popupRect.size.width, self.popupRect.origin.y, 0, self.popupRect.size.height);
        //NSLog(@"Hide Rect: %f, %f", self.hideRect.origin.x, self.hideRect.origin.y);
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
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.2];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[self setFrame:self.popupRect];
	[UIView commitAnimations];
}

- (void)hide{
    NSLog(@"Hide");
	self.isPopup = NO;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.2];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[self setFrame:self.hideRect];
	[UIView commitAnimations];
}

@end
