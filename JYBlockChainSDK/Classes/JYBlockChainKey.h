//
//  BlockChainKey.h
//  BlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JYBlockChainKey : NSObject
@property(nonatomic, readwrite) NSData* identifier;
@property(nonatomic, readwrite) uint32_t fingerprint;
@property(nonatomic, readwrite) uint32_t parentFingerprint;
@property(nonatomic, readwrite) uint32_t index;
@property(nonatomic, readwrite) uint8_t depth;
@property(nonatomic, readwrite) BOOL hardened;

/**
    压缩公钥  注意目前各种地址生成和派生 都是默认用的压缩公钥
 */
@property(nonatomic, strong) NSData *compressedPublicKey;

/**
    未压缩公钥
 */
@property(nonatomic, strong) NSData *uncompressedPublicKey;

/**
    私钥
 */
@property(nonatomic, strong) NSData *privateKey;

/**
    chain code
 */
@property(nonatomic, strong) NSData *chainCode;

/**
    P2PKH地址和P2SH地址 会根据判断自动输出
 */
@property(nonatomic, strong) NSString *address;

/**
    WIF私钥
 */
@property(nonatomic, strong) NSString *wifPrivateKey;

/**
    派生路径
 */
@property(nonatomic, strong) NSString *path;

/**
 派生密钥
 path为派生路径
 m / purpose' / coin_type' / account' / change / address_index
 bip44的路径:  m/44'/0'/0'/0/0  公钥编码是 1addresses
 bip49的路径  m/49'/0'/0'/0/0 公钥编码是 3addresses
 bip84 路径 m/84'/0'/0'/0/0  公钥编码是bc1addresses
 币种类型: https://github.com/satoshilabs/slips/blob/master/slip-0044.md
 */
- (JYBlockChainKey *)derivedKeychainWithPath:(NSString*)path;


@end

NS_ASSUME_NONNULL_END
