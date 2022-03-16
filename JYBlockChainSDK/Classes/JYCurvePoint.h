//
//  JYCurvePoint.h
//  JYBlockChainSDK
//
//  Created by new on 2022/3/15.
//

#import <Foundation/Foundation.h>
#import "JYBigNumber.h"
NS_ASSUME_NONNULL_BEGIN

@interface JYCurvePoint : NSObject
@property(nonatomic, readonly) NSData* data;

- (id) initWithData:(NSData*)data;
- (instancetype) addGeneratorMultipliedBy:(JYBigNumber*)number;
- (BOOL) isInfinity;
- (void) clear;
@end

NS_ASSUME_NONNULL_END
