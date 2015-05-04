//
//  BCDataInput.m
//  BCDataInput
//
//  Copyright 2015 GameHouse, a division of RealNetworks, Inc.
// 
//  The GameHouse Promotion Network SDK is licensed under the Apache License, 
//  Version 2.0 (the "License"); you may not use this file except in compliance 
//  with the License. You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "BCDataInput.h"

NSString * const BCReadErrorDomain = @"BCReadErrorDomain";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#pragma clang diagnostic ignored "-Wformat"

static int rawIntBitsToFloat(int x)
{
    union {
        float f;  // assuming 32-bit IEEE 754 single-precision
        int i;    // assuming 32-bit 2's complement int
    } u;
    
    u.i = x;
    return u.f;
}

BOOL BCReadBool(NSInputStream *stream, BOOL* ptr, NSError **errPtr)
{
    int value;
    if (BCReadByte(stream, &value, errPtr))
    {
        *ptr = value != 0;
        return YES;
    }
    
    return NO;
}

BOOL BCReadByte(NSInputStream *stream, int* ptr, NSError **errPtr)
{
    uint8_t buffer = 0;
    if ([stream read:&buffer maxLength:1] == 1)
    {
        *ptr = buffer;
        return YES;
    }
    
    if (errPtr != NULL)
    {
        *errPtr = stream.streamError;
    }
    
    return NO;
}

BOOL BCReadShort(NSInputStream *stream, int* ptr, NSError **errPtr)
{
    uint8_t buffer[2];
    if ([stream read:buffer maxLength:2] == 2)
    {
        *ptr = (buffer[0] << 8) | buffer[1];
        return YES;
    }
    
    if (errPtr != NULL)
    {
        *errPtr = stream.streamError;
    }
    
    return NO;
}

BOOL BCReadChar(NSInputStream *stream, int* ptr, NSError **errPtr)
{
    return BCReadShort(stream, ptr, errPtr);
}

BOOL BCReadInt(NSInputStream *stream, int *ptr, NSError **errPtr)
{
    uint8_t buffer[4];
    if ([stream read:buffer maxLength:4] == 4)
    {
        *ptr = buffer[0] << 24 | buffer[1] << 16 | buffer[2] << 8 | buffer[3];
        return YES;
    }
    
    if (errPtr != NULL)
    {
        *errPtr = stream.streamError;
    }
    
    return NO;
}

BOOL BCReadFloat(NSInputStream *stream, float *ptr, NSError **errPtr)
{
    int value;
    if (BCReadInt(stream, &value, errPtr))
    {
        *ptr = rawIntBitsToFloat(value);
        return YES;
    }
    
    return NO;
}

BOOL BCReadString(NSInputStream *stream, NSString **ptr, NSError **errPtr)
{
    int utflen;
    if (!BCReadShort(stream, &utflen, errPtr))
    {
        return NO;
    }
    
    uint8_t * bytearr = (uint8_t *)malloc(utflen * sizeof(uint8_t));
    unichar * chararr = (unichar *)malloc(utflen * sizeof(unichar));
    
    int c, char2, char3;
    int count = 0;
    int chararr_count=0;
    
    int bytesRead = [stream read:bytearr maxLength:utflen];
    if (bytesRead != utflen)
    {
        if (errPtr)
        {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey :
                    [NSString stringWithFormat:@"Can't read string: expected=%d actual=%d", utflen, bytesRead]
            };
            *errPtr = [NSError errorWithDomain:BCReadErrorDomain code:-1 userInfo:userInfo];
        }

        return NO;
    }
    
    while (count < utflen) {
        c = (int) bytearr[count] & 0xff;
        if (c > 127) break;
        count++;
        chararr[chararr_count++]=(char)c;
    }
    
    while (count < utflen) {
        c = (int) bytearr[count] & 0xff;
        switch (c >> 4) {
            case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
                /* 0xxxxxxx*/
                count++;
                chararr[chararr_count++]=(char)c;
                break;
            case 12: case 13:
                /* 110x xxxx   10xx xxxx*/
                count += 2;
                char2 = (int) bytearr[count-1];
                chararr[chararr_count++]=(char)(((c & 0x1F) << 6) |
                                                (char2 & 0x3F));
                break;
            case 14:
                /* 1110 xxxx  10xx xxxx  10xx xxxx */
                count += 3;
                char2 = (int) bytearr[count-2];
                char3 = (int) bytearr[count-1];
                chararr[chararr_count++]=(char)(((c     & 0x0F) << 12) |
                                                ((char2 & 0x3F) << 6)  |
                                                ((char3 & 0x3F) << 0));
                break;
            default:
                /* 10xx xxxx,  1111 xxxx */
                if (errPtr)
                {
                    NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Can't read UTF string: unexpected character range: "
                                                     "10xx xxxx,  1111 xxxx"]
                    };
                    *errPtr = [NSError errorWithDomain:BCReadErrorDomain code:-1 userInfo:userInfo];
                }
                
                free(bytearr);
                free(chararr);
                
                return NO;
        }
    }
    
    *ptr = [[NSString alloc] initWithCharacters:chararr length:chararr_count];
    free(bytearr);
    free(chararr);
    
    return YES;
}

BOOL BCReadBytes(NSInputStream *stream, NSString **ptr, NSUInteger length, NSError **errPtr)
{
    uint8_t bytes[length + 1];
    int bytesRead = [stream read:bytes maxLength:length];
    if (bytesRead != length)
    {
        if (errPtr)
        {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Can't read string bytes: expected=%d actual=%d", length, bytesRead]
            };
            *errPtr = [NSError errorWithDomain:BCReadErrorDomain code:-1 userInfo:userInfo];
        }
        return NO;
    }
    bytes[length] = 0;
    const char *string = (const char *)bytes;
    
    *ptr = [[NSString alloc] initWithCString:string encoding:NSASCIIStringEncoding];
    return YES;
}

BOOL BCReadData(NSInputStream *stream, NSData **ptr, NSError **errPtr)
{
    int length;
    NSError *error = nil;
    if (!BCReadInt(stream, &length, &error))
    {
        if (errPtr) *errPtr = nil;
        return NO;
    }
    
    uint8_t* buffer = malloc(length);
    int bytesRead = [stream read:buffer maxLength:length];
    if (bytesRead != length)
    {
        if (errPtr)
        {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Can't read data: bytes expected %d actual read %d", length, bytesRead]
            };
            *errPtr = [[NSError alloc] initWithDomain:BCReadErrorDomain code:-1 userInfo:userInfo];
        }
        
        free(buffer);
        return NO;
    }
    
    *ptr = [[NSData alloc] initWithBytesNoCopy:buffer length:length];
    return YES;
}

#pragma clang diagnostic pop
