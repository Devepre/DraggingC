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
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        [_baseView addGestureRecognizer:panGesture];
        
        // default usage
        _sourceReceivable = YES;
        _destinationReceivable = YES;
        
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    // old
    static CGPoint initialDraggingViewCenter;
    static CGPoint deltaVector;
    
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
//    static int indexInBottom;
    static BOOL gotToReceiver;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            if (!self.draggingView) {
                printf("NEW DRAGGING VIEW\n");

                self.draggingFromCollectionView = [self getDraggedCollectionViewFromBasePoint:touchPointGlobal];
                CGPoint draggingPoint = [self.baseView convertPoint:touchPointGlobal toView:self.draggingFromCollectionView];
                self.draggingFromContainerIndexPath = [self.draggingFromCollectionView indexPathForItemAtPoint:draggingPoint];
                self.draggingView = [self.draggingFromCollectionView cellForItemAtIndexPath:self.draggingFromContainerIndexPath];
                self.self.draggingView = self.draggingView;
            }
            
            if (self.draggingView) {
                printf("began dragging view\n");
                if (!self.fieldView) {
                    [self createFieldViewOnTopOf:self.baseView];
                }
                
                initialDraggingViewCenter = self.draggingView.center;
                
                CGPoint touchPointInDragingView = [self.baseView convertPoint:touchPointGlobal toView:self.draggingView];
                deltaVector = CGPointMake(CGRectGetMidX(self.draggingView.bounds) - touchPointInDragingView.x,
                                          CGRectGetMidY(self.draggingView.bounds) - touchPointInDragingView.y);
                
                //remove from Source CollectionView
                [self.draggingView removeFromSuperview];
                
                //delegate methods to handle datasource
                if (self.delegate && [self.delegate respondsToSelector:@selector(canDragItemAtIndexPath:fromView:)]) {
                    BOOL canDrag = [self.delegate canDragItemAtIndexPath:self.draggingFromContainerIndexPath
                                                                fromView:self.draggingFromCollectionView];
                    if (canDrag) {
                        if ([self.delegate respondsToSelector:@selector(dragBeganFromView:atIndexPath:)]) {
                            [self.delegate dragBeganFromView:self.draggingFromCollectionView
                                                 atIndexPath:self.draggingFromContainerIndexPath];
                        }
                    }
                }
                
                //adding to temp field
                self.draggingView.center = CGPointMake(touchPointGlobal.x + deltaVector.x, touchPointGlobal.y + deltaVector.y);
                [self.fieldView addSubview:self.draggingView];
                
                //animation
                [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.draggingView) {
                printf("dragging view\n");
                //moving object itself
                self.draggingView.center = CGPointMake(touchPointGlobal.x + deltaVector.x, touchPointGlobal.y + deltaVector.y);
                
                UICollectionView *currentCollectionReceiver = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
                BOOL isInOtherCollection = self.draggingFromCollectionView != currentCollectionReceiver;
                
                if (isInOtherCollection) {
                    CGPoint pointInReceiver = [sender locationInView:currentCollectionReceiver];
                    NSIndexPath *overridingIndexPath = [currentCollectionReceiver indexPathForItemAtPoint:pointInReceiver];
                    if (overridingIndexPath) {
                        NSInteger indexInReceiver = overridingIndexPath.row;
                        printf("will add to %ld", indexInReceiver);
                        //TODO data and View update
                    }
                }
                
                /*
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
                [self.destinationView updateInteractiveMovementTargetPosition:[sender locationInView:self.destinationView]];*/
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            //TODO  View animation update
            /*gotToReceiver = NO;
            [self.destinationView endInteractiveMovement];*/
            
            if (self.fieldView) {
                [self.draggingView removeFromSuperview];
                
//                UIView *receiverView = [self findViewForPoint:touchPointGlobal inView:baseView dragble:NO receivable:YES];
                UICollectionView *currentCollectionReceiver = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
                
                if (currentCollectionReceiver) {
                    if (currentCollectionReceiver != self.draggingFromCollectionView) {
                        CGPoint pointInReceiver = [sender locationInView:currentCollectionReceiver];
                        NSIndexPath *currentReceiverIndexPath = [currentCollectionReceiver indexPathForItemAtPoint:pointInReceiver];
                        if (self.delegate && [self.delegate respondsToSelector:@selector(draggedFromCollectionView:atIndexPath:toCollectionView:atIndexPath:)]) {
                            [self.delegate draggedFromCollectionView:self.draggingFromCollectionView
                                                         atIndexPath:self.draggingFromContainerIndexPath
                                                    toCollectionView:currentCollectionReceiver
                                                         atIndexPath:currentReceiverIndexPath];
                            [self.sourceView reloadData];
                            [self.destinationView reloadData];
                            [self printData]; //logging
                            
                            //adding CellView to Receiver
                            CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal toView:currentCollectionReceiver];
                            CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                            self.draggingView.center = newCenterWithDelta;
                            [currentCollectionReceiver addSubview:self.draggingView];
                            
                            //animation
                            [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                        }
                    } else { //ReceiverView == SenderView
                        [self.draggingFromCollectionView addSubview:self.draggingView];
                        
                        //adding CellView back to Sender
                        CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal toView:self.draggingFromCollectionView];
                        CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                        self.draggingView.center = newCenterWithDelta;
                        
                        //animation
                        [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                        [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{ self.draggingView.center = initialDraggingViewCenter; } completion:nil];
                    }
                }
                
                //deallocating
                self.draggingView = nil;
                [self.fieldView removeFromSuperview];
                self.fieldView = nil;
                
               
                /*
                if (currentCollectionReceiver && currentCollectionReceiver != draggingFromCollectionView) {
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
                    
                    CGPoint newCenter = [baseView convertPoint:touchPointGlobal toView:currentCollectionReceiver];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    draggingView.center = newCenterWithDelta;
                    [currentCollectionReceiver addSubview:draggingView];
                    
                    [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                } else {
                    [draggingFromCollectionView addSubview:draggingView];
                    
                    CGPoint newCenter = [baseView convertPoint:touchPointGlobal toView:draggingFromCollectionView];
                    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                    draggingView.center = newCenterWithDelta;
                    
                    [UIView animateWithDuration:0.3f animations:^{ draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{ draggingView.center = initialDraggingViewCenter; } completion:nil];
                }
                
                //deallocating
                draggingView = nil;
                [self.fieldView removeFromSuperview];
                self.fieldView = nil;*/
            }
            break;
        default:
            break;
    }
    
}


#pragma mark - Data Source Handling
////TODO reordering data logic is here
//- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
//    NSLog(@"\nchanged \n%@", self.choosedTagsData);
//    NSLog(@"Source: %@ Destination: %@", sourceIndexPath, destinationIndexPath);
//
//    NSLog(@"\nchanged \n%@", self.choosedTagsData);
//    [self.destinationView reloadData];
//
//}

#pragma mark - Additional methods

- (UICollectionView *)getDraggedCollectionViewFromBasePoint: (CGPoint)point {
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

- (void)createFieldViewOnTopOf:(UIView *)currentView {
    self.fieldView = [[UIView alloc] initWithFrame:currentView.frame];
    UIColor *transparentColor = [UIColor colorWithWhite:1.f alpha:0.f];
    [self.fieldView setBackgroundColor:transparentColor];
    [currentView addSubview:self.fieldView];
}

- (void)printData {
    NSLog(@"TODO printing data here...");
//    NSLog(@"\n%@ \n\n%@", self.tagsData, self.choosedTagsData);
}

/*
 - (BOOL)isPoint: (CGPoint)point fromView: (UIView *)superVeiw isInsideView:(UIView *)view {
 CGPoint insideViewPoint = [superVeiw convertPoint:point toView:view];
 BOOL result = [view pointInside:insideViewPoint withEvent:nil];
 
 return result;
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
} */

@end
