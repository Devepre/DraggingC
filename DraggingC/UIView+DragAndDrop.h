#import <UIKit/UIKit.h>

@interface UIView (DragAndDrop)

@property (assign, getter=isDragable) BOOL dragable;
@property (weak) UIView *superView;

- (NSMutableArray*) allSubViews;

@end
