#import "ViewController.h"
#import "UIView+DragAndDrop.h"

@interface ViewController ()

@property (strong) UIView *fieldView;

@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";
static NSString * const reuseIdentifier2 = @"CellCollected";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tagsData = [[NSMutableArray alloc] initWithObjects:@"StringOne", @"StringTwo", @"StringThree", nil];
    _choosedTagsData = [[NSMutableArray alloc] initWithObjects:@"bla-blah", @"anotherOne", nil];
    
    self.backgroundView.dragable = NO;
    self.collectionViewTop.receivable = YES;
    self.collectionViewBottom.receivable = YES;
    [self attachGesturesToView:self.backgroundView];
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
- (void)attachGesturesToView:(UIView *)view {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    static UIView *dragingView;
    static CGPoint initialDraggingViewCenter;
    static UIView *superViewForDraging;
    static CGPoint deltaVector;
    
    UIView *currentViewGlobal = sender.view;
    CGPoint touchPointGlobal = [sender locationInView:currentViewGlobal];;
    NSIndexPath *path;
    static int index;
    static UIView *parentContainerView;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            dragingView = [self findViewForPoint:touchPointGlobal inView:currentViewGlobal dragble:YES receivable:NO];
            parentContainerView = [self findViewForPoint:touchPointGlobal inView:currentViewGlobal dragble:NO receivable:YES];
            
            path = [(UICollectionView *)parentContainerView indexPathForItemAtPoint:[currentViewGlobal convertPoint:touchPointGlobal toView:(UICollectionView *)parentContainerView]];
            index = path.item;
            printf("index = %d\n", index);
            
            if ([self isPoint:touchPointGlobal fromView:currentViewGlobal isInsideView:dragingView] && dragingView.isDragable) {
                if (!self.fieldView) {
                    [self createFieldViewOnTopOf:currentViewGlobal];
                }
                
                superViewForDraging = dragingView.superview;
                initialDraggingViewCenter = dragingView.center;
                
                CGPoint touchPointInDragingView = [currentViewGlobal convertPoint:touchPointGlobal toView:dragingView];
                deltaVector = CGPointMake(CGRectGetMidX(dragingView.bounds) - touchPointInDragingView.x,
                                         CGRectGetMidY(dragingView.bounds) - touchPointInDragingView.y);
                
                [dragingView removeFromSuperview];
                dragingView.center = CGPointMake(touchPointGlobal.x + deltaVector.x, touchPointGlobal.y + deltaVector.y);
                [self.fieldView addSubview:dragingView];
                
                [UIView animateWithDuration:0.3f animations:^{ dragingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (dragingView && dragingView.dragable) {
                dragingView.center = CGPointMake(touchPointGlobal.x + deltaVector.x, touchPointGlobal.y + deltaVector.y);
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.fieldView) {
                [dragingView removeFromSuperview];
                UIView *receiverView = [self findViewForPoint:touchPointGlobal inView:currentViewGlobal dragble:NO receivable:YES];
                
                if (receiverView && receiverView != parentContainerView) {
                    if (receiverView.tag == 102) {
                        [self.choosedTagsData addObject:[self.tagsData objectAtIndex:index]];
                        [self.tagsData removeObjectAtIndex:index];
                    } else {
                        [self.tagsData addObject:[self.choosedTagsData objectAtIndex:index]];
                        [self.choosedTagsData removeObjectAtIndex:index];
                    }
                    
                    [self.collectionViewTop reloadData];
                    [self.collectionViewBottom reloadData];
                    [self printData];
                    
                    CGPoint newCenter = [currentViewGlobal convertPoint:touchPointGlobal toView:receiverView];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    dragingView.center = newCenterWithDelta;
                    [receiverView addSubview:dragingView];
                    
                    [UIView animateWithDuration:0.3f animations:^{ dragingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                } else {
                    [superViewForDraging addSubview:dragingView];

                    CGPoint newCenter = [currentViewGlobal convertPoint:touchPointGlobal toView:superViewForDraging];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    dragingView.center = newCenterWithDelta;
                    
                    [UIView animateWithDuration:0.3f animations:^{ dragingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{ dragingView.center = initialDraggingViewCenter; } completion:nil];
                }
                
                [self.fieldView removeFromSuperview];
                self.fieldView = nil;
            }
            break;
        case UIGestureRecognizerStateCancelled:
            printf("LOL never LOL\n");
            break;
        default:
            break;
    }
    
}

#pragma mark - Additional methods

- (BOOL)isPoint: (CGPoint)point fromView: (UIView *)superVeiw isInsideView:(UIView *)view {
    CGPoint insideViewPoint = [superVeiw convertPoint:point toView:view];
    BOOL result = [view pointInside:insideViewPoint withEvent:nil];
    
    return result;
}

- (void)createFieldViewOnTopOf:(UIView *)currentView {
    self.fieldView = [[UIView alloc] initWithFrame:currentView.frame];
    UIColor *transparentColor = [UIColor colorWithWhite:1.f alpha:0.f];
    [self.fieldView setBackgroundColor:transparentColor];
    [currentView addSubview:self.fieldView];
}

- (UIView *)findViewForPoint: (CGPoint)point inView: (UIView *)sourceView dragble: (BOOL)dragable receivable: (BOOL)receivable {
    for(UIView *subview in [sourceView allSubViews]) {
        if ([self isPoint:point fromView:sourceView isInsideView:subview]
            && (subview.dragable == dragable)
            && subview.receivable == receivable) {
            return subview;
        }
    }
    return nil;
}

- (void)printData {
    NSLog(@"\n%@ \n\n%@", self.tagsData, self.choosedTagsData);
}

@end
