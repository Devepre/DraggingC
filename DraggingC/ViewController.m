#import "ViewController.h"
#import "UIView+DragAndDrop.h"

@interface ViewController ()

@property (strong) UIView *fieldView;

@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tagsData = [[NSMutableArray alloc] initWithObjects:@"stringOne", @"stringTwo", @"stringTrhee", nil];
    NSLog(@"init %@", _tagsData);
    
    
    self.backgroundView.dragable = NO;
    [self attachGesturesToView:self.backgroundView];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tagsData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell =  [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    UILabel *recipeView = (UILabel *)[cell viewWithTag:145];
    recipeView.text = [self.tagsData objectAtIndex:indexPath.row];
    
    cell.dragable = YES;
    
    return cell;
}


#pragma mark - Touches & Gestures
- (void)attachGesturesToView:(UIView *)view {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    static UIView *draggingView;
    
    UIView *currentView = sender.view;
    CGPoint touchPoint = [sender locationInView:currentView];
    printf("touchPoint: %f, %f\n", touchPoint.x, touchPoint.y);
    
    draggingView = [self findViewForPoint:touchPoint inView:sender.view];

    
    //    CGPoint translatedPoint = [sender translationInView:sender.view.superview];
    //    translatedPoint = CGPointMake(sender.view.center.x + translatedPoint.x, sender.view.center.y + translatedPoint.y);
    
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            if ([self isPoint:touchPoint fromView:currentView isInsideView:draggingView] && draggingView.isDragable) {
                printf("inside data view\n");
//                draggingView = self.dataView;
                
                if (!self.fieldView) {
                    self.fieldView = [[UIView alloc] initWithFrame:currentView.frame];
                    UIColor *transparentColor = [UIColor colorWithWhite:1.f alpha:0.f];
                    [self.fieldView setBackgroundColor:transparentColor];
                    [currentView addSubview:self.fieldView];
                }
                
                [draggingView removeFromSuperview];
                draggingView.center = touchPoint;
                [self.fieldView addSubview:draggingView];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (draggingView && draggingView.dragable) {
                draggingView.center = touchPoint;
            }
            break;
        case UIGestureRecognizerStateEnded:
            ;
            if (self.fieldView) {
                [draggingView removeFromSuperview];
                [self.backgroundView addSubview:draggingView];
                [self.fieldView removeFromSuperview];
                self.fieldView = nil;
            }
            break;
        case UIGestureRecognizerStateCancelled:
            ;
            break;
        default:
            break;
    }
    
}

- (BOOL)isPoint: (CGPoint)point fromView: (UIView *)superVeiw isInsideView:(UIView *)view {
    CGPoint insideViewPoint = [superVeiw convertPoint:point toView:view];
    BOOL result = [view pointInside:insideViewPoint withEvent:nil];
    
    return result;
}

- (UIView *)findViewForPoint: (CGPoint)point inView: (UIView *)sourceView {
    UIView *result;

    for(UIView *subview in [sourceView allSubViews]) {
//        printf("%s\n", [[[subview class] description] UTF8String]);
        if ([self isPoint:point fromView:sourceView isInsideView:subview] && subview.dragable) {
//            printf("FOUND!\n");
            return subview;
        }
    }
    
    return result;
}

@end
