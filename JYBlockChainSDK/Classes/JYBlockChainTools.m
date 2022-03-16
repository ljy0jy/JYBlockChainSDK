//
//  JYBlockChainTools.m
//  JYBlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import "JYBlockChainTools.h"


@implementation JYBlockChainTools

+ (NSData *)my_dataFromHexString:(NSString *)str
{
    const char *chars = [str UTF8String];
    int i = 0, len = (int)str.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len/2.0];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len)
    {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

//将字符串转换为16进制
+ (NSString *)my_hexstringFromData:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    //如果buffer不存在
    if(!dataBuffer)
    {
        return [NSString string];
    }
    
    NSUInteger dataLength = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for(int i = 0 ; i < dataLength ; ++i)
    {
       
        [hexString appendString:[NSString stringWithFormat:@"%02lx",(unsigned long)dataBuffer[i]]];
    }
    
    return [NSString stringWithString:hexString];
}



@end
