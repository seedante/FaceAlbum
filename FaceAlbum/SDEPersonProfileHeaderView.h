//
//  SDEPersonProfileHeaderView.h
//  FaceAlbum
//
//  Created by seedante on 9/14/14.
//  Copyright (c) 2014 seedante. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDEPersonProfileHeaderView : UICollectionReusableView

@property (nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatorImageView;
@property (weak, nonatomic) UICollectionView *MontangeRoomCollectionView;
@property (nonatomic, weak) UIViewController *parentVC;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, copy) NSString *assetURLString;
@property (nonatomic) NSValue *portraitAreaRectValue;
@property (nonatomic, copy) NSString *storePath;

- (IBAction)userEndInput:(id)sender;
- (IBAction)performChooseAction:(id)sender;
@end
