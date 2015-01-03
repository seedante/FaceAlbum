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

@implementation SDEPersonProfileHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        /*
        [[NSBundle mainBundle] loadNibNamed:@"SDEPersonProfileHeaderView" owner:self options:nil];
        [self addSubview:self.avatorImageView];
        [self addSubview:self.nameTextField];
        [self addSubview:self.numberLabel];
        [self addSubview:self.actionButton];
         */
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
- (void)prepareForReuse
{
    NSLog(@"prepareForReuse");
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
    if (self.collectionView.allowsSelection) {
        self.collectionView.allowsSelection = NO;
        self.delegate.isChoosingAvator = NO;
        self.delegate.editedSection = -1;
        [self.actionButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self createPosterFileFromAsset:self.assetURLString WithArea:self.portraitAreaRectValue AtPath:self.storePath];
    }else{
        self.collectionView.allowsSelection = YES;
        self.collectionView.allowsMultipleSelection = NO;
        self.delegate.isChoosingAvator = YES;
        self.delegate.editedSection = self.section;
        [self.actionButton setTitle:@"Confirm" forState:UIControlStateNormal];
    }
}

- (void)createPosterFileFromAsset:(NSString *)assetURLString WithArea:(NSValue *)portraitAreaRect AtPath:(NSString *)storePath
{
    if (!assetURLString) {
        NSLog(@"null URL");
    }
    [[[ALAssetsLibrary alloc] init] assetForURL:[NSURL URLWithString:assetURLString] resultBlock:^(ALAsset *asset){
        if (asset) {
            CGImageRef sourceCGImage = [asset.defaultRepresentation fullScreenImage];
            CGImageRef portraitCGImage = CGImageCreateWithImageInRect(sourceCGImage, portraitAreaRect.CGRectValue);
            UIImage *portraitUIImage = [UIImage imageWithCGImage:portraitCGImage];
            NSData *imageData = UIImageJPEGRepresentation(portraitUIImage, 1.0f);
            
            BOOL isExisted = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
            if (isExisted) {
                BOOL deleteResult = [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
                if (!deleteResult) {
                    NSLog(@"Delete File Error.");
                }else
                    NSLog(@"Delete Success.");
            }
            
            BOOL success = [imageData writeToFile:storePath atomically:YES];
            if (!success) {
                NSLog(@"Create Portrait Image File Error");
            }
            //NSLog(@"Write Portrait Image File to Path: %@", storePath);
            CGImageRelease(portraitCGImage);
            //CGImageRelease(sourceCGImage);
        }else
            NSLog(@"Access Asset Failed");
    }failureBlock:^(NSError *error){
        NSLog(@"Authorizate Failed");
    }];
}

@end
