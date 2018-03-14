#import "DragDealer.h"
#import <UIKit/UIkit.h>

@interface DragDealer ()

@property (strong, nonatomic) UIView *fieldView;
@property (strong, nonatomic) UICollectionView *draggingFromCollectionView;
@property (strong, nonatomic) UICollectionViewCell *draggingView;
@property (assign, nonatomic) NSIndexPath *draggingFromContainerIndexPath;

// from static
@property (assign, nonatomic) CGPoint initialDraggingViewCenter;
@property (assign, nonatomic) CGPoint deltaVector;
@property (assign, nonatomic) CGPoint initialGlobalPoint;

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
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handlePan:)];
        panGesture.delegate = self;
        [_baseView addGestureRecognizer:panGesture];
        
        // default usage
        _sourceReceivable = YES;
        _destinationReceivable = YES;
        _scaled = YES;
        
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
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

- (void)performDragVeryBeginningUsingGesture: (UIPanGestureRecognizer *)sender {
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    
    if (!self.draggingView) {
        self.draggingFromCollectionView = [self getDraggedCollectionViewFromBasePoint:touchPointGlobal];
        CGPoint draggingPoint = [self.baseView convertPoint:touchPointGlobal
                                                     toView:self.draggingFromCollectionView];
        self.draggingFromContainerIndexPath = [self.draggingFromCollectionView indexPathForItemAtPoint:draggingPoint];
        self.draggingView = [self.draggingFromCollectionView cellForItemAtIndexPath:self.draggingFromContainerIndexPath];
    }
    
    if (self.draggingView) {
        //delegate methods to handle datasource
        if (self.delegate && [self.delegate respondsToSelector:@selector(canDragItemAtIndexPath:fromView:)]) {
            BOOL canDrag = [self.delegate canDragItemAtIndexPath:self.draggingFromContainerIndexPath
                                                        fromView:self.draggingFromCollectionView];
            if (canDrag) {
                [self performDragBegan:&touchPointGlobal];
            } else { //delegate doesn't allow to drag this view
                self.draggingView = nil;
            }
        }
    }
}

- (void)performDragBegan:(const CGPoint *)touchPointGlobal {
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
    [self.fieldView addSubview:self.draggingView];
    
    if (self.isSacled) { //begin animation
        [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
    }
}

- (void)performDraggingUsingGesture:(UIPanGestureRecognizer *)sender {
    //moving object itself
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    self.draggingView.center = CGPointMake(touchPointGlobal.x + self.deltaVector.x, touchPointGlobal.y + self.deltaVector.y);
    
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

- (void)performDragFinishUsingGesture:(UIPanGestureRecognizer *)sender {
    //TODO  View animation update
    /*gotToReceiver = NO;
     [self.destinationView endInteractiveMovement];*/
    
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
    
    if (self.fieldView) {
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
                }
                //assume data was changed by delegate
                //                        [self.sourceView reloadData];
                //                        [self.destinationView reloadData];
                [self printData]; //logging
                
                [self.draggingView removeFromSuperview];
                //adding CellView to Receiver
                CGPoint newCenter = [self.baseView convertPoint:touchPointGlobal toView:currentCollectionReceiver];
                CGPoint newCenterWithDelta = CGPointMake(newCenter.x + self.deltaVector.x, newCenter.y + self.deltaVector.y);
                self.draggingView.center = newCenterWithDelta;
                [currentCollectionReceiver addSubview:self.draggingView];
                
                if (self.isSacled) {
                    [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                }
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
    //TODO HERE ANIMATION OF FIELDVIEW!
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

- (void)printData {
    NSLog(@"TODO printing data here...");
//    NSLog(@"\n%@ \n\n%@", self.tagsData, self.choosedTagsData);
}

@end
