//
//  SDPersonAlbumViewController.m
//  FaceAlbum
//
//  Created by seedante on 14-7-29.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEPersonGalleryViewController.h"
#import "SDEPAVCDataSource.h"

@interface SDEPersonGalleryViewController ()

@property (nonatomic) SDEPAVCDataSource *dataSource;

@end

@implementation SDEPersonGalleryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.navigationItem.hidesBackButton = YES;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    self.dataSource = [[SDEPAVCDataSource alloc] init];
    self.collectionView.dataSource = self.dataSource;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end