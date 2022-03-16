//
//  JYEncAndDec.m
//  JYBlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import "JYEncAndDec.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import "OpenSSL/OpenSSL.h"
#import "JYBlockChainTools.h"

static const char* JYBase58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

NSMutableData* JYHMACSHA512(NSData* key, NSData* data) {
    if (!key) return nil;
    if (!data) return nil;
    unsigned char digest[CC_SHA512_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA512, key.bytes, key.length, data.bytes, data.length, digest);
    NSMutableData* result = [NSMutableData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
    memset(digest, 0, CC_SHA512_DIGEST_LENGTH);
    
    return result;
}

NSMutableData* JYSHA256(NSData* data) {
  
    if (!data) return nil;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes,(int)data.length,digest);
    NSMutableData* result = [NSMutableData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    memset(digest, 0, CC_SHA256_DIGEST_LENGTH);
    return result;
}

NSMutableData* JYHash256(NSData* data) {
    if (!data) return nil;
    unsigned char digest1[CC_SHA256_DIGEST_LENGTH];
    unsigned char digest2[CC_SHA256_DIGEST_LENGTH];
    __block CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        CC_SHA256_Update(&ctx, bytes, (CC_LONG)byteRange.length);
    }];
    CC_SHA256_Final(digest1, &ctx);
    CC_SHA256(digest1, CC_SHA256_DIGEST_LENGTH, digest2);
    NSMutableData* result = [NSMutableData dataWithBytes:digest2 length:CC_SHA256_DIGEST_LENGTH];
    memset(digest1, 0, CC_SHA256_DIGEST_LENGTH);
    memset(digest2, 0, CC_SHA256_DIGEST_LENGTH);
    return result;
}

NSMutableData* JYPDF2SHA512(NSData* data, NSData *salt, int iterations) {
    if (!salt) return nil;
    if (!data) return nil;
    unsigned char digest[CC_SHA512_DIGEST_LENGTH];
    CCKeyDerivationPBKDF(kCCPBKDF2, data.bytes, data.length, salt.bytes, salt.length, kCCPRFHmacAlgSHA512, iterations, digest, CC_SHA512_DIGEST_LENGTH);
    NSMutableData* result = [NSMutableData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
    memset(digest, 0, CC_SHA512_DIGEST_LENGTH);
    return result;
}

NSMutableData* JYHash160(NSData* data) {
    if (!data) return nil;
    unsigned char digest1[CC_SHA256_DIGEST_LENGTH];
    unsigned char digest2[RIPEMD160_DIGEST_LENGTH];
    __block CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        CC_SHA256_Update(&ctx, bytes, (CC_LONG)byteRange.length);
    }];
    CC_SHA256_Final(digest1, &ctx);
    RIPEMD160(digest1, CC_SHA256_DIGEST_LENGTH, digest2);
    NSMutableData* result = [NSMutableData dataWithBytes:digest2 length:RIPEMD160_DIGEST_LENGTH];
    memset(digest1, 0, CC_SHA256_DIGEST_LENGTH);
    memset(digest2, 0, RIPEMD160_DIGEST_LENGTH);
    return result;
}

NSMutableData* JYReversedMutableData(NSData* data) {
    if (!data) return nil;
    NSMutableData* md = [NSMutableData dataWithData:data];
    JYDataReverse(md);
    return md;
}

NSMutableData* JYDataFromBase58CString(const char* cstring) {
    if (cstring == NULL) return nil;
    
    // empty string -> empty data.
    if (cstring[0] == '\0') return [NSMutableData data];
    
    NSMutableData* result = nil;
    
    BN_CTX* pctx = BN_CTX_new();
    __block BIGNUM *bn58;   bn58 = BN_new();   BN_set_word(bn58, 58);
    __block BIGNUM *bn;     bn = BN_new();     BN_zero(bn);
    __block BIGNUM *bnChar; bnChar = BN_new();
    
    void(^finish)() = ^{
        if (pctx) BN_CTX_free(pctx);
        BN_clear_free(bn58);
        BN_clear_free(bn);
        BN_clear_free(bnChar);
    };
    
    while (isspace(*cstring)) cstring++;
    
    
    // Convert big endian string to bignum
    for (const char* p = cstring; *p; p++) {
        const char* p1 = strchr(JYBase58Alphabet, *p);
        if (p1 == NULL) {
            while (isspace(*p))
                p++;
            if (*p != '\0') {
                finish();
                return nil;
            }
            break;
        }
        
        BN_set_word(bnChar, (BN_ULONG)(p1 - JYBase58Alphabet));
        
        if (!BN_mul(bn, bn, bn58, pctx)) {
            finish();
            return nil;
        }
        
        if (!BN_add(bn, bn, bnChar)) {
            finish();
            return nil;
        }
    }
    
    // Get bignum as little endian data
    
    NSMutableData* bndata = nil;
    {
        size_t bnsize = BN_bn2mpi(bn, NULL);
        if (bnsize <= 4) {
            bndata = [NSMutableData data];
        } else {
            bndata = [NSMutableData dataWithLength:bnsize];
            BN_bn2mpi(bn, bndata.mutableBytes);
            [bndata replaceBytesInRange:NSMakeRange(0, 4) withBytes:NULL length:0];
            JYDataReverse(bndata);
        }
    }
    size_t bnsize = bndata.length;
    
    // Trim off sign byte if present
    if (bnsize >= 2
        && ((unsigned char*)bndata.bytes)[bnsize - 1] == 0
        && ((unsigned char*)bndata.bytes)[bnsize - 2] >= 0x80) {
        bnsize -= 1;
        [bndata setLength:bnsize];
    }
    
    // Restore leading zeros
    int nLeadingZeros = 0;
    for (const char* p = cstring; *p == JYBase58Alphabet[0]; p++)
        nLeadingZeros++;
    
    result = [NSMutableData dataWithLength:nLeadingZeros + bnsize];
    
    // Copy the bignum to the beginning of array. We'll reverse it then and zeros will become leading zeros.
    [result replaceBytesInRange:NSMakeRange(0, bnsize) withBytes:bndata.bytes length:bnsize];
    
    // Convert little endian data to big endian
    JYDataReverse(result);
    
    finish();
    
    return result;
}

char* JYBase58CStringWithData(NSData* data) {
    if (!data) return NULL;
    
    BN_CTX* pctx = BN_CTX_new();
    __block BIGNUM *bn58; bn58=BN_new(); BN_set_word(bn58, 58);
    __block BIGNUM *bn0;  bn0=BN_new();  BN_zero(bn0);
    __block BIGNUM *bn; bn=BN_new(); BN_zero(bn);
    __block BIGNUM *dv; dv=BN_new(); BN_zero(dv);
    __block BIGNUM *rem; rem=BN_new(); BN_zero(rem);
    
    void(^finish)() = ^{
        if (pctx) BN_CTX_free(pctx);
        BN_clear_free(bn58);
        BN_clear_free(bn0);
        BN_clear_free(bn);
        BN_clear_free(dv);
        BN_clear_free(rem);
    };
    
    // Convert big endian data to little endian.
    // Extra zero at the end make sure bignum will interpret as a positive number.
    NSMutableData* tmp = JYReversedMutableData(data);
    tmp.length += 1;
    
    // Convert little endian data to bignum
    {
        NSUInteger size = tmp.length;
        NSMutableData* mdata = [tmp mutableCopy];
        
        // Reverse to convert to OpenSSL bignum endianess
        JYDataReverse(mdata);
        
        // BIGNUM's byte stream format expects 4 bytes of
        // big endian size data info at the front
        [mdata replaceBytesInRange:NSMakeRange(0, 0) withBytes:"\0\0\0\0" length:4];
        unsigned char* bytes = mdata.mutableBytes;
        bytes[0] = (size >> 24) & 0xff;
        bytes[1] = (size >> 16) & 0xff;
        bytes[2] = (size >> 8) & 0xff;
        bytes[3] = (size >> 0) & 0xff;
        
        BN_mpi2bn(bytes, (int)mdata.length, bn);
    }
    
    // Expected size increase from base58 conversion is approximately 137%
    // use 138% to be safe
    NSMutableData* stringData = [NSMutableData dataWithCapacity:data.length*138/100 + 1];
    
    while (BN_cmp(bn, bn0) > 0) {
        if (!BN_div(dv, rem, bn, bn58, pctx)) {
            finish();
            return nil;
        }
        BN_copy(bn, dv);
        unsigned long c = BN_get_word(rem);
        [stringData appendBytes:JYBase58Alphabet + c length:1];
    }
    finish();
    
    // Leading zeroes encoded as base58 ones ("1")
    const unsigned char* pbegin = data.bytes;
    const unsigned char* pend = data.bytes + data.length;
    for (const unsigned char* p = pbegin; p < pend && *p == 0; p++) {
        [stringData appendBytes:JYBase58Alphabet + 0 length:1];
    }
    
    // Convert little endian std::string to big endian
    JYDataReverse(stringData);
    
    [stringData appendBytes:"" length:1];
    
    char* r = malloc(stringData.length);
    memcpy(r, stringData.bytes, stringData.length);
    JYDataClear(stringData);
    return r;
}

//byte对调
void JYDataReverse(NSMutableData* self) {
    JYReverseBytesLength(self.mutableBytes, self.length);
}

// Clears contents of the data to prevent leaks through swapping or buffer-overflow attacks.
BOOL JYDataClear(NSData* data) {
    if ([data isKindOfClass:[NSMutableData class]]) {
        [(NSMutableData*)data resetBytesInRange:NSMakeRange(0, data.length)];
        return YES;
    }
    return NO;
}

void JYReverseBytesLength(void* bytes, NSUInteger length) {
    // K&R
    if (length <= 1) return;
    unsigned char* buf = bytes;
    unsigned char byte;
    NSUInteger i, j;
    for (i = 0, j = length - 1; i < j; i++, j--) {
        byte = buf[i];
        buf[i] = buf[j];
        buf[j] = byte;
    }
}

NSMutableString* JYCheckSUM(NSString *checkStr) {
    if (!checkStr) return nil;
    NSData *checkData = [JYBlockChainTools my_dataFromHexString:checkStr];
    NSData *checkSum = JYSHA256(JYSHA256(checkData));
    return [JYBlockChainTools my_hexstringFromData:[NSMutableData dataWithBytes:checkSum.bytes length:4]];
}
