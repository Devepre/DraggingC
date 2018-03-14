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
    static CGPoint initialDraggingViewCenter;
    static CGPoint deltaVector;
    static CGPoint initialGlobalPoint;
    
    CGPoint touchPointGlobal = [sender locationInView:self.baseView];
//    static int indexInBottom;
    static BOOL gotToReceiver;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            if (!self.draggingView) {
                printf("got new drag view\n");
                self.draggingFromCollectionView = [self getDraggedCollectionViewFromBasePoint:touchPointGlobal];
                CGPoint draggingPoint = [self.baseView convertPoint:touchPointGlobal
                                                             toView:self.draggingFromCollectionView];
                self.draggingFromContainerIndexPath = [self.draggingFromCollectionView indexPathForItemAtPoint:draggingPoint];
                self.draggingView = [self.draggingFromCollectionView cellForItemAtIndexPath:self.draggingFromContainerIndexPath];
            }
            
            if (self.draggingView) {
                if (!self.fieldView) {
                    [self createFieldViewOnTopOf:self.baseView];
                }
                
                printf("already have object to drag\n");
                
                initialDraggingViewCenter = self.draggingView.center;
                initialGlobalPoint = touchPointGlobal;
                
                CGPoint touchPointInDragingView = [self.baseView convertPoint:touchPointGlobal
                                                                       toView:self.draggingView];
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
                
                if (self.isSacled) { //begin animation
                    [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);}];
                }
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.draggingView) {
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
                        CGPoint newCenterWithDelta = CGPointMake(newCenter.x + deltaVector.x, newCenter.y + deltaVector.y);
                        self.draggingView.center = newCenterWithDelta;
                        [currentCollectionReceiver addSubview:self.draggingView];
                        
                        if (self.isSacled) {
                            [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
                        }
                    } else { //ReceiverView == SenderView
                        [self undoDraggingFromBasePoint:touchPointGlobal
                                         withDeltaPoint:deltaVector
                                   toInitialCenterPoint:initialDraggingViewCenter];
                    }
                } else { //ReceiverView is not valid
                    [self undoDraggingFromInvalidSourceToGlobalPoint:initialGlobalPoint
                                                      withDeltaPoint:deltaVector];
                }
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

- (void)discardDragProcess {
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
    [self discardDragProcess];
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
        [self discardDragProcess];
    };
    
    [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.draggingView.center = newGlobalCenter;
                     } completion:discardDragProcess];
    
    if (self.isSacled) {
        [UIView animateWithDuration:.3f animations:^{ self.draggingView.transform = CGAffineTransformMakeScale(1.f, 1.f);}];
    } else {
        discardDragProcess;
    }
}

- (void)printData {
    NSLog(@"TODO printing data here...");
//    NSLog(@"\n%@ \n\n%@", self.tagsData, self.choosedTagsData);
}

@end
