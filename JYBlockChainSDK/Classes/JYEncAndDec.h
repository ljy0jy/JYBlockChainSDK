//
//  JYEncAndDec.h
//  JYBlockChainSDK
//
//  Created by new on 2022/3/14.
//

#import <Foundation/Foundation.h>

NSMutableData* JYHMACSHA512(NSData* key, NSData* data);

NSMutableData* JYSHA256(NSData* data);

NSMutableData* JYHash256(NSData* data);

NSMutableData* JYPDF2SHA512(NSData* data, NSData *salt, int iterations);

NSMutableData* JYHash160(NSData* data);

NSMutableData* JYReversedMutableData(NSData* data);

char* JYBase58CStringWithData(NSData* data);

void JYDataReverse(NSMutableData* self);

void JYReverseBytesLength(void* bytes, NSUInteger length);

BOOL JYDataClear(NSData* data);

NSMutableData* JYDataFromBase58CString(const char* cstring);

NSMutableString* JYCheckSUM(NSString *checkStr);
