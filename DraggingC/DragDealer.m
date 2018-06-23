#import "DragDealer.h"
#import <UIKit/UIkit.h>

@interface DragDealer ()

@property (strong, nonatomic) UICollectionViewCell   *draggingView;
@property (strong, nonatomic) UIView                 *fieldView;
@property (strong, nonatomic) UICollectionView       *draggingFromCollectionView;
@property (strong, nonatomic) UICollectionView       *currentCollectionReceiver;
@property (strong, nonatomic) UICollectionView       *previousCollectionReceiver;

@property (assign, nonatomic) CGPoint initialGlobalPoint;
@property (assign, nonatomic) CGPoint initialDraggingViewCenter;
@property (assign, nonatomic) CGPoint deltaVector;

@property (assign, nonatomic) NSIndexPath *draggingFromContainerIndexPath;
@property (strong, nonatomic) NSIndexPath *overridingIndexPath;
@property (strong, nonatomic) NSIndexPath *previousOverridingIndexPath;

@property (assign, nonatomic) BOOL gotToReceiver;
@property (assign, nonatomic) BOOL leaveFromReceiver;
@property (assign, nonatomic) BOOL itemWasDropped;

@end

@implementation DragDealer

- (instancetype)init {
    return nil;
}


- (instancetype)initWithBaseView:(UIView *)baseView
                      sourceView:(UICollectionView *)sourceView
                 destinationView:(UICollectionView *)destinationView
                        delegate:(NSObject<DragDealerProtocol> *)delegate
                longPressEnabled:(BOOL)longPressEnabled {
    self = [super init];
    if (self) {
        _baseView = baseView;
        _sourceView = sourceView;
        _destinationView = destinationView;
        _delegate = delegate;
        
        //appropriate gesture creation
        if (longPressEnabled) {
            printf("Long gesture is enabled\n");
            UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc]
                                                         initWithTarget:self
                                                         action:@selector(handlePan:)];
            longGesture.delegate = self;
            [_baseView addGestureRecognizer:longGesture];
        } else {
            printf("Pan gesture is enabled\n");
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                                  initWithTarget:self
                                                  action:@selector(handlePan:)];
            panGesture.delegate = self;
            [_baseView addGestureRecognizer:panGesture];
        }
        
        // default usage
        _scaled = YES;
        _selectionScale = 1.2f;
        
    }
    
    return self;
}

#pragma mark - Gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return self.simultaneouslyScrollAndDragAllowed;
}


- (void)handlePan:(UIGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self performDragVeryBeginningUsingGesture:sender];
            break;
        case UIGestureRecognizerStateChanged:
            if (self.draggingView) {
                [self performDraggingUsingGesture:sender];
            } else { /* nothing actually to move */
                printf("There is no actual view to move now\n");
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

- (void)performDragVeryBeginningUsingGesture:(UIGestureRecognizer *)sender {
    self.initialGlobalPoint = [sender locationInView:self.baseView];
    
    // Get initial data from container - what to drag and from where
    if (!self.draggingView) {
        self.draggingFromCollectionView = [self getDraggedCollectionViewFromBasePoint:self.initialGlobalPoint];
        CGPoint draggingPoint = [self.baseView convertPoint:self.initialGlobalPoint
                                                     toView:self.draggingFromCollectionView];
        self.draggingFromContainerIndexPath = [self.draggingFromCollectionView indexPathForItemAtPoint:draggingPoint];
        self.draggingView = [self.draggingFromCollectionView cellForItemAtIndexPath:self.draggingFromContainerIndexPath];
    }
    
    // Perform dragging if there is something to drag
    if (self.draggingView) {
        // Delegate methods to handle datasource
        if (self.delegate && [self.delegate respondsToSelector:@selector(canDragItemFromView:atIndexPath:)]) {
            BOOL canDrag = [self.delegate canDragItemFromView:self.draggingFromCollectionView
                                                  atIndexPath:self.draggingFromContainerIndexPath];
            if (canDrag) {
                [self performDragBegan];
            } else { //delegate doesn't allow to drag this view
                self.draggingView = nil;
            }
        } else { // As default it's allowed to drag the view if delegate doesn't report anything
            [self performDragBegan];
        }
    }
}


- (void)performDragBegan {
    // Invokation of optional delegate's method if any
    if ([self.delegate respondsToSelector:@selector(dragBeganFromView:atIndexPath:)]) {
        [self.delegate dragBeganFromView:self.draggingFromCollectionView
                             atIndexPath:self.draggingFromContainerIndexPath];
    }
    
    // Creating View where dragging will be occure
    if (!self.fieldView) {
        [self createFieldViewOnTopOf:self.baseView];
    }
    
    // Getting info about touch point inside dragging view
    self.initialDraggingViewCenter = self.draggingView.center;
    CGPoint touchPointInDragingView = [self.baseView convertPoint:self.initialGlobalPoint
                                                           toView:self.draggingView];
    self.deltaVector = CGPointMake(CGRectGetMidX(self.draggingView.bounds) - touchPointInDragingView.x,
                                   CGRectGetMidY(self.draggingView.bounds) - touchPointInDragingView.y);
    
    // Remove from Source CollectionView
    [self.draggingView removeFromSuperview];
    
    // Adding to temp field with delta coordinates included
    self.draggingView.center = CGPointMake(self.initialGlobalPoint.x + self.deltaVector.x,
                                           self.initialGlobalPoint.y + self.deltaVector.y);
    [self.fieldView addSubview:self.draggingView];
    
    if (self.isScaled) { //begin animation
        [UIView animateWithDuration:.3f
                         animations:^{
                             self.draggingView.transform = CGAffineTransformMakeScale(self.selectionScale,
                                                                                      self.selectionScale);
                         }];
    }
}


- (void)performDraggingUsingGesture:(UIGestureRecognizer *)sender {
    // Moving object itself
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    self.draggingView.center = CGPointMake(touchPointGlobal.x + self.deltaVector.x,
                                           touchPointGlobal.y + self.deltaVector.y);
    
    // Get what is the previousCollectionReceiver
    UICollectionView *collectionViewUnderDraggingView = [self getDraggedCollectionViewFromBasePoint:self.draggingView.center];
    if (self.currentCollectionReceiver && self.currentCollectionReceiver != collectionViewUnderDraggingView) {
        self.previousCollectionReceiver = self.currentCollectionReceiver;
    } else {
        self.previousCollectionReceiver = collectionViewUnderDraggingView;
    }
    
    self.currentCollectionReceiver = collectionViewUnderDraggingView;
    
    BOOL isInOtherCollection = self.draggingFromCollectionView != self.currentCollectionReceiver;
    
    printf("Current Receiver Tag: %ld\n", (long)self.currentCollectionReceiver.tag);
    printf("is in other collection: %s\n", isInOtherCollection ? "yes" : "no");
    
    // TODO to remove this debug log
    UILabel *temp = (UILabel *)[[self.draggingView.subviews objectAtIndex:0].subviews objectAtIndex:0];
    printf("%s\n", [temp.text UTF8String]);
    
    if (isInOtherCollection) {
        CGPoint pointInReceiver = [sender locationInView:self.currentCollectionReceiver];
        self.overridingIndexPath = [self.currentCollectionReceiver indexPathForItemAtPoint:pointInReceiver];
        if (self.overridingIndexPath) {
            self.previousOverridingIndexPath = self.overridingIndexPath;
            
            // It means user moved object to the new IndexPath - need to start new InteractiveMovement and perform data changes
            if (!self.gotToReceiver) {
                self.gotToReceiver = YES;
                
                // Invoke delegate methods to handle datatsource change - drop object to Receiver in order to perform default animation
                if (self.delegate &&
                    [self.delegate respondsToSelector:@selector(dropCopyObjectFromCollectionView:atIndexPath:toCollectionView:atIndexPath:)]) {
                    [self.delegate dropCopyObjectFromCollectionView:self.draggingFromCollectionView
                                                        atIndexPath:self.draggingFromContainerIndexPath
                                                   toCollectionView:self.currentCollectionReceiver
                                                        atIndexPath:self.overridingIndexPath];
                    self.itemWasDropped = YES;
                    
                    // UI updates according to datasource changes
                    [self.currentCollectionReceiver insertItemsAtIndexPaths:@[self.overridingIndexPath]];
                    [self.currentCollectionReceiver cellForItemAtIndexPath:self.overridingIndexPath].hidden = YES; //need to hide because it's Copy of item
                }
                // Starting interaction movement for receiver
                [self.currentCollectionReceiver beginInteractiveMovementForItemAtIndexPath:self.overridingIndexPath];
            }
            // Else just continue interactive movement without any data changes
            [self.currentCollectionReceiver updateInteractiveMovementTargetPosition:[sender locationInView:self.destinationView]];
        
        } else { // Not over any indexPath - need to check if it leaves index or just didn't make over any index before
            if (self.gotToReceiver) { // Means Drag item is leaving from IndexPath and Receiver
                self.leaveFromReceiver = YES;
                self.gotToReceiver = NO;
                
                // need to finish Interactive Movement in order to start any new in future
                [self.previousCollectionReceiver endInteractiveMovement];
                
                // Invokde delegate to delelte previously created item Copy (needed for animation)
                if (self.delegate && [self.delegate respondsToSelector:@selector(deleteObjectFromCollectionView:atIndexPath:)]) {
                    self.itemWasDropped = NO;
                    [self.delegate deleteObjectFromCollectionView:self.previousCollectionReceiver
                                                      atIndexPath:self.previousOverridingIndexPath];

                    // UI updates - also need to show item since item# was changed and now some other item is hidden
                    [self.previousCollectionReceiver cellForItemAtIndexPath:self.previousOverridingIndexPath].hidden = NO;
                    [self.previousCollectionReceiver deleteItemsAtIndexPaths:@[self.previousOverridingIndexPath]];
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
                
                if (!currentReceiverIndexPath) { // Dragged to outside of any index - add to the end
                    NSInteger lastSection = [currentCollectionReceiver numberOfSections] - 1; // TODO to check 0 index
                    NSInteger lastItem = [currentCollectionReceiver numberOfItemsInSection:lastSection];
                    currentReceiverIndexPath = [NSIndexPath indexPathForItem:lastItem inSection:lastSection];
                }
                
                // Invoke delegate methods depending on item was allready dropped or it full drag-n-drop process
                if (self.delegate) {
                    if (self.itemWasDropped && [self.delegate respondsToSelector:@selector(deleteObjectFromCollectionView:atIndexPath:)]) {
                        [self.delegate deleteObjectFromCollectionView:self.draggingFromCollectionView
                                                          atIndexPath:self.draggingFromContainerIndexPath];
                        // UI update
                        [self.draggingFromCollectionView deleteItemsAtIndexPaths:@[self.draggingFromContainerIndexPath]];
                    } else if ([self.delegate respondsToSelector:@selector(draggedFromCollectionView:atIndexPath:toCollectionView:atIndexPath:)]) {
                        // Item was not dropped already
                        [self.delegate draggedFromCollectionView:self.draggingFromCollectionView
                                                     atIndexPath:self.draggingFromContainerIndexPath
                                                toCollectionView:currentCollectionReceiver
                                                     atIndexPath:currentReceiverIndexPath];
                        // UI update
                        [self.draggingFromCollectionView deleteItemsAtIndexPaths:@[self.draggingFromContainerIndexPath]];
                        [currentCollectionReceiver insertItemsAtIndexPaths:@[currentReceiverIndexPath]];
                    }
                    
                }
                [self.draggingView removeFromSuperview];
                
                /* //manually move back the item
                 [self.draggingView removeFromSuperview];
                //adding CellView to Receiver
                CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal toView:currentCollectionReceiver];
                CGPoint newCenterWithDelta = CGPointMake(newCenter.x + self.deltaVector.x, newCenter.y + self.deltaVector.y);
                self.draggingView.center = newCenterWithDelta;
                [currentCollectionReceiver addSubview:self.draggingView];
                
                if (self.isScaled) {
                    [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                }
                [self finalizeDragProcess]; */
                
                [self finalizeDragProcess];
            } else { // ReceiverView == SenderView
                [self undoDraggingFromBasePoint:touchPointGlobal
                                 withDeltaPoint:self.deltaVector
                           toInitialCenterPoint:self.initialDraggingViewCenter];
            }
        } else { // ReceiverView is not valid
            [self undoDraggingFromInvalidSourceToGlobalPoint:self.initialGlobalPoint
                                              withDeltaVector:self.deltaVector];
        }
    }
}

#pragma mark - Additional methods

- (void)finalizeDragProcess {
    self.draggingView = nil;
    [self.fieldView removeFromSuperview];
    self.fieldView = nil;
    
    // Setting additional data to the default values
    self.itemWasDropped = NO;
    self.gotToReceiver = NO;
    self.leaveFromReceiver = NO;
}

- (UICollectionView *)getDraggedCollectionViewFromBasePoint:(CGPoint)point {
    UICollectionView *result = nil;
    
    CGPoint pointInSource = [self.baseView convertPoint:point
                                                 toView:self.sourceView];
    CGPoint pointInDestination = [self.baseView convertPoint:point
                                                      toView:self.destinationView];
    
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


- (void)undoDraggingFromBasePoint:(CGPoint)touchPointGlobal
                   withDeltaPoint:(CGPoint)deltaVector
             toInitialCenterPoint:(CGPoint)initialDraggingViewCenter {
    
    [self.draggingView removeFromSuperview];
    
    // Adding CellView back to Sender
    CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal
                                             toView:self.draggingFromCollectionView];
    CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x,
                                             newCenter.y + deltaVector.y);
    self.draggingView.center = newCenterWithDelta;
    
    if (self.isScaled) {
        [UIView animateWithDuration:.3f
                         animations:^{
                             self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);
                         }];
    }
    [UIView animateWithDuration:.3f
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.draggingView.center = initialDraggingViewCenter;
                     }
                     completion:nil];
    
    [self.draggingFromCollectionView addSubview:self.draggingView];
    [self finalizeDragProcess];
}


- (void)undoDraggingFromInvalidSourceToGlobalPoint:(CGPoint)initialGlobalPoint
                                    withDeltaVector:(CGPoint)deltaVector {
    
    CGPoint newGlobalCenter = CGPointMake(initialGlobalPoint.x + deltaVector.x,
                                          initialGlobalPoint.y + deltaVector.y);
    
    void (^discardDragProcess)(BOOL finished) = ^ (BOOL finished) {
        [self.draggingView removeFromSuperview];
        
        // Adding CellView back to Sender
        CGPoint newCenter = [self.baseView convertPoint:self.draggingView.center
                                                 toView:self.draggingFromCollectionView];
        self.draggingView.center = newCenter;
        
        [self.draggingFromCollectionView addSubview:self.draggingView];
        [self finalizeDragProcess];
    };
    
    [UIView animateWithDuration:.3f
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.draggingView.center = newGlobalCenter;
                     }
                     completion:discardDragProcess];
    
    if (self.isScaled) {
        [UIView animateWithDuration:.3f
                         animations:^{
                             self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);
                         }];
    } else {
#pragma GCC diagnostic ignored "-Wunused-value"
        discardDragProcess;
    }
}

@end

