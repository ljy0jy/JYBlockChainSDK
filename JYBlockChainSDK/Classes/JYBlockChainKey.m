//
//  BlockChainKey.m
//  BlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import "JYBlockChainKey.h"
#import "JYBigNumber.h"
#import "JYEncAndDec.h"
#import "JYCurvePoint.h"
#import "OpenSSL/OpenSSL.h"
#import "JYBlockChainTools.h"

@implementation JYBlockChainKey
{
    EC_KEY* _key;
}
- (NSData *)compressedPublicKey {
    if (!_compressedPublicKey) {
        if (_privateKey) {
            //data转bignum
            BIGNUM *bignum = BN_bin2bn(_privateKey.bytes, (int)_privateKey.length, BN_new());
            if (!bignum) return nil;
            [self prepareKeyIfNeeded];
            //计算曲线 拿到公钥
            BTCRegenerateKey(_key, bignum);
            //释放内存
            BN_clear_free(bignum);
            _compressedPublicKey = [self publicKeyWithCompression:YES];
            
        }else return nil;
        
    }
    return _compressedPublicKey;
}

- (NSData *)uncompressedPublicKey {
    if (!_uncompressedPublicKey) {
        if (_privateKey) {
            //data转bignum
            BIGNUM *bignum = BN_bin2bn(_privateKey.bytes, (int)_privateKey.length, BN_new());
            if (!bignum) return nil;
            //计算曲线 拿到公钥
            BTCRegenerateKey(_key, bignum);
            //释放内存
            BN_clear_free(bignum);
            return [self publicKeyWithCompression:NO];
        }else return nil;
        
    }
    return _uncompressedPublicKey;
}

- (NSString *)address {
    if (!_address) {
        if (self.compressedPublicKey) {
            NSString* hash160 = [JYBlockChainTools my_hexstringFromData:JYHash160(_compressedPublicKey)];
            NSString *prefix = [NSString string];
            if ([self.path containsString:@"44'/0'/0'"]) {
                prefix = @"00";
            }else if ([self.path containsString:@"49'/0'/0'"]) {
                prefix = @"05";
            }
            NSString *checkStr = [NSString stringWithFormat:@"%@%@",prefix,hash160];

            
            NSMutableString *addressData = [NSMutableString string];
            [addressData appendString:prefix];
            [addressData appendString:hash160];
            [addressData appendString:JYCheckSUM(checkStr)];
            
            char * a = JYBase58CStringWithData([JYBlockChainTools my_dataFromHexString:addressData]);

            return [NSString stringWithCString:a encoding:NSASCIIStringEncoding];
            
        }
    }
    return _address;
}

- (NSString *)wifPrivateKey {
    if (!_wifPrivateKey) {
        if (_privateKey) {
            NSString *extened = [NSString stringWithFormat:@"80%@01",[JYBlockChainTools my_hexstringFromData:_privateKey]];
            NSString *extendCheckSum = [NSString stringWithFormat:@"%@%@",extened,JYCheckSUM(extened)];
            char *wif = JYBase58CStringWithData([JYBlockChainTools my_dataFromHexString:extendCheckSum]);
            _wifPrivateKey = [NSString stringWithCString:wif encoding:NSASCIIStringEncoding];
        }
    }
    return _wifPrivateKey;
}

- (NSMutableData*) publicKeyWithCompression:(BOOL)compression {
    if (!_key) return nil;
    //设置转换模式 是否压缩
    EC_KEY_set_conv_form(_key, compression ? POINT_CONVERSION_COMPRESSED : POINT_CONVERSION_UNCOMPRESSED);
    //
    int length = i2o_ECPublicKey(_key, NULL);
    if (!length) return nil;
    NSAssert(length <= 65, @"Pubkey length must be up to 65 bytes.");
    NSMutableData* data = [[NSMutableData alloc] initWithLength:length];
    unsigned char* bytes = [data mutableBytes];
    if (i2o_ECPublicKey(_key, &bytes) != length) return nil;
    return data;
}

- (JYBlockChainKey *)derivedKeychainWithPath:(NSString*)path {

    if (path == nil) return nil;

    if ([path isEqualToString:@"m"] ||
        [path isEqualToString:@"/"] ||
        [path isEqualToString:@""]) {
        return nil;
    }

    JYBlockChainKey* kc = self;

    if ([path rangeOfString:@"m/"].location == 0) {
        path = [path substringFromIndex:2];
    }
    for (NSString* chunk in [path componentsSeparatedByString:@"/"]) {
        if (chunk.length == 0) {
            continue;
        }
        BOOL hardened = NO;
        NSString* indexString = chunk;
        if ([chunk rangeOfString:@"'"].location == chunk.length - 1) {
            hardened = YES;
            indexString = [chunk substringToIndex:chunk.length - 1];
        }

        // Make sure the chunk is just a number
        NSInteger i = [indexString integerValue];
        if (i >= 0 && [@(i).stringValue isEqualToString:indexString]) {
            kc = [kc derivedKeychainAtIndex:(uint32_t)i hardened:hardened factor:NULL];
        } else {
            return nil;
        }
    }
    kc.path = path;
    return kc;
}

- (JYBlockChainKey *)derivedKeychainAtIndex:(uint32_t)index hardened:(BOOL)hardened factor:(JYBigNumber**)factorOut {
    

    //是否hardened 用BOOL hardened判断， 不能用index大值来判断，这样比较方便
    if ((0x80000000 & index) != 0) {
        @throw [NSException exceptionWithName:@"BTCKeychain Exception"
                                       reason:@"Indexes >= 0x80000000 are invalid. Use hardened:YES argument instead." userInfo:nil];
        return nil;
    }
    
    //没有私钥 无法派生
    if (!_privateKey && hardened) {
        return nil;
    }

    JYBlockChainKey* derivedKeychain = [[JYBlockChainKey alloc] init];

    NSMutableData* data = [NSMutableData data];
    
    //如果是hardened 要用私钥加密 padding是固定格式 需要在私钥前加1个字节的0
    //如果不是hardened 用公钥加密
    if (hardened) {
        uint8_t padding = 0;
        [data appendBytes:&padding length:1];
        [data appendData:_privateKey];
    } else {
        [data appendData:self.compressedPublicKey];
    }
    
    //转32位大index 如果是 hardened 则在index前加0x80000000 否则就是index本身
    uint32_t indexBE = OSSwapHostToBigInt32(hardened ? (0x80000000 | index) : index);
    // 把index拼接到data后面
    [data appendBytes:&indexBE length:sizeof(indexBE)];
    
    NSData* digest = JYHMACSHA512(_chainCode, data);
    
    JYBigNumber* factor = [[JYBigNumber alloc] initWithUnsignedBigEndian:[digest subdataWithRange:NSMakeRange(0, 32)]];

    // Factor is too big, this derivation is invalid.
    if ([factor greaterOrEqual:[JYBigNumber curveOrder]]) {
        return nil;
    }

    if (factorOut) *factorOut = factor;

    derivedKeychain.chainCode = [NSMutableData dataWithBytes:digest.bytes+32 length:32];

    if (_privateKey) {
        JYMutableBigNumber* pkNumber = [[JYMutableBigNumber alloc] initWithUnsignedBigEndian:_privateKey];
        
        [pkNumber add:factor mod:[JYBigNumber curveOrder]];

        // Check for invalid derivation.
        if ([pkNumber isEqual:[JYBigNumber zero]]) return nil;

        NSData* pkData = pkNumber.unsignedBigEndian;
        derivedKeychain.privateKey = [pkData mutableCopy];
        [(NSMutableData *)pkData resetBytesInRange:NSMakeRange(0, pkData.length)];
       
        [pkNumber clear];
    } else {
        JYCurvePoint* point = [[JYCurvePoint alloc] initWithData:_compressedPublicKey];
        [point addGeneratorMultipliedBy:factor];

        // Check for invalid derivation.
        if ([point isInfinity]) return nil;

        NSData* pointData = point.data;
        derivedKeychain.compressedPublicKey = [pointData mutableCopy];
        [(NSMutableData *)pointData resetBytesInRange:NSMakeRange(0, pointData.length)];
        [point clear];
    }
    derivedKeychain.depth = _depth + 1;
    derivedKeychain.parentFingerprint = self.fingerprint;
    derivedKeychain.index = index;
    derivedKeychain.hardened = hardened;
    return derivedKeychain;
}

- (void) prepareKeyIfNeeded {
    if (_key) return;
    _key = EC_KEY_new_by_curve_name(NID_secp256k1);
    if (!_key) {
        // This should not generally happen.
    }
}

static int BTCRegenerateKey(EC_KEY *eckey, BIGNUM *priv_key) {
    BN_CTX *ctx = NULL;
    EC_POINT *pub_key = NULL;
    
    if (!eckey) return 0;
    
    const EC_GROUP *group = EC_KEY_get0_group(eckey);
    
    BOOL success = NO;
    if ((ctx = BN_CTX_new())) {
        if ((pub_key = EC_POINT_new(group))) {
            if (EC_POINT_mul(group, pub_key, priv_key, NULL, NULL, ctx)) {
                EC_KEY_set_private_key(eckey, priv_key);
                EC_KEY_set_public_key(eckey, pub_key);
                success = YES;
            }
        }
    }
    
    if (pub_key) EC_POINT_free(pub_key);
    if (ctx) BN_CTX_free(ctx);
    
    return success;
}

@end
