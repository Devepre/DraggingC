#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//@class UIGestureRecognizer;
//@class UIView;

@protocol DragDealerProtocol

@optional

- (BOOL) canDragItemAtIndexPath: (NSIndexPath *)path
                      fromView: (UICollectionView *)view;

- (void) dragBeganFromView: (UICollectionView *)view
               atIndexPath: (NSIndexPath *)path;

- (void) draggedFromCollectionView: (UICollectionView *)fromView
                       atIndexPath: (NSIndexPath *)indexFrom
                  toCollectionView: (UICollectionView *)toView
                       atIndexPath: (NSIndexPath *)indexTo;

@end

@interface DragDealer : NSObject <UIGestureRecognizerDelegate>

@property (weak, nonatomic) UIView *baseView;
@property (weak, nonatomic) UICollectionView *sourceView;
@property (weak, nonatomic) UICollectionView *destinationView;
@property (weak, nonatomic) NSObject<DragDealerProtocol> *delegate;

@property (assign, nonatomic, getter=isSacled) BOOL scaled;
@property (assign, nonatomic, getter=isSourceReceivable) BOOL sourceReceivable;
@property (assign, nonatomic, getter = isDestinationReceivable) BOOL destinationReceivable;

- (instancetype)initWithBaseView: (UIView *)baseView
                   andSourceView: (UICollectionView *)sourceView
              andDestinationView: (UICollectionView *)destinationView
                     andDelegate: (NSObject<DragDealerProtocol> *)delegate NS_DESIGNATED_INITIALIZER;

@end
