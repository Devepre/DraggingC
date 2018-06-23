#import <UIKit/UIKit.h>

@interface UIView (DragAndDrop)

@property (assign, getter=isDragable) BOOL   dragable;
@property (assign, getter=isReceivable) BOOL receivable;

- (NSMutableArray *) allSubViews;

@end
