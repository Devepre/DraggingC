#import "DragDealer.h"
#import <UIKit/UIkit.h>

@interface DragDealer ()

@property (strong, nonatomic) UIView *fieldView;
@property (strong, nonatomic) UICollectionView *draggingFromCollectionView;
@property (strong, nonatomic) UICollectionViewCell *draggingView;
@property (assign, nonatomic) NSIndexPath *draggingFromContainerIndexPath;

@property (assign, nonatomic) CGPoint initialDraggingViewCenter;
@property (assign, nonatomic) CGPoint deltaVector;
@property (assign, nonatomic) CGPoint initialGlobalPoint;
@property (assign, nonatomic) BOOL gotToReceiver;
@property (assign, nonatomic) BOOL leaveFromReceiver;
@property (strong, nonatomic) UICollectionView *currentCollectionReceiver;
@property (strong, nonatomic) UICollectionView *oldCollectionReceiver;

@property (strong, nonatomic) NSIndexPath *overridingIndexPath;
@property (strong, nonatomic) NSIndexPath *oldOverridingIndexPath;
@property (assign, nonatomic) BOOL itemWasDropped;

@end

@implementation DragDealer

- (instancetype)init {
    self = [self initWithBaseView:nil andSourceView:nil andDestinationView:nil andDelegate:nil andLongPressEnabled:NO];
    return self;
}

- (instancetype)initWithBaseView: (UIView *)baseView
                   andSourceView: (UICollectionView *)sourceView
              andDestinationView: (UICollectionView *)destinationView
                     andDelegate: (NSObject<DragDealerProtocol> *)delegate
             andLongPressEnabled: (BOOL)longPressEnabled {
    self = [super init];
    if (self) {
        _baseView = baseView;
        _sourceView = sourceView;
        _destinationView = destinationView;
        _delegate = delegate;
        
        //gesture creation
        if (longPressEnabled) {
            NSLog(@"Long");
            UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                     action:@selector(handlePan:)];
            longGesture.delegate = self;
            [_baseView addGestureRecognizer:longGesture];
        } else {
            NSLog(@"Pan");
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(handlePan:)];
            panGesture.delegate = self;
            [_baseView addGestureRecognizer:panGesture];
        }
        
        // default usage
        _scaled = YES;
        
    }
    return self;
}

#pragma mark - Gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return self.simultaneouslyScrollAndDragAllowed;
}

//- (void)handlePan:(UIPanGestureRecognizer *)sender {
- (void)handlePan:(UIGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self performDragVeryBeginningUsingGesture:sender];
            break;
        case UIGestureRecognizerStateChanged:
            if (self.draggingView) {
                [self performDraggingUsingGesture:sender];
            } else {
                //nothing to move
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self performDragFinishUsingGesture:sender];
            break;
        default:
            break;
    }
    
}

#pragma mark - Dragging Gestures Handling

- (void)performDragVeryBeginningUsingGesture: (UIGestureRecognizer *)sender {
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    
    if (!self.draggingView) {
//        printf("not dragging view exist\n");
        self.draggingFromCollectionView = [self getDraggedCollectionViewFromBasePoint:touchPointGlobal];
        CGPoint draggingPoint = [self.baseView convertPoint:touchPointGlobal
                                                     toView:self.draggingFromCollectionView];
        self.draggingFromContainerIndexPath = [self.draggingFromCollectionView indexPathForItemAtPoint:draggingPoint];
        self.draggingView = [self.draggingFromCollectionView cellForItemAtIndexPath:self.draggingFromContainerIndexPath];
    }
    
    if (self.draggingView) {
        //delegate methods to handle datasource
        if (self.delegate && [self.delegate respondsToSelector:@selector(canDragItemFromView:atIndexPath:)]) {
            BOOL canDrag = [self.delegate canDragItemFromView:self.draggingFromCollectionView
                                                  atIndexPath:self.draggingFromContainerIndexPath];
            if (canDrag) {
                [self performDragBegan:&touchPointGlobal];
            } else { //delegate doesn't allow to drag this view
                self.draggingView = nil;
            }
        }
    }
}

- (void)performDragBegan:(const CGPoint *)touchPointGlobal {
    self.itemWasDropped = NO;
    self.gotToReceiver = NO;
    self.leaveFromReceiver = NO;
    
    if ([self.delegate respondsToSelector:@selector(dragBeganFromView:atIndexPath:)]) {
        [self.delegate dragBeganFromView:self.draggingFromCollectionView
                             atIndexPath:self.draggingFromContainerIndexPath];
    }
    
    if (!self.fieldView) {
        [self createFieldViewOnTopOf:self.baseView];
    }
    
    self.initialDraggingViewCenter = self.draggingView.center;
    self.initialGlobalPoint = *touchPointGlobal;
    
    CGPoint touchPointInDragingView = [self.baseView convertPoint:*touchPointGlobal
                                                           toView:self.draggingView];
    self.deltaVector = CGPointMake(CGRectGetMidX(self.draggingView.bounds) - touchPointInDragingView.x,
                                   CGRectGetMidY(self.draggingView.bounds) - touchPointInDragingView.y);
    
    //remove from Source CollectionView
    [self.draggingView removeFromSuperview];
    
    //adding to temp field
    self.draggingView.center = CGPointMake(touchPointGlobal->x + self.deltaVector.x, touchPointGlobal->y + self.deltaVector.y);
//    printf("adding to temp field\n");
    [self.fieldView addSubview:self.draggingView];
    
    if (self.isSacled) { //begin animation
        [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
    }
}

- (void)performDraggingUsingGesture:(UIGestureRecognizer *)sender {
    //moving object itself
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    self.draggingView.center = CGPointMake(touchPointGlobal.x + self.deltaVector.x, touchPointGlobal.y + self.deltaVector.y);
    
    if (self.currentCollectionReceiver && self.currentCollectionReceiver != [self getDraggedCollectionViewFromBasePoint:self.draggingView.center]) {
        self.oldCollectionReceiver = self.currentCollectionReceiver;
    } else {
        self.oldCollectionReceiver = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
    }
    self.currentCollectionReceiver = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
    BOOL isInOtherCollection = self.draggingFromCollectionView != self.currentCollectionReceiver;
    printf("Current Receiver Tag: %ld\n", (long)self.currentCollectionReceiver.tag);
    printf("is in other collection: %s\n", isInOtherCollection ? "yes" : "no");
    UILabel *temp = (UILabel *)[[self.draggingView.subviews objectAtIndex:0].subviews objectAtIndex:0];
    printf("%s\n", [temp.text UTF8String]);
    
    
    if (isInOtherCollection) {
        //        printf("Is in other collection\n");
        CGPoint pointInReceiver = [sender locationInView:self.currentCollectionReceiver];
        self.overridingIndexPath = [self.currentCollectionReceiver indexPathForItemAtPoint:pointInReceiver];
        if (self.overridingIndexPath) {
            self.oldOverridingIndexPath = self.overridingIndexPath;
            //            printf("inside bottom and index = %ld\n", (long)indexInReceiver.item);
            if (!self.gotToReceiver) {
                self.gotToReceiver = YES;
                
                printf("GOT TO RECEIVER\n");
                if (self.delegate && [self.delegate respondsToSelector:@selector(dropCopyObjectFromCollectionView:atIndexPath:toCollectionView:atIndexPath:)]) {
                    [self.delegate dropCopyObjectFromCollectionView:self.draggingFromCollectionView
                                                    atIndexPath:self.draggingFromContainerIndexPath
                                               toCollectionView:self.currentCollectionReceiver
                                                    atIndexPath:self.overridingIndexPath];
                    //                [self.choosedTagsData insertObject:[self.tagsData objectAtIndex:index] atIndex:indexInBottom];
                    self.itemWasDropped = YES;
                    
                    printf("Insert at IndexPath: %ld\n", (long)self.overridingIndexPath.item);
                    [self.currentCollectionReceiver insertItemsAtIndexPaths:@[self.overridingIndexPath]];
                    [self.currentCollectionReceiver cellForItemAtIndexPath:self.overridingIndexPath].hidden = YES;
//                    [self.currentCollectionReceiver reloadData];
                }
                [self.currentCollectionReceiver beginInteractiveMovementForItemAtIndexPath:self.overridingIndexPath];
            } else {
                
            }
            // else continue interactive movement
            [self.currentCollectionReceiver updateInteractiveMovementTargetPosition:[sender locationInView:self.destinationView]];
            ///////
        } else { // not overriding indexPath == check if leave
//            UICollectionView *temp = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
//            if (self.gotToReceiver && temp != self.oldCollectionReceiver) {
            if (self.gotToReceiver) {
                printf("LEAVING from IndexPath\n");
                self.leaveFromReceiver = YES;
                self.gotToReceiver = NO;
                
                [self.oldCollectionReceiver endInteractiveMovement];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(deleteObjectFromCollectionView:atIndexPath:)]) {
                    self.itemWasDropped = NO;
                    printf("IndexPath: %ld\n", (long)self.oldOverridingIndexPath.item);
                    printf("send DELETE to delegate with prev indexpath\n");
                    printf("current old collection receiver: %ld\n", (long)self.oldCollectionReceiver.tag);
                    [self.delegate deleteObjectFromCollectionView:self.oldCollectionReceiver
                                                      atIndexPath:self.oldOverridingIndexPath];
                    printf("\nONE\n");
                    [self.oldCollectionReceiver cellForItemAtIndexPath:self.oldOverridingIndexPath].hidden = NO;
                    [self.oldCollectionReceiver deleteItemsAtIndexPaths:@[self.oldOverridingIndexPath]];
                    printf("\nTWO\n");
                }
            }
        }
    }
    
}

- (void)performDragFinishUsingGesture:(UIGestureRecognizer *)sender {
    self.gotToReceiver = NO;
    [self.currentCollectionReceiver cellForItemAtIndexPath:self.overridingIndexPath].hidden = NO;
    [self.currentCollectionReceiver endInteractiveMovement];
    
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    
    if (self.fieldView) {
        UICollectionView *currentCollectionReceiver = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
        
        if (currentCollectionReceiver) {
            if (currentCollectionReceiver != self.draggingFromCollectionView) {
                CGPoint pointInReceiver = [sender locationInView:currentCollectionReceiver];
                NSIndexPath *currentReceiverIndexPath = [currentCollectionReceiver indexPathForItemAtPoint:pointInReceiver];
                
                if (!currentReceiverIndexPath) { //dragged to outside of any index - add to the end
                    NSInteger lastSection = [currentCollectionReceiver numberOfSections] - 1;
                    NSInteger lastItem = [currentCollectionReceiver numberOfItemsInSection:lastSection];
                    currentReceiverIndexPath = [NSIndexPath indexPathForItem:lastItem inSection:lastSection];
                }
                
                printf("index path during END of drag is: %ld\n", (long)currentReceiverIndexPath.item);
                
                if (self.delegate) {
                    if (self.itemWasDropped && [self.delegate respondsToSelector:@selector(deleteObjectFromCollectionView:atIndexPath:)]) {
                        printf("item was already dropped\n");
//                        currentCollectionReceiver = nil; //hack
                        [self.delegate deleteObjectFromCollectionView:self.draggingFromCollectionView
                                                          atIndexPath:self.draggingFromContainerIndexPath];
                        [self.draggingFromCollectionView deleteItemsAtIndexPaths:@[self.draggingFromContainerIndexPath]];
                    } else if ([self.delegate respondsToSelector:@selector(draggedFromCollectionView:atIndexPath:toCollectionView:atIndexPath:)]) { //item was not dropped already
                        [self.delegate draggedFromCollectionView:self.draggingFromCollectionView
                                                     atIndexPath:self.draggingFromContainerIndexPath
                                                toCollectionView:currentCollectionReceiver
                                                     atIndexPath:currentReceiverIndexPath];
                        [self.draggingFromCollectionView deleteItemsAtIndexPaths:@[self.draggingFromContainerIndexPath]];
                        [currentCollectionReceiver insertItemsAtIndexPaths:@[currentReceiverIndexPath]];
                    }
                    
                }
                [self.draggingView removeFromSuperview];
                
                //assume data was changed by delegate
//                [self.sourceView reloadData];
//                [self.destinationView reloadData];
                
                /*[self.draggingView removeFromSuperview];
                //adding CellView to Receiver
                CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal toView:currentCollectionReceiver];
                CGPoint newCenterWithDelta = CGPointMake(newCenter.x + self.deltaVector.x, newCenter.y + self.deltaVector.y);
                self.draggingView.center = newCenterWithDelta;
                [currentCollectionReceiver addSubview:self.draggingView];
                
                if (self.isSacled) {
                    [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                }
                [self finalizeDragProcess]; */
                
                [self finalizeDragProcess];
            } else { //ReceiverView == SenderView
                [self undoDraggingFromBasePoint:touchPointGlobal
                                 withDeltaPoint:self.deltaVector
                           toInitialCenterPoint:self.initialDraggingViewCenter];
            }
        } else { //ReceiverView is not valid
            [self undoDraggingFromInvalidSourceToGlobalPoint:self.initialGlobalPoint
                                              withDeltaPoint:self.deltaVector];
        }
    }
}

#pragma mark - Additional methods

- (void)finalizeDragProcess {
    self.draggingView = nil;
    [self.fieldView removeFromSuperview];
    self.fieldView = nil;
}

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

- (void)undoDraggingFromBasePoint: (CGPoint)touchPointGlobal withDeltaPoint: (CGPoint)deltaVector toInitialCenterPoint: (CGPoint)initialDraggingViewCenter {
    [self.draggingView removeFromSuperview];
    
    //adding CellView back to Sender
    CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal toView:self.draggingFromCollectionView];
    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
    self.draggingView.center = newCenterWithDelta;
    
    if (self.isSacled) {
        [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
    }
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{ self.draggingView.center = initialDraggingViewCenter; } completion:nil];
    
    [self.draggingFromCollectionView addSubview:self.draggingView];
    [self finalizeDragProcess];
}

- (void)undoDraggingFromInvalidSourceToGlobalPoint: (CGPoint)initialGlobalPoint withDeltaPoint: (CGPoint)deltaVector {
    printf("undo from invalid\n");
    CGPoint newGlobalCenter = CGPointMake(initialGlobalPoint.x + deltaVector.x, initialGlobalPoint.y + deltaVector.y);
    
    void (^discardDragProcess)(BOOL finished) = ^ (BOOL finished) {
        [self.draggingView removeFromSuperview];
        
        //adding CellView back to Sender
        CGPoint newCenter = [self.baseView convertPoint:self.draggingView.center toView:self.draggingFromCollectionView];
        self.draggingView.center = newCenter;
        
        [self.draggingFromCollectionView addSubview:self.draggingView];
        [self finalizeDragProcess];
    };
    
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.draggingView.center = newGlobalCenter;
                     } completion:discardDragProcess];
    
    if (self.isSacled) {
        [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
    } else {
#pragma GCC diagnostic ignored "-Wunused-value"
        discardDragProcess;
    }
}

@end

