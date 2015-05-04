//
//  CPBaseAdView.m
//  CPBaseAdView
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

#import "CPBaseAdView.h"

#import "CPCommon.h"

typedef enum {
    CPBaseAdViewContentStateCreated,
    CPBaseAdViewContentStateLoading,
    CPBaseAdViewContentStateLoaded,
    CPBaseAdViewContentStateNotLoaded
} CPBaseAdViewContentState;

@interface CPBaseAdView ()
{
    CPBaseAdViewContentState _state;
}
@end

@implementation CPBaseAdView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _state  = CPBaseAdViewContentStateCreated;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

#pragma mark -
#pragma mark Content

- (void)loadContent
{
    _state = CPBaseAdViewContentStateLoading;
}

- (void)cancelLoadContent
{
    _state = CPBaseAdViewContentStateNotLoaded;
    [self notifyCancelLoad];
}

- (BOOL)isContentLoaded
{
    return _state == CPBaseAdViewContentStateLoaded;
}

- (BOOL)isContentLoading
{
    return _state == CPBaseAdViewContentStateLoading;
}

- (void)contentDidLoad
{
    _state = CPBaseAdViewContentStateLoaded;
    [self notifyContentDidLoad];
}

- (void)contentDidFailWithError:(NSError *)error
{
    [self notifyFailLoadWithError:error];
}

#pragma mark -
#pragma mark Lifecycle

- (void)start
{
}

- (void)stop
{
    if ([self isContentLoading])
    {
        [self cancelLoadContent];
    }
}

#pragma mark -
#pragma mark Content notifications

- (void)notifyStartLoad
{
    if ([_contentDelegate respondsToSelector:@selector(adViewDidStartLoad:)]) {
        [_contentDelegate adViewDidStartLoad:self];
    }
}

- (void)notifyContentDidLoad
{
    if ([_contentDelegate respondsToSelector:@selector(adViewDidFinishLoad:)]) {
        [_contentDelegate adViewDidFinishLoad:self];
    }
}

- (void)notifyFailLoadWithError:(NSError *)error
{
    if ([_contentDelegate respondsToSelector:@selector(adView:didFailLoadWithError:)]) {
        [_contentDelegate adView:self didFailLoadWithError:error];
    }
}

- (void)notifyCancelLoad
{
    if ([_contentDelegate respondsToSelector:@selector(adViewDidCancelLoad:)]) {
        [_contentDelegate adViewDidCancelLoad:self];
    }
}

@end
