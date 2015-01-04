//
//  SDEPersonInfoEditViewController.m
//  FaceAlbum
//
//  Created by seedante on 1/4/15.
//  Copyright (c) 2015 seedante. All rights reserved.
//

#import "SDEPersonInfoEditViewController.h"
#import "SDEAvatorCell.h"

@interface SDEPersonInfoEditViewController ()

@end

@implementation SDEPersonInfoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SDEAvatorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"avatorCell" forIndexPath:indexPath];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"CandidateInfo" forIndexPath:indexPath];
    
    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (IBAction)saveAllModify:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAllModify:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
