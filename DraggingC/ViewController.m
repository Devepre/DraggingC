#import "ViewController.h"
#import "UIView+DragAndDrop.h"

@interface ViewController ()

@property (strong) UIView *fieldView;

@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tagsData = [[NSMutableArray alloc] initWithObjects:@"StrinOne", @"StringTwo", @"StringThree", nil];
    
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
    static UIView *draggingView;
    static CGPoint initialDraggingViewCenter;
    static UIView *superViewForDragging;
    static CGPoint deltaPoint;
    
    UIView *currentView = sender.view;
    CGPoint touchPoint = [sender locationInView:currentView];
//    printf("touchPoint: %f, %f\n", touchPoint.x, touchPoint.y);
    
//    draggingView = [self findViewForPoint:touchPoint inView:currentView dragble:YES receivable:NO];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            printf("INISDE\n");
            draggingView = [self findViewForPoint:touchPoint inView:currentView dragble:YES receivable:NO];
            if ([self isPoint:touchPoint fromView:currentView isInsideView:draggingView] && draggingView.isDragable) {
                printf("TOUCH BEGAN\n");
                if (!self.fieldView) {
                    self.fieldView = [[UIView alloc] initWithFrame:currentView.frame];
                    UIColor *transparentColor = [UIColor colorWithWhite:1.f alpha:0.f];
                    [self.fieldView setBackgroundColor:transparentColor];
                    [currentView addSubview:self.fieldView];
                }
                
                superViewForDragging = draggingView.superview;
                initialDraggingViewCenter = draggingView.center;
                
                CGPoint pointInDrag = [currentView convertPoint:touchPoint toView:draggingView];
                deltaPoint = CGPointMake(CGRectGetMidX(draggingView.bounds) - pointInDrag.x,
                                         CGRectGetMidY(draggingView.bounds) - pointInDrag.y);
                
                [draggingView removeFromSuperview];
                draggingView.center = CGPointMake(touchPoint.x + deltaPoint.x, touchPoint.y + deltaPoint.y);
                [self.fieldView addSubview:draggingView];
                
                [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
            }
            break;
        case UIGestureRecognizerStateChanged:
            printf("changed\n");
            if (draggingView && draggingView.dragable) {
                draggingView.center = CGPointMake(touchPoint.x + deltaPoint.x, touchPoint.y + deltaPoint.y);
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.fieldView) {
                [draggingView removeFromSuperview];
                UIView *receiverView = [self findViewForPoint:touchPoint inView:currentView dragble:NO receivable:YES];
                
                if (receiverView) {
                    CGPoint newCenter = [currentView convertPoint:touchPoint toView:receiverView];
                    draggingView.center = newCenter;
                    [receiverView addSubview:draggingView];
                    
                    [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                } else {
                    goto cancel; // LOL
                }
                
                [self.fieldView removeFromSuperview];
                self.fieldView = nil;
            }
            break;
        case UIGestureRecognizerStateCancelled:
        cancel:
            printf("Gesture cancelled\n");
            
            [superViewForDragging addSubview:draggingView];
            NSLog(@"superview tag: %ld", [superViewForDragging tag]);
            
            [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{ draggingView.center = initialDraggingViewCenter; } completion:nil];
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
