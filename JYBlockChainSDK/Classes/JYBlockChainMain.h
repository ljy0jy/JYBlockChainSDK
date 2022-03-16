//
//  BlockChainSDK.h
//  BlockChainSDK
//
//  Created by new on 2022/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//输入长度必须为128、160、192、224、256
typedef enum : NSUInteger {
    Entropy128 = 128,
    Entropy160 = 160,
    Entropy192 = 192,
    Entropy224 = 224,
    Entropy256 = 256,
} EntropyLenth;
@class JYBlockChainKey;
@interface JYBlockChainMain : NSObject


/**
    创建助记词
    entropyLenth   为熵的长度
 */
+ (NSString *)generateMnemonicString:(EntropyLenth)entropyLenth;



/**
    通过助记词拿种子
    mnemonicString 是字符串形式助记词, 空格隔开
    passphrase为加盐字符串，一般可填@"" 或者 nil
 */
+ (NSData *)generateSeedFromMnemonicString:(NSString *)mnemonicString passphrase:(NSString *)passphrase;

/**
    通过种子拿到主密钥
 */
+ (JYBlockChainKey *)generateKeyfromSeed:(NSData *)seed;


/**
    通过助记词 派生路径 拿钱包地址
    path为派生路径
    m / purpose' / coin_type' / account' / change / address_index
    bip44的路径:  m/44'/0'/0'/0/0  公钥编码是 1addresses
    bip49的路径  m/49'/0'/0'/0/0 公钥编码是 3addresses
    bip84 路径 m/84'/0'/0'/0/0  公钥编码是bc1addresses
    币种类型: https://github.com/satoshilabs/slips/blob/master/slip-0044.md
 */
+ (JYBlockChainKey *)generateWalletAddressFromMnemonicString:(NSString *)mnemonicString path:(NSString *)path;





@end

NS_ASSUME_NONNULL_END
