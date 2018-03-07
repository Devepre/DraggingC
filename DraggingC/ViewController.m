#import "ViewController.h"
#import "UIView+DragAndDrop.h"

@interface ViewController ()

@property (strong) UIView *fieldView;

@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tagsData = [[NSMutableArray alloc] initWithObjects:@"StringOne", @"StringTwo", @"StringThree", nil];
    
    self.backgroundView.dragable = NO;
    self.collectionViewBottom.receivable = YES;
    [self attachGesturesToView:self.backgroundView];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tagsData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell =  [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    UILabel *recipeView = (UILabel *)[cell viewWithTag:145];
    recipeView.text = [self.tagsData objectAtIndex:indexPath.row];
    
    cell.dragable = YES;
    
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
    CGPoint touchPointGlobal = [sender locationInView:currentViewGlobal];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            printf("INISDE\n");
            dragingView = [self findViewForPoint:touchPointGlobal inView:currentViewGlobal dragble:YES receivable:NO];
            if ([self isPoint:touchPointGlobal fromView:currentViewGlobal isInsideView:dragingView] && dragingView.isDragable) {
                printf("TOUCH BEGAN\n");
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
                
                if (receiverView) {
                    CGPoint newCenter = [currentViewGlobal convertPoint:touchPointGlobal toView:receiverView];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    dragingView.center = newCenterWithDelta;
                    [receiverView addSubview:dragingView];
                    
                    [UIView animateWithDuration:0.3f animations:^{ dragingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                } else {
                    [superViewForDraging addSubview:dragingView];
                    
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

- (BOOL)isPoint: (CGPoint)point fromView: (UIView *)superVeiw isInsideView:(UIView *)view {
    CGPoint insideViewPoint = [superVeiw convertPoint:point toView:view];
    BOOL result = [view pointInside:insideViewPoint withEvent:nil];
    
    return result;
}

#pragma mark - Additional methods

- (void)createFieldViewOnTopOf:(UIView *)currentView {
    self.fieldView = [[UIView alloc] initWithFrame:currentView.frame];
    UIColor *transparentColor = [UIColor colorWithWhite:1.f alpha:0.f];
    [self.fieldView setBackgroundColor:transparentColor];
    [currentView addSubview:self.fieldView];
}

- (UIView *)findViewForPoint: (CGPoint)point inView: (UIView *)sourceView dragble: (BOOL)dragable receivable: (BOOL)receivable {
    for(UIView *subview in [sourceView allSubViews]) {
//        printf("%s\n", [[[subview class] description] UTF8String]);
        if ([self isPoint:point fromView:sourceView isInsideView:subview]
            && (subview.dragable == dragable)
            && subview.receivable == receivable) {
//            printf("FOUND!\n");
            return subview;
        }
    }
    return nil;
}

@end
