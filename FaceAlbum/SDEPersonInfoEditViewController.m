//
//  SDEPersonInfoEditViewController.m
//  FaceAlbum
//
//  Created by seedante on 1/4/15.
//  Copyright (c) 2015 seedante. All rights reserved.
//

#import "SDEPersonInfoEditViewController.h"
#import "SDEAvatorCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Face.h"
#import "Person.h"
#import "Store.h"

@interface SDEPersonInfoEditViewController ()


@property (nonatomic, weak) NSManagedObjectContext *mangedObjectContext;
@property (nonatomic, assign) NSInteger choosedIndex;
@property (nonatomic) Person *currentPersonItem;
@property (nonatomic, copy) NSString *editedNameString;

@end

@implementation SDEPersonInfoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.choosedIndex = -1;
    self.faceFetchedResultsController = [[Store sharedStore] faceFetchedResultsController];
    self.mangedObjectContext = [[Store sharedStore] managedObjectContext];
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.section]];
    self.currentPersonItem = faceItem.personOwner;
    [self.posterImageView setImage:self.currentPersonItem.avatorImage];
    if (self.currentPersonItem.name && self.currentPersonItem.name.length > 0) {
        self.nameTextField.text = self.currentPersonItem.name;
    }
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UICollectionViewDataSource Method
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.faceFetchedResultsController sections] objectAtIndex:self.section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDEAvatorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"avatorCell" forIndexPath:indexPath];
    cell.layer.cornerRadius = cell.avatorCornerRadius;
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:self.section]];
    UIImage *avatorImage = [UIImage imageWithContentsOfFile:faceItem.storeFileName];
    if (!avatorImage) {
        avatorImage = faceItem.avatorImage;
    }
    
    [cell.avatorView setImage:avatorImage];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:self.section]];
    UIImage *avatorImage = [UIImage imageWithContentsOfFile:faceItem.storeFileName];
    if (!avatorImage) {
        avatorImage = faceItem.avatorImage;
    }
    [self.posterImageView setImage:avatorImage];
    self.choosedIndex = indexPath.item;
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

- (IBAction)saveAllModify:(id)sender
{
    self.editedNameString = self.nameTextField.text;
    if (self.editedNameString && self.editedNameString.length > 0) {
        if (self.currentPersonItem.name && self.currentPersonItem.name.length > 0) {
            if (![self.editedNameString isEqual:self.currentPersonItem.name]) {
                self.currentPersonItem.name = self.editedNameString;
                for (Face *face in self.currentPersonItem.ownedFaces) {
                    face.name = self.editedNameString;
                }
            }
        }else{
            self.currentPersonItem.name = self.editedNameString;
            for (Face *face in self.currentPersonItem.ownedFaces) {
                face.name = self.editedNameString;
            }
        }
    }
    
    if (self.choosedIndex != -1) {
        Face *faceItem = [self.faceFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:self.choosedIndex inSection:self.section]];
        UIImage *avatorImage = [UIImage imageWithContentsOfFile:faceItem.storeFileName];
        if (!avatorImage) {
            avatorImage = faceItem.avatorImage;
        }
        self.currentPersonItem.avatorImage = avatorImage;
        NSString *storePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        storePath = [storePath stringByAppendingPathComponent:self.currentPersonItem.portraitFileString];
        [self createPosterFileFromAsset:faceItem.assetURLString WithArea:faceItem.portraitAreaRect AtPath:storePath];
    }
    
    if ([self.mangedObjectContext hasChanges]) {
        [self.MontangeRoomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:self.section]];
        [self.mangedObjectContext save:nil];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAllModify:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.editedNameString = textField.text;
}
@end
