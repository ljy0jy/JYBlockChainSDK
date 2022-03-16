//
//  JYBigNumber.m
//  JYBlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import "JYBigNumber.h"
#import "JYBlockChainTools.h"


#define JYBigNumberCompare(a, b) (BN_cmp(a->_bignum, b->_bignum))

@implementation JYBigNumber
{
    @package
    BIGNUM *_bignum;
    
    BOOL _immutable;
}
+ (instancetype) zero {
    static JYBigNumber* bn = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bn = [[self alloc] init];
        BN_zero(bn->_bignum);
    });
    return bn;
}
- (void) clear {
    BN_clear(_bignum);
}
- (id) init {
    if (self = [super init]) {
        _bignum = BN_new();
    }
    return self;
}

- (id) initWithUnsignedBigEndian:(NSData *)data {
    if (!data) return nil;
    if (self = [self init]) self.unsignedBigEndian = data;
    _immutable = YES;
    return self;
}

- (NSData*) unsignedBigEndian {
    int num_bytes = BN_num_bytes(_bignum);
    NSMutableData* data = [[NSMutableData alloc] initWithLength:32]; // zeroed data
    int copied_bytes = BN_bn2bin(_bignum, &data.mutableBytes[32 - num_bytes]); // fill the tail of the data so it's zero-padded to the left
    if (copied_bytes != num_bytes) return nil;
    return data;
}

- (void) setUnsignedBigEndian:(NSData *)data {
    [self throwIfImmutable];
    if (!data) return;
    if (!BN_bin2bn(data.bytes, (int)data.length, _bignum)) {
        return;
    }
}

- (void) throwIfImmutable {
    if (_immutable) {
        @throw [NSException exceptionWithName:@"Immutable BTCBigNumber is modified" reason:@"" userInfo:nil];
    }
}

+ (JYBigNumber*) curveOrder {
    static JYBigNumber* order;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        order = [[JYBigNumber alloc] initWithUnsignedBigEndian:[JYBlockChainTools my_dataFromHexString:@"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"]];
    });
    return order;
}
- (BOOL) greaterOrEqual:(JYBigNumber *)other { return JYBigNumberCompare(self, other) >= 0; }
@end




@implementation JYMutableBigNumber


- (instancetype) add:(JYBigNumber*)other {
    BN_add((self->_bignum), (self->_bignum), (other->_bignum));
    return self;
}


- (instancetype) add:(JYBigNumber*)other mod:(JYBigNumber*)mod {
    BN_CTX* pctx = BN_CTX_new();
    BN_mod_add((self->_bignum), (self->_bignum), (other->_bignum), (mod->_bignum), pctx);
    BN_CTX_free(pctx);
    return self;
}


@end

