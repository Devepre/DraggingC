#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) NSMutableArray *tagsData;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewTop;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewBottom;

@end

