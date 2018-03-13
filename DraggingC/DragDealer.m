#import "DragDealer.h"
#import <UIKit/UIkit.h>

@interface DragDealer ()

@property (strong, nonatomic) UIView *fieldView;
@property (strong, nonatomic) UICollectionView *draggingFromCollectionView;
@property (strong, nonatomic) UICollectionViewCell *draggingView;
@property (assign, nonatomic) NSIndexPath *draggingFromContainerIndexPath;

@end

@implementation DragDealer

- (instancetype)init {
    self = [self initWithBaseView:nil andSourceView:nil andDestinationView:nil andDelegate:nil];
    return self;
}

- (instancetype)initWithBaseView: (UIView *)baseView
                   andSourceView: (UICollectionView *)sourceView
              andDestinationView: (UICollectionView *)destinationView
                     andDelegate: (NSObject<DragDealerProtocol> *)delegate {
    self = [super init];
    if (self) {
        _baseView = baseView;
        _sourceView = sourceView;
        _destinationView = destinationView;
        _delegate = delegate;
        
        //gesture creation
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:_baseView action:@selector(handlePan:)];
        panGesture.delegate = self;
        [_baseView addGestureRecognizer:panGesture];
        
        // default usage
        _sourceReceivable = YES;
        _destinationReceivable = YES;
        
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    UIView *draggingView = self.draggingView;
    UIView *baseView = self.baseView;
    UICollectionView *draggingFromCollectionView = self.draggingFromCollectionView;
    NSIndexPath *draggingFromContainerIndexPath = self.draggingFromContainerIndexPath;
    
    // old
    static CGPoint initialDraggingViewCenter;
    static CGPoint deltaVector;
    
    CGPoint touchPointGlobal = [sender locationInView:baseView];
    static int indexInBottom;
    static BOOL gotToReceiver;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            if (!draggingView) {
                printf("NEW DRAGGING VIEW\n");

                draggingFromCollectionView = [self getDraggedCollectionViewFromPoint:touchPointGlobal];
                CGPoint draggingPoint = [baseView convertPoint:touchPointGlobal toView:draggingFromCollectionView];
                draggingFromContainerIndexPath = [draggingFromCollectionView indexPathForItemAtPoint:draggingPoint];
                draggingView = [draggingFromCollectionView cellForItemAtIndexPath:draggingFromContainerIndexPath];
            }
            
            if (draggingView) {
                if (!self.fieldView) {
                    [self createFieldViewOnTopOf:baseView];
                }
                
                initialDraggingViewCenter = draggingView.center;
                
                CGPoint touchPointInDragingView = [baseView convertPoint:touchPointGlobal toView:draggingView];
                deltaVector = CGPointMake(CGRectGetMidX(draggingView.bounds) - touchPointInDragingView.x,
                                          CGRectGetMidY(draggingView.bounds) - touchPointInDragingView.y);
                
                //remove from Source CollectionView
                [draggingView removeFromSuperview];
                
                //delegate methods to handle datasource
                if (self.delegate && [self.delegate respondsToSelector:@selector(canDragItemAtIndexPath:fromView:)]) {
                    BOOL canDrag = [self.delegate canDragItemAtIndexPath:draggingFromContainerIndexPath
                                                                fromView:draggingFromCollectionView];
                    if (canDrag) {
                        if ([self.delegate respondsToSelector:@selector(dragBeganFromView:atIndexPath:)]) {
                            [self.delegate dragBeganFromView:draggingFromCollectionView
                                                 atIndexPath:draggingFromContainerIndexPath];
                        }
                    }
                }
                
                //adding to temp field
                draggingView.center = CGPointMake(touchPointGlobal.x + deltaVector.x, touchPointGlobal.y + deltaVector.y);
                [self.fieldView addSubview:draggingView];
                
                //animation
                [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (draggingView) {
                //check to comment it
                draggingView.center = CGPointMake(touchPointGlobal.x + deltaVector.x, touchPointGlobal.y + deltaVector.y);
                
                if ([self isPoint:draggingView.center fromView:baseView isInsideView:self.destinationView]) {
                    
                    NSIndexPath *selectedIndexPath = [self.destinationView indexPathForItemAtPoint:[sender locationInView:self.destinationView]];
                    if(selectedIndexPath) {
                        printf("inside bottom and index = %ld\n", (long)selectedIndexPath.row);
                        indexInBottom = (int)selectedIndexPath.row;
                        if (!gotToReceiver) {
                            gotToReceiver = YES;
                            
                            printf("GOT TO RECEIVER\n");
                            [self.choosedTagsData insertObject:[self.tagsData objectAtIndex:index] atIndex:indexInBottom];
                            [self.destinationView insertItemsAtIndexPaths:@[selectedIndexPath]];
                            //                            [self.collectionViewBottom reloadData];
                            
                            [self.destinationView beginInteractiveMovementForItemAtIndexPath:selectedIndexPath];
                        }
                    }
                }
                [self.destinationView updateInteractiveMovementTargetPosition:[sender locationInView:self.destinationView]];
            }
            break;
        case UIGestureRecognizerStateEnded:
            gotToReceiver = NO;
            [self.destinationView endInteractiveMovement];
            
            if (self.fieldView) {
                [draggingView removeFromSuperview];
                UIView *receiverView = [self findViewForPoint:touchPointGlobal inView:baseView dragble:NO receivable:YES];
                
                if (receiverView && receiverView != draggingFromCollectionView) {
                    if (receiverView.tag == 102) {
                        //                        [self.choosedTagsData addObject:[self.tagsData objectAtIndex:index]];
                        [self.tagsData removeObjectAtIndex:index];
                    } else {
                        [self.tagsData addObject:[self.choosedTagsData objectAtIndex:index]];
                        [self.choosedTagsData removeObjectAtIndex:index];
                    }
                    
                    [self.sourceView reloadData];
                    [self.destinationView reloadData];
                    [self printData];
                    
                    CGPoint newCenter = [baseView convertPoint:touchPointGlobal toView:receiverView];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    draggingView.center = newCenterWithDelta;
                    [receiverView addSubview:draggingView];
                    
                    [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                } else {
                    [draggingFromCollectionView addSubview:draggingView];
                    
                    CGPoint newCenter = [baseView convertPoint:touchPointGlobal toView:draggingFromCollectionView];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    draggingView.center = newCenterWithDelta;
                    
                    [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{ draggingView.center = initialDraggingViewCenter; } completion:nil];
                }
                
                [self.fieldView removeFromSuperview];
                self.fieldView = nil;
                draggingView = nil;
            }
            break;
        case UIGestureRecognizerStateCancelled:
            printf("LOL never LOL\n");
            draggingView = nil;
            break;
        default:
            break;
    }
    
}

#pragma mark - Data Source Handling
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    NSLog(@"\nchanged \n%@", self.choosedTagsData);
    NSLog(@"Source: %@ Destination: %@", sourceIndexPath, destinationIndexPath);
    
    NSLog(@"\nchanged \n%@", self.choosedTagsData);
    [self.destinationView reloadData];
    
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
    for (UIView *subview in [self allSubViewsInView:sourceView]) {
        if ([self isPoint:point fromView:sourceView isInsideView:subview]
            && (subview.dragable == dragable)
            && subview.receivable == receivable) {
            return subview;
        }
    }
    return nil;
}

- (NSMutableArray*)allSubViewsInView: (UIView *)view {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObject:self];
    for (UIView *subview in view.subviews) {
        [arr addObjectsFromArray:(NSArray *)[self allSubViewsInView: subview]];
    }
    return arr;
}

- (void)printData {
//    NSLog(@"\n%@ \n\n%@", self.tagsData, self.choosedTagsData);
}

- (UICollectionView *)getDraggedCollectionViewFromPoint: (CGPoint)point {
    UICollectionView * result = nil;
    
    CGPoint pointInSource = [self.baseView convertPoint:point toView:self.sourceView];
    CGPoint pointInDestination = [self.baseView convertPoint:point toView:self.destinationView];
    
    if ([self.sourceView pointInside:pointInSource withEvent:nil]) {
        result = self.sourceView;
    } else if ([self.destinationView pointInside:pointInDestination withEvent:nil]) {
        result = self.destinationView;
    }
    
    return result;
}

@end
