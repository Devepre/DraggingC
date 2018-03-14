#import <UIKit/UIKit.h>
#import "DragDealer.h"

@interface ViewController : UIViewController <DragDealerProtocol>

@property (strong, nonatomic) IBOutlet UIView *backgroundView;

@property (strong, nonatomic) NSMutableArray *tagsData;
@property (strong, nonatomic) NSMutableArray *choosedTagsData;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewTop;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewBottom;

@end

