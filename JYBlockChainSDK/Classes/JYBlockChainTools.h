//
//  JYBlockChainTools.h
//  JYBlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JYBlockChainTools : NSObject

/**
    字符串转data (其中的字符串为16进制数字，意味着2个字符是1个字节 也就是data的1个长度)
 */

+ (NSData *)my_dataFromHexString:(NSString *)str;

/**
        data转成16进制  用字符串表示
 */
+ (NSString *)my_hexstringFromData:(NSData *)data;




@end

NS_ASSUME_NONNULL_END
