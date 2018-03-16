#import "ViewController.h"
#import "UIView+DragAndDrop.h"

@interface ViewController ()

@property (strong) DragDealer *dragDealer;

@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";
static NSString * const reuseIdentifier2 = @"CellCollected";

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    _tagsData = [[NSMutableArray alloc] initWithObjects:@"StringOne", @"StringTwo", nil];
//    _choosedTagsData = [[NSMutableArray alloc] initWithObjects:@"bla-blah", @"anotherOne", nil];
    _choosedTagsData = [[NSMutableArray alloc] init];
    
    _tagsData = [[NSMutableArray alloc]init];
    for (int i = 0; i < 100; i++) {
        [_tagsData addObject:[NSString stringWithFormat:@"String%d", i]];
    }
    
    _dragDealer = [[DragDealer alloc] initWithBaseView: _backgroundView
                                         andSourceView:_collectionViewTop
                                    andDestinationView:_collectionViewBottom
                                           andDelegate:self
                                   andLongPressEnabled:YES];
    _dragDealer.scaled = YES;
    _dragDealer.simultaneouslyScrollAndDragAllowed = NO;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (collectionView.tag) {
        case 101:
            return self.tagsData.count;
            break;
            
        case 102:
            return self.choosedTagsData.count;
            break;
        default:
            break;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    UILabel *recipeView;
    switch (collectionView.tag) {
        case 101:
            cell =  [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
            cell.dragable = YES;
            
            recipeView = (UILabel *)[cell viewWithTag:145];
            recipeView.text = [self.tagsData objectAtIndex:indexPath.row];
            break;
        case 102:
            cell =  [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier2 forIndexPath:indexPath];
            cell.dragable = YES;
            
            recipeView = (UILabel *)[cell viewWithTag:146];
            recipeView.text = [self.choosedTagsData objectAtIndex:indexPath.row];
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - <DragDealerProtocol>

- (BOOL) canDragItemFromView:(UICollectionView *)view
                 atIndexPath:(NSIndexPath *)path {
//        if (path.item == 1) {
//            printf("I don't allow to drag from %ld view at index %ld\n", view.tag, path.item);
//            return NO;
//        }
    
    return YES;
}

- (void)dragBeganFromView: (UICollectionView *)view
              atIndexPath: (NSIndexPath *)path {
//    printf("<VC> Begin dragging from view tagged as %ld at index %ld\n", (long)view.tag, (long)path.item);
}

- (void)draggedFromCollectionView: (UICollectionView *)fromView
                      atIndexPath: (NSIndexPath *)indexFrom
                 toCollectionView: (UICollectionView *)toView
                      atIndexPath: (NSIndexPath *)indexTo {
    printf("<VC> End of dragging - moving DATA now from index %ld to index %ld\n", (long)indexFrom.item, (long)indexTo.item);
    NSString *transferObj;
    NSMutableArray *source;
    NSMutableArray *destination;
    
    if (fromView.tag == 101) {
        source = self.tagsData;
    } else if (fromView.tag == 102) {
        source = self.choosedTagsData;
    }
    if (toView.tag == 101) {
        destination = self.tagsData;
    } else if (toView.tag == 102) {
        destination = self.choosedTagsData;
    }
    
    transferObj = [source objectAtIndex:indexFrom.item];
    [source removeObjectAtIndex:indexFrom.item];
    [destination insertObject:transferObj atIndex:indexTo.item];
    
    [self printData];
}

- (void) dropCopyObjectFromCollectionView: (UICollectionView *)fromView
                          atIndexPath: (NSIndexPath *)indexFrom
                     toCollectionView: (UICollectionView *)toView
                          atIndexPath: (NSIndexPath *)indexTo {
    printf("<VC> Swap object from index %ld to index %ld\n", (long)indexFrom.item, (long)indexTo.item);
    NSString *transferObj;
    NSMutableArray *source;
    NSMutableArray *destination;
    
    if (fromView.tag == 101) {
        source = self.tagsData;
    } else if (fromView.tag == 102) {
        source = self.choosedTagsData;
    }
    if (toView.tag == 101) {
        destination = self.tagsData;
    } else if (toView.tag == 102) {
        destination = self.choosedTagsData;
    }
    
    transferObj = [source objectAtIndex:indexFrom.item];
    [destination insertObject:transferObj atIndex:indexTo.item];
    
    [self printData];
}

- (void)deleteObjectFromCollectionView:(UICollectionView *)fromView atIndexPath:(NSIndexPath *)indexFrom {
    printf("<VC> Delete object from view tagged as %ld at index %ld\n", (long)fromView.tag, (long)indexFrom.item);
    NSMutableArray *source;
    if (fromView.tag == 101) {
        source = self.tagsData;
    } else if (fromView.tag == 102) {
        source = self.choosedTagsData;
    }
    [source removeObjectAtIndex:indexFrom.item];
    printf("<VC> deleted!\n");

    [self printData];
}

#pragma mark - Data Source Handling

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    printf("<VC> FRAMEWORK work is here\n");
    NSLog(@"\nUpdate from Framework \n%@", self.choosedTagsData);
    NSLog(@"Source: %@ Destination: %@", sourceIndexPath, destinationIndexPath);
    
    NSLog(@"\nUpdate from Framework \n%@", self.choosedTagsData);
    [self.collectionViewBottom reloadData];
    [self.collectionViewTop reloadData];
    
}

#pragma mark - Touches & Gestures

#pragma mark - Additional methods

- (void)printData {
    NSLog(@"\n<VC>\n%@ \n\n%@", self.tagsData, self.choosedTagsData);
}

@end

