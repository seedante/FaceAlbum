//
//  SDEPersonProfileHeaderView.m
//  FaceAlbum
//
//  Created by seedante on 9/14/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import "SDEPersonProfileHeaderView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Person.h"
#import "SDEPersonInfoEditViewController.h"
#import "SDEStore.h"

@implementation SDEPersonProfileHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.avatorImageView setImage:nil];
    self.section = -1;
    self.assetURLString = nil;
    self.portraitAreaRectValue = nil;
    self.storePath = nil;
    self.numberLabel.text = nil;
    self.nameTextField.text = nil;
    
}

- (IBAction)userEndInput:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    [textField resignFirstResponder];
}

- (IBAction)performChooseAction:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    SDEPersonInfoEditViewController *personInfoEditVC = [storyboard instantiateViewControllerWithIdentifier:@"PersonInfoEditVC"];
    personInfoEditVC.section = self.section;
    personInfoEditVC.MontangeRoomCollectionView = self.MontangeRoomCollectionView;
    [self.parentVC presentViewController:personInfoEditVC animated:YES completion:nil];
}

@end
