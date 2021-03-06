#import "UIView+DragAndDrop.h"
#import <objc/runtime.h>

static void * DragAndDropDragablePropertyKey = &DragAndDropDragablePropertyKey;
static void * DragAndDropReceivablePropertyKey = &DragAndDropReceivablePropertyKey;

@implementation UIView (DragAndDrop)

- (void)setDragable:(BOOL)dragable {
    NSNumber *value = [NSNumber numberWithBool:dragable];
    objc_setAssociatedObject(self, DragAndDropDragablePropertyKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDragable {
    NSNumber *value = objc_getAssociatedObject(self, DragAndDropDragablePropertyKey);
    return [value boolValue];
}

- (void)setReceivable:(BOOL)receivable {
    NSNumber *value = [NSNumber numberWithBool:receivable];
    objc_setAssociatedObject(self, DragAndDropReceivablePropertyKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isReceivable {
    NSNumber *value = objc_getAssociatedObject(self, DragAndDropReceivablePropertyKey);
    return [value boolValue];
}

- (NSMutableArray*)allSubViews {
    NSMutableArray *arr=[[NSMutableArray alloc] init];
    [arr addObject:self];
    for (UIView *subview in self.subviews) {
        [arr addObjectsFromArray:(NSArray*)[subview allSubViews]];
    }
    return arr;
}

@end
