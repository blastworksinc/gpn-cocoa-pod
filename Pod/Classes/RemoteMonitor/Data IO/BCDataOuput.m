//
//  BCDataOuput.m
//  BCDataOuput
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

#import "BCDataOuput.h"

static int floatToRawIntBits(float x)
{
    union {
        float f;  // assuming 32-bit IEEE 754 single-precision
        int i;    // assuming 32-bit 2's complement int
    } u;
    
    u.f = x;
    return u.i;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

int BCWriteBool(NSOutputStream *stream, BOOL value)
{
    return BCWriteByte(stream, value ? 1 : 0);
}

int BCWriteByte(NSOutputStream *stream, int value)
{
    uint8_t buffer = (uint8_t) (value & 0xFF);
    return [stream write:&buffer maxLength:1];
}

int BCWriteShort(NSOutputStream *stream, int value)
{
    uint8_t buffer[2];
    buffer[0] = (value >> 8) & 0xFF;
    buffer[1] = (value >> 0) & 0xFF;
    
    return [stream write:buffer maxLength:2];
}

int BCWriteChar(NSOutputStream *stream, int value)
{
    return BCWriteShort(stream, value);
}

int BCWriteInt(NSOutputStream *stream, int value)
{
    uint8_t buffer[4];
    buffer[0] = (value >> 24) & 0xFF;
    buffer[1] = (value >> 16) & 0xFF;
    buffer[2] = (value >> 8) & 0xFF;
    buffer[3] = (value >> 0) & 0xFF;
    
    return [stream write:buffer maxLength:4];
}

int BCWriteFloat(NSOutputStream *stream, float value)
{
    int bits = floatToRawIntBits(value);
    return BCWriteInt(stream, bits);
}

int BCWriteString(NSOutputStream *stream, NSString *value)
{
    int strlen = value.length;
    int utflen = 0;
    int c, count = 0;
    
    /* use charAt instead of copying String to char array */
    for (int i = 0; i < strlen; i++) {
        // c = str.charAt(i);
        c = [value characterAtIndex:i];
        if ((c >= 0x0001) && (c <= 0x007F)) {
            utflen++;
        } else if (c > 0x07FF) {
            utflen += 3;
        } else {
            utflen += 2;
        }
    }
    
    uint8_t* bytearr = (uint8_t*)malloc(utflen + 2); // TODO: use shared buffer or allocate on the stack
    
    bytearr[count++] = (uint8_t) ((utflen >> 8) & 0xFF);
    bytearr[count++] = (uint8_t) ((utflen >> 0) & 0xFF);
    
    int i=0;
    for (i=0; i<strlen; i++) {
        c = [value characterAtIndex:i];
        if (!((c >= 0x0001) && (c <= 0x007F))) break;
        bytearr[count++] = (uint8_t) c;
    }
    
    for (;i < strlen; i++){
        c = [value characterAtIndex:i];
        if ((c >= 0x0001) && (c <= 0x007F)) {
            bytearr[count++] = (uint8_t) c;
            
        } else if (c > 0x07FF) {
            bytearr[count++] = (uint8_t) (0xE0 | ((c >> 12) & 0x0F));
            bytearr[count++] = (uint8_t) (0x80 | ((c >>  6) & 0x3F));
            bytearr[count++] = (uint8_t) (0x80 | ((c >>  0) & 0x3F));
        } else {
            bytearr[count++] = (uint8_t) (0xC0 | ((c >>  6) & 0x1F));
            bytearr[count++] = (uint8_t) (0x80 | ((c >>  0) & 0x3F));
        }
    }
    
    int bytesWritten = [stream write:bytearr maxLength:utflen+2];
    free(bytearr);
    
    return bytesWritten;
}

int BCWriteData(NSOutputStream *stream, NSData *data)
{
    int total = 0;
    int length = data.length;
    total += BCWriteInt(stream, length);
    
    const uint8_t *bytes = data.bytes;
    total += [stream write:bytes maxLength:data.length];
    
    return total;
}

#pragma clang diagnostic pop
