#import <Foundation/Foundation.h>
@class UIView;

@protocol DragDealerProtocol

@optional

- (void)dragFromSourceStartedAtIndexPath: (NSIndexPath *) path;

@end

@interface DragDealer : NSObject

@property (weak, nonatomic) UIView *sourceView;
@property (weak, nonatomic) UIView *destinationView;
@property (weak, nonatomic) NSObject<DragDealerProtocol> *delegate;

@property (assign, nonatomic, getter=isSourceReceivable) BOOL sourceReceivable;
@property (assign, nonatomic, getter = isDestinationReceivable) BOOL destinationReceivable;

@end
