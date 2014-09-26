//
//  Store.m
//  FaceAlbum
//
//  Created by seedante on 14-7-22.
//  Copyright (c) 2014年 seedante. All rights reserved.
//

#import "Store.h"
#import "Person.h"

@interface Store ()

@property (nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite) Person *FacelessMan;
@end

@implementation Store

+ (Store *)sharedStore
{
    static Store *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Store alloc]init];
    });
    return sharedInstance;
}

- (void)setupStoreWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL
{
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    NSManagedObjectModel *dataModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES};
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:dataModel];
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    if(error)
        NSLog(@"error: %@", error);
    self.managedObjectContext.persistentStoreCoordinator = psc;
    
    //check if exist FacelessMan, if not, create it.
    NSUserDefaults *defaultConfig = [NSUserDefaults standardUserDefaults];
    [defaultConfig registerDefaults:@{@"FacelessMan": @NO}];
    [defaultConfig synchronize];
    
    BOOL isFacelessManExisted = [defaultConfig boolForKey:@"FacelessMan"];
    if (!isFacelessManExisted) {
        Person *FacelessMan = [Person insertNewObjectInManagedObjectContext:self.managedObjectContext];
        FacelessMan.order = 0;
        FacelessMan.name = @"UnKnown";
        FacelessMan.personID = @"FacelessMan";
        FacelessMan.whetherToDisplay = YES;
        FacelessMan.faceCount = 0;
        FacelessMan.photoCount = 0;
        [self.managedObjectContext save:nil];
        [defaultConfig setBool:YES forKey:@"FacelessMan"];
        [defaultConfig synchronize];
    }
}

- (NSFetchedResultsController *)faceFetchedResultsController
{
    if (_faceFetchedResultsController != nil) {
        return _faceFetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Face"];
    [fetchRequest setFetchBatchSize:100];
    
    NSSortDescriptor *SectionOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *ItemOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:NO];
    [fetchRequest setSortDescriptors:@[SectionOrderDescriptor, ItemOrderDescriptor]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whetherToDisplay == YES"];
    [fetchRequest setPredicate:predicate];
    
    _faceFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"allFaces"];
    
    return _faceFetchedResultsController;
}

- (NSFetchedResultsController *)personFetchedResultsController
{
    if (_personFetchedResultsController != nil) {
        return _personFetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    [fetchRequest setFetchBatchSize:10];
    
    NSSortDescriptor *orderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    [fetchRequest setSortDescriptors:@[orderDescriptor]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whetherToDisplay == YES"];
    [fetchRequest setPredicate:predicate];
    _personFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"order" cacheName:@"allPersons"];
    
    return _personFetchedResultsController;
}

- (NSFetchedResultsController *)photoFetchedResultsController
{
    if (!_photoFetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
        [fetchRequest setFetchBatchSize:10];
        
        NSSortDescriptor *orderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
        [fetchRequest setSortDescriptors:@[orderDescriptor]];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whetherToDisplay == YES"];
        [fetchRequest setPredicate:predicate];
        _personFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"name" cacheName:@"myLife"];
    }
    
    return _photoFetchedResultsController;
}

@end
