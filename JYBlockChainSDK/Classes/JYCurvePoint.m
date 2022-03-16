//
//  JYCurvePoint.m
//  JYBlockChainSDK
//
//  Created by new on 2022/3/15.
//

#import "JYCurvePoint.h"
#import "OpenSSL/OpenSSL.h"


@implementation JYCurvePoint{
    EC_GROUP* _group;
    EC_POINT* _point;
    BN_CTX*   _bnctx;
}

- (id) initWithData:(NSData*)data {
    if (self = [self initEmpty]) {
        
        BIGNUM* bn = BN_bin2bn(data.bytes, (int)data.length, NULL);
        if (!bn) {
            return nil;
        }
        
        if (!EC_POINT_bn2point(_group, bn, _point, _bnctx)) {
            if (bn) BN_clear_free(bn);
            return nil;
        }
        
        // Point is imported, only need to cleanup an intermediate BIGNUM structure.
        if (bn) BN_clear_free(bn);
    }
    return self;
}

- (instancetype) addGeneratorMultipliedBy:(JYBigNumber*)number {
    if (!number) return nil;
    
    if (!EC_POINT_mul(_group, _point, number.BIGNUM, _point, BN_value_one(), _bnctx)) {
        return nil;
    }
    
    return self;
}

- (id) initEmpty {
    if (self = [super init]) {
        _group = NULL;
        _point = NULL;
        _bnctx   = NULL;
        
        _group = EC_GROUP_new_by_curve_name(NID_secp256k1);
        if (!_group) {
            NSLog(@"JYCurvePoint: EC_GROUP_new_by_curve_name(NID_secp256k1) failed");
            goto finish;
        }
        
        _point = EC_POINT_new(_group);
        if (!_point) {
            NSLog(@"JYCurvePoint: EC_POINT_new(_group) failed");
            goto finish;
        }
        
        _bnctx = BN_CTX_new();
        if (!_bnctx) {
            NSLog(@"JYCurvePoint: BN_CTX_new() failed");
            goto finish;
        }
        
        return self;
        
    finish:
        if (_group) EC_GROUP_free(_group);
        if (_point) EC_POINT_clear_free(_point);
        
        return nil;
    }
    return self;
}

- (BOOL) isInfinity {
    return 1 == EC_POINT_is_at_infinity(_group, _point);
}

- (void) clear {
    if (_point) EC_POINT_clear_free(_point);
    _point = NULL;
}

@end
