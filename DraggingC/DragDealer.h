#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DragDealerProtocol.h"
#import "UIView+DragAndDrop.m" // Not using for current class but need to be imported as part of Framework

@interface DragDealer : NSObject <UIGestureRecognizerDelegate>

@property (weak, nonatomic) UIView                       *baseView;
@property (weak, nonatomic) UICollectionView             *sourceView;
@property (weak, nonatomic) UICollectionView             *destinationView;
@property (weak, nonatomic) NSObject<DragDealerProtocol> *delegate;

@property (assign, nonatomic, getter=isScaled) BOOL scaled;
@property (assign, nonatomic, getter=isSimulatniouslyScrollAndDragAllowed) BOOL simultaneouslyScrollAndDragAllowed;
@property (assign, nonatomic) CGFloat selectionScale;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithBaseView:(UIView *)baseView
                      sourceView:(UICollectionView *)sourceView
                 destinationView:(UICollectionView *)destinationView
                        delegate:(NSObject<DragDealerProtocol> *)delegate
                longPressEnabled:(BOOL)longPressEnabled NS_DESIGNATED_INITIALIZER;

@end

