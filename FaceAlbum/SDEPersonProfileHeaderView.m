//
//  SDEPersonProfileHeaderView.m
//  FaceAlbum
//
//  Created by seedante on 9/14/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPersonProfileHeaderView.h"

@implementation SDEPersonProfileHeaderView

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

- (IBAction)userEndInput:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    [textField resignFirstResponder];
}
@end
