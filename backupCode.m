//LineLayout
-(id)init
{
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(ITEM_SIZE, ITEM_SIZE);
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sectionInset = UIEdgeInsetsMake(200, 0.0, 200, 0.0);
        self.minimumLineSpacing = 50.0;
    }
    return self;
}



-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* array = [super layoutAttributesForElementsInRect:rect];
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    
    for (UICollectionViewLayoutAttributes* attributes in array) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            CGFloat distance = CGRectGetMidX(visibleRect) - attributes.center.x;
            CGFloat normalizedDistance = distance / ACTIVE_DISTANCE;
            if (ABS(distance) < ACTIVE_DISTANCE) {
                CGFloat zoom = 1 + ZOOM_FACTOR*(1 - ABS(normalizedDistance));
                attributes.transform3D = CATransform3DMakeScale(zoom, zoom, 1.0);
                attributes.zIndex = 1;
            }
        }
    }
    return array;
}

#pragma mark - check photo change
- (void)checkPhotoLibraryChange
{
    NSLog(@"Check PhotoLibrary change.");
    NSFetchRequest *albumFetchQuest = [[NSFetchRequest alloc] initWithEntityName:@"AlbumGroup"];
    [albumFetchQuest setResultType:NSDictionaryResultType];
    NSEntityDescription *AlbumGroupDescription = [NSEntityDescription entityForName:@"AlbumGroup" inManagedObjectContext:self.faceFetchedResultsController.managedObjectContext];
    NSPropertyDescription *persistentIDDescription = [[AlbumGroupDescription propertiesByName] objectForKey:@"persistentID"];
    NSPropertyDescription *photoCountDescription = [[AlbumGroupDescription propertiesByName] objectForKey:@"photoCount"];
    [albumFetchQuest setPropertiesToFetch:@[persistentIDDescription, photoCountDescription]];
    NSArray *queryResult = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:albumFetchQuest error:nil];
    NSMutableDictionary *albumGroupInfo = [NSMutableDictionary new];
    
    for (NSDictionary *result in queryResult) {
        [albumGroupInfo setObject:result[@"photoCount"] forKey:result[@"persistentID"]];
    }
    
    //Now, just check if there is a different photo and tell the app the photo library is changed, just scan.
    ALAssetsLibraryGroupsEnumerationResultsBlock groupBlock = ^(ALAssetsGroup *group, BOOL *stop){
        NSInteger currentCount = [group numberOfAssets];
        NSString *persistentIDString = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
        if ([albumGroupInfo valueForKey:persistentIDString] == nil || (NSInteger)albumGroupInfo[persistentIDString] != currentCount) {
            NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
            NSLog(@"Album Group: %@ change.", groupName);
            [self.changedAlbumGroups addObject:groupURL];
            *stop = YES;
            return;
        }
        
        NSFetchRequest *assetFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
        [assetFetchRequest setResultType:NSDictionaryResultType];
        
        NSSortDescriptor *URLStringDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"uniqueURLString" ascending:YES];
        [assetFetchRequest setPropertiesToFetch:@[URLStringDescriptor]];
        NSArray *array = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:assetFetchRequest error:nil];
        NSArray *URLArray = [array valueForKeyPath:@"allValues.firstObject"];
        if (URLArray != nil && URLArray.count > 0) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *shouldStop){
                NSString *assetURLString = [(NSURL *)[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
                if (![URLArray containsObject:assetURLString]) {
                    NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                    NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
                    NSLog(@"Album Group: %@ change.", groupName);
                    [self.changedAlbumGroups addObject:groupURL];
                    *shouldStop = YES;
                }
            }];
        }
        
        /*
         __block NSFetchRequest *assetFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
         [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
         NSString *URLString = [(NSURL *)[result valueForProperty:ALAssetPropertyAssetURL] absoluteString];
         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueURLString == %@", URLString];
         [assetFetchRequest setPredicate:predicate];
         NSArray *array = [self.faceFetchedResultsController.managedObjectContext executeFetchRequest:assetFetchRequest error:nil];
         if (array != nil && array.count > 0) {
         ;
         }else{
         *stop = YES;
         NSString *groupName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
         NSURL *groupURL = (NSURL *)[group valueForKey:ALAssetsGroupPropertyURL];
         NSLog(@"Album Group:%@ Change.", groupName);
         [changedAlbumGroups addObject:groupURL];
         return;
         }
         }];
         */
    };
    
    NSUInteger groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupSavedPhotos;
    [self.photoLibrary enumerateGroupsWithTypes:groupTypes usingBlock:groupBlock failureBlock:nil];
}


#pragma mark - LXReorderableCollectionViewDelegateFlowLayout
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Will Begin drag");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Dragging");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Will End Drag.");
}

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Drag End.");
}