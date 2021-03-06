#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol DragDealerProtocol

@optional
- (BOOL) canDragItemFromView: (UICollectionView *)view
                 atIndexPath: (NSIndexPath *)path;

- (void) dragBeganFromView: (UICollectionView *)view
               atIndexPath: (NSIndexPath *)path;

@required
- (void) draggedFromCollectionView: (UICollectionView *)fromView
                       atIndexPath: (NSIndexPath *)indexFrom
                  toCollectionView: (UICollectionView *)toView
                       atIndexPath: (NSIndexPath *)indexTo;

- (void) dropCopyObjectFromCollectionView: (UICollectionView *)fromView
                              atIndexPath: (NSIndexPath *)indexFrom
                         toCollectionView: (UICollectionView *)toView
                              atIndexPath: (NSIndexPath *)indexTo;

- (void) deleteObjectFromCollectionView: (UICollectionView *) fromView
                            atIndexPath: (NSIndexPath *)indexFrom;

@end

@interface DragDealer : NSObject <UIGestureRecognizerDelegate>

@property (weak, nonatomic) UIView *baseView;
@property (weak, nonatomic) UICollectionView *sourceView;
@property (weak, nonatomic) UICollectionView *destinationView;
@property (weak, nonatomic) NSObject<DragDealerProtocol> *delegate;

@property (assign, nonatomic, getter=isScaled) BOOL scaled;
@property (assign, nonatomic, getter=isSimulatniouslyScrollAndDragAllowed) BOOL simultaneouslyScrollAndDragAllowed;
@property (assign, nonatomic) CGFloat selectionScale;

- (instancetype)initWithBaseView: (UIView *)baseView
                   andSourceView: (UICollectionView *)sourceView
              andDestinationView: (UICollectionView *)destinationView
                     andDelegate: (NSObject<DragDealerProtocol> *)delegate
             andLongPressEnabled: (BOOL)longPressEnabled NS_DESIGNATED_INITIALIZER;

@end

