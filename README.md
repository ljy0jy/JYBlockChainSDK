# JYBlockChainSDK

JYBlockChainSDK是一个区块链钱包SDK，可以创建钱包，生成助记词，生成钱包地址，以及wif私钥
本SDK 需要依赖OpenSSL

# 安装
    pod 'JYBlockChainSDK'  
    pod "OpenSSL-Universal"    
    pod install  
    
#如何使用
    Example里面的 JYViewController 有部分展示   
    import "JYBlockChainSDK/JYBlockChainSDK.h"  

    //创建一个钱包并生成助记词
    NSString *mnemonicString = [JYBlockChainMain generateMnemonicString:Entropy128];
    //助记词为idea talent month depth what cave tuna liar book corn alone increase
    NSLog(@"助记词为%@", mnemonicString);
    
    //获取master密钥
    //先获取种子
    NSData *seed = [JYBlockChainMain generateSeedFromMnemonicString:mnemonicString passphrase:@""];
    //通过种子拿到master密钥
    JYBlockChainKey*masterKey =[JYBlockChainMain generateKeyfromSeed:seed];
    NSString *seedStr = [JYBlockChainTools my_hexstringFromData:seed];
    NSString *privateKey = [JYBlockChainTools my_hexstringFromData:masterKey.privateKey];
    NSString *compressedPublicKey = [JYBlockChainTools my_hexstringFromData:masterKey.compressedPublicKey];
    NSString *uncompressedPublicKey = [JYBlockChainTools my_hexstringFromData:masterKey.uncompressedPublicKey];

    /**
     种子为:3409998857f916997415e15b509ec7a9660a0b8c863e6cfe0f5d860e4b2a718cdfaef64a861a59d6be0bef0cf638dbc9b86447b19576b1678552fa94535bc6f4
     主私钥:f26e3fb2cca5fc4bdcf6cc8069fcc6391b010372788a77fbbd0a515f8b7dae14
     主公钥(压缩):03aeb4186446699e65c571397f55e860d1c6985d41416ee7b5ba03218b0f309f4a
     主公钥(未压缩):04aeb4186446699e65c571397f55e860d1c6985d41416ee7b5ba03218b0f309f4aae627439a3304267f959f2d03906191f71ed7bb64ac2b94999def53aeb1ac1eb
     wif私钥:L5LxtWQuf8eu4R7Emmfy1RShPuaXHiVZwakmBLo7Nn9AuPw8mMoG
     */
    NSLog(@"种子为:%@\n主私钥:%@\n主公钥(压缩):%@\n主公钥(未压缩):%@\nwif私钥:%@",seedStr,privateKey,compressedPublicKey,uncompressedPublicKey,masterKey.wifPrivateKey);
    
    //助记词获得钱包地址
    //这里以bip44 比特币为例子 生成20个比特币地址
    NSMutableArray *addressArr = [NSMutableArray array];
    for (int i = 0; i < 20; i++) {
        NSString *path = [NSString stringWithFormat:@"m/44'/0'/0'/0/%d", i];
        JYBlockChainKey* key = [masterKey derivedKeychainWithPath:path];
        [addressArr addObject:key.address];
    }
    /**
     比特币钱包地址:(
         1Pg5tGWf1AjxYeTL3stztjT2bkVSsbXEGE,
         1EsQvyUauG4MhRM97DHfjHLYo5RJrQfByM,
         1M4dxvrGQpVMZSFYbMZtnVEF9GKfngBd1N,
         1NRqeb8cx5ddmsUXSewgeoGUCTJ3DrcLA6,
         1H7cXWPaB5UkhUbiPo8sNxn1QXXdLo71fg,
         16WszGfJhHKMCDf3FjPqmJYEJjbkVR4Q2W,
         1ChWncvK5vJXtdLjpVAVPHo35kKjwim9om,
         1E5eJQCfkgUTgCosYpbcSea4wkdYjuwKRV,
         19ZtSZMy5gHAzDpcbHHGxsPD5aHUZmfGyA,
         1D18zSuHgdkjgBPEUFN8miSzF7qRga7zgX,
         15UYuaVpTVYZcUQvpVMGA4WH2LwWmYBjMp,
         1EsSEbCsfvW7rNctgHtrMgB6FfimESmJcX,
         1DqH6D12QdHPqyznRMNmGiftRRbu5giVxo,
         181rEJExVNNBsG6fdqX8k56u7153UZQbgx,
         1NFoLQmefbV51A3JM34uZatwMtjjkDNdSc,
         1PDYaK2D8PqwbAyCvhbctcR3VJBsThqPvy,
         1DjbcjKDXH3HAUMWQdEpSJu3M2CPB8StH4,
         14UzWUzXdBJSVthrAxCHmUJCtYv126VDgZ,
         17Xfak8rBfw2SupMe19KRSieaivJ5auHuR,
         1HYQbfGFf8h7iMgb7uWVEYac7xHUgRjjiZ
     )
     */
    NSLog(@"比特币钱包地址:%@", addressArr);
    
    
