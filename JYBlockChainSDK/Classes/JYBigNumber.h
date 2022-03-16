//
//  JYBigNumber.h
//  JYBlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import <Foundation/Foundation.h>
#import "OpenSSL/OpenSSL.h"

@class JYBigNumber;
@class JYMutableBigNumber;
@interface JYBigNumber : NSObject

@property(nonatomic, readwrite) NSData* unsignedBigEndian;
@property(nonatomic, readonly) const BIGNUM* BIGNUM;

+ (instancetype)zero;
+ (JYBigNumber*)curveOrder;


- (id)initWithUnsignedBigEndian:(NSData *)data;
- (void)clear;
- (BOOL)greaterOrEqual:(JYBigNumber *)other;
@end

@interface JYMutableBigNumber : JYBigNumber

- (instancetype)add:(JYBigNumber*)other;

- (instancetype)add:(JYBigNumber*)other mod:(JYBigNumber*)mod;
@end
#import "OpenSSL/OpenSSL.h"
