#import "DragDealer.h"
#import <UIKit/UIkit.h>

@implementation DragDealer

- (instancetype)initWithSourceView: (UIView *)sourceView
                andDestinationView: (UIView *)destinationView
                       andDelegate: (NSObject<DragDealerProtocol> *) delegate {
    self = [super init];
    if (self) {
        _sourceView = sourceView;
        _destinationView = destinationView;
        _delegate = delegate;
        
        // default usage
        _sourceReceivable = YES;
        _destinationReceivable = YES;
        
    }
    return self;
}

@end
