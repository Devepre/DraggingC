//
//  DragDealerProtocol.h
//  DraggingC
//
//  Created by Limitation on 6/23/18.
//  Copyright © 2018 DEL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DragDealerProtocol <NSObject>

@required
- (void)draggedFromCollectionView:(UICollectionView *)fromView
                      atIndexPath:(NSIndexPath *)indexFrom
                 toCollectionView:(UICollectionView *)toView
                      atIndexPath:(NSIndexPath *)indexTo;

- (void)dropCopyObjectFromCollectionView:(UICollectionView *)fromView
                             atIndexPath:(NSIndexPath *)indexFrom
                        toCollectionView:(UICollectionView *)toView
                             atIndexPath:(NSIndexPath *)indexTo;

- (void)deleteObjectFromCollectionView:(UICollectionView *)fromView
                           atIndexPath:(NSIndexPath *)indexFrom;

@optional
- (BOOL)canDragItemFromView:(UICollectionView *)view
                atIndexPath:(NSIndexPath *)path;

- (void)dragBeganFromView:(UICollectionView *)view
              atIndexPath:(NSIndexPath *)path;

@end

NS_ASSUME_NONNULL_END
