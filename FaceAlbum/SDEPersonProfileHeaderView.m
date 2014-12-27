//
//  SDEPersonProfileHeaderView.m
//  FaceAlbum
//
//  Created by seedante on 9/14/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPersonProfileHeaderView.h"
#import "Person.h"

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

- (IBAction)performChooseAction:(id)sender
{
    if (self.collectionView.allowsSelection) {
        self.collectionView.allowsSelection = NO;
        self.delegate.isChoosingAvator = NO;
        self.delegate.sectionOfChooseAvator = -1;
        [self.actionButton setBackgroundColor:[UIColor clearColor]];
    }else{
        self.collectionView.allowsSelection = YES;
        self.collectionView.allowsMultipleSelection = NO;
        self.delegate.isChoosingAvator = YES;
        self.delegate.sectionOfChooseAvator = self.section;
        [self.actionButton setBackgroundColor:[UIColor redColor]];
    }

}

@end
