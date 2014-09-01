//
//  SDEPAVCDataSource.m
//  FaceAlbum
//
//  Created by seedante on 14-8-10.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "SDEPAVCDataSource.h"
#import "Store.h"

@interface SDEPAVCDataSource ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation SDEPAVCDataSource

+ (instancetype)sharedDataSource{
    static SDEPAVCDataSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SDEPAVCDataSource alloc]init];
    });
    return sharedInstance;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    Store *storeCenter = [Store sharedStore];
    _managedObjectContext = storeCenter.managedObjectContext;
    return _managedObjectContext;
}

- (NSFetchedResultsController *)faceFetchedResultsController
{
    if (_faceFetchedResultsController != nil) {
        return _faceFetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Face"];
    [fetchRequest setFetchBatchSize:100];
    
    NSSortDescriptor *SectionOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *ItemOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:@[SectionOrderDescriptor, ItemOrderDescriptor]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whetherToDisplay == YES"];
    [fetchRequest setPredicate:predicate];
    
    _faceFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"allFaces"];
    _faceFetchedResultsController.delegate = self;
    
    return _faceFetchedResultsController;
}

- (NSFetchedResultsController *)personFetchedResultsController
{
    if (_personFetchedResultsController != nil) {
        return _personFetchedResultsController;
    }
    
    _personFetchedResultsController = [[Store sharedStore] personFetchedResultsController];
    _personFetchedResultsController.delegate = self;
    
    return _personFetchedResultsController;
}

@end
