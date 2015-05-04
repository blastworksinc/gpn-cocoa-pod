//
//  CPHttpRequest.m
//  CPHttpRequest
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

#import "CPHttpRequest_Inheritance.h"
#import "NSMutableDictionary_Types.h"

#import "CPHttpRequestManager.h"
#import "CPDebug.h"
#import "CPURLUtils.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"

#define kPAHttpRequestDefaultTimeout 60.0

typedef enum
{
	CPHttpRequestStateCreate,
	CPHttpRequestStateStarted,
	CPHttpRequestStateFinished,
	CPHttpRequestStateFinishedError,
    CPHttpRequestStateCanceled
} CPHttpRequestState;

@interface CPHttpRequest ()
{
    NSURLConnection     * _connection;
    CPHttpRequestState    _state;
    NSMutableURLRequest * _request;
    NSMutableData       * _responseData;
}

@property (nonatomic, copy) CPHttpRequestCompletion completionBlock;

@end

@implementation CPHttpRequest

+ (id)requestWithURLRequest:(NSURLRequest *)request
{
    return [[self alloc] initWithURLRequest:request];
}

- (id)initWithURLRequest:(NSURLRequest *)request
{
    self = [super init];
    if (self)
    {
        _state = CPHttpRequestStateCreate;
        _request = [request mutableCopy];
    }
    return self;
}


- (void)startWithCompletionBlock:(CPHttpRequestCompletion)completion
{
    self.completionBlock = completion;
    
    CPAssert(_state == CPHttpRequestStateCreate);
    _state = CPHttpRequestStateStarted;
    
    [self openConnection];
}

- (void)cancel
{
    [self calculateRequestDuration];
    if (_state == CPHttpRequestStateStarted)
    {
        [self notifyCancelTarget];
    }
    [self cancelInLoop];
}

- (void)cancelInLoop
{
    _state = CPHttpRequestStateCanceled;
    [self releaseConnection];
    self.completionBlock = nil; // don't let a retain cycle
}

- (void)finish
{   
    [self calculateRequestDuration];
    if (![self isCanceled])
    {
        [self notifyFinishTarget];
    }
    [self releaseConnection];
    self.completionBlock = nil; // don't let a retain cycle
}

- (void)finishWithError:(NSError *)error
{
    [self calculateRequestDuration];
    if (![self isCanceled])
    {
        _error = error;
        [self notifyErrorTarget:error];
    }
    [self releaseConnection];
    self.completionBlock = nil; // don't let a retain cycle
}

- (void)finishWithErrorMessage:(NSString *)message andErrorCode:(NSInteger)code
{
    NSError *error = [[CPHttpRequestError alloc] initWithRequest:self
                                                       errorCode:code
                                                      andMessage:message];
    [self finishWithError:error];
}

- (void)notifyFinishTarget
{
    if (_completionBlock) {
        _completionBlock(self, nil, NO);
    }
}

- (void)notifyErrorTarget:(NSError *)error
{
    if (_completionBlock) {
        _completionBlock(self, error, NO);
    }
}

- (void)notifyCancelTarget
{
    if (_completionBlock) {
        _completionBlock(self, nil, YES);
    }
}

- (BOOL)isCanceled
{
    return _state == CPHttpRequestStateCanceled;
}

#pragma mark -
#pragma mark Request duration

- (void)setupRequestStartDate
{
    _startDate = [NSDate date];
}

- (void)calculateRequestDuration
{
    _duration = -[self.startDate timeIntervalSinceNow];
}

#pragma mark -
#pragma mark Connection

- (void)openConnection
{
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    if (connection != nil)
    {
        _connection = connection;
        _responseData = [NSMutableData data];
        
        [self setupRequestStartDate];
    }
    else
    {
        [self finishWithErrorMessage:@"Can't create connection" andErrorCode:CPHttpRequestErrorCodeConnectionError];
    }
}

- (void)releaseConnection
{
    [_connection cancel];
    _connection = nil;
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    _responseCode = httpResponse.statusCode;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        if (_responseCode != 200)
        {
            NSString *message = [[NSString alloc] initWithFormat:@"Unexpected status code: %d", _responseCode];
            [self finishWithErrorMessage:message andErrorCode:CPHttpRequestErrorCodeUnexpectedHttpCode];
            return;
        }
    }
    [_responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self releaseConnection];
    [self finishWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self finish];
    [self releaseConnection];
}

@end

#pragma clang diagnostic pop
