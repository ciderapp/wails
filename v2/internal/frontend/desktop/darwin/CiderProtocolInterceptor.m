//
//  ReplacingImageURLProtocol.m
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "CiderProtocolInterceptor.h"

@interface CiderProtocolInterceptor () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation CiderProtocolInterceptor

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSLog(@"[%@] Requesting....", NSStringFromClass([self class]));  
    if ([[request.URL absoluteString] containsString:@"apple.com"] || [[request.URL absoluteString] containsString:@"cider.sh"]) {
        return YES;
    }
    return NO;
}

- (void)startLoading
{
        NSMutableURLRequest *interceptorRequest = [self.request mutableCopy];
        [interceptorRequest setValue:@"Cider-2;?client=dotnet" forHTTPHeaderField:@"User-Agent"];
        [interceptorRequest setValue:@"1" forHTTPHeaderField:@"DNT"];
        [interceptorRequest setValue:@"amp-api.music.apple.com" forHTTPHeaderField:@"Authority" ];
        [interceptorRequest setValue:@"https://music.apple.com" forHTTPHeaderField:@"Origin" ];
        [interceptorRequest setValue:@"https://music.apple.com" forHTTPHeaderField:@"Referer" ];
        [interceptorRequest setValue:@"empty" forHTTPHeaderField:@"sec-fetch-dest" ];
        [interceptorRequest setValue:@"cors" forHTTPHeaderField:@"sec-fetch-mode"];
        [interceptorRequest setValue:@"same-site" forHTTPHeaderField:@"sec-fetch-site"];
        self.connection = [NSURLConnection connectionWithRequest:interceptorRequest delegate:self];
        [self.connection start];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}
- (void)stopLoading
{
    [self.connection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}
@end



