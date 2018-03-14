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
    
    _tagsData = [[NSMutableArray alloc] initWithObjects:@"StringOne", @"StringTwo", @"StringThree", nil];
    _choosedTagsData = [[NSMutableArray alloc] initWithObjects:@"bla-blah", @"anotherOne", nil];
    
    _dragDealer = [[DragDealer alloc] initWithBaseView: _backgroundView
                                         andSourceView:_collectionViewTop
                                    andDestinationView:_collectionViewBottom
                                           andDelegate:self];
    _dragDealer.scaled = YES;
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

#pragma mark - Touches & Gestures

#pragma mark - Additional methods

@end
