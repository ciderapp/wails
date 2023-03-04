//
//  ReplacingImageURLProtocol.m
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "CiderProtocolInterceptor.h"
#import <Foundation/Foundation.h>

static NSString* const FilteredKey = @"FilteredKey";

@implementation CiderProtocolInterceptor

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
     NSLog(@"[%@] Requesting....", NSStringFromClass([self class]));
    
    if ([[request.URL path] containsString:@"apple.com"] || [[request.URL path] containsString:@"cider.sh"]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *) request {
    NSLog(@"[%@] canonicalRequestForRequest", NSStringFromClass([self class]));
    return request;
}

- (void)startLoading {
    NSLog(@"[%@] Starting Loading the request: %@", NSStringFromClass([self class]),[[self request] allHTTPHeaderFields]);
    
        NSMutableURLRequest *interceptorRequest =
        #if WORKAROUND_MUTABLE_COPY_LEAK
            [[self request] avoidMutableCopyLeak];
        #else
            [[self request] mutableCopy];
        #endif
        [interceptorRequest setValue:@"User-Agent" forHTTPHeaderField:@"Cider-2;?client=dotnet"];
        [interceptorRequest setValue:@"DNT" forHTTPHeaderField:@"1"];
        [interceptorRequest setValue:@"authority" forHTTPHeaderField:@"amp-api.music.apple.com"];
        [interceptorRequest setValue:@"origin" forHTTPHeaderField:@"https://music.apple.com"];
        [interceptorRequest setValue:@"referer" forHTTPHeaderField:@"https://music.apple.com"];
        [interceptorRequest setValue:@"sec-fetch-dest" forHTTPHeaderField:@"empty"];
        [interceptorRequest setValue:@"sec-fetch-mode" forHTTPHeaderField:@"cors"];
        [interceptorRequest setValue:@"sec-fetch-site" forHTTPHeaderField:@"same-site"];
    
         [self setConnection:[NSURLConnection connectionWithRequest:interceptorRequest delegate:self]];

}

- (void)stopLoading {
    [[self connection] cancel];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    NSLog(@"[%@] Will send request: %@ ", NSStringFromClass([self class]), [request allHTTPHeaderFields]);

    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"[%@] Received response code: %ld", NSStringFromClass([self class]), (long)[((NSHTTPURLResponse *) response) statusCode]);
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"[%@] Received data\n%@", NSStringFromClass([self class]), [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);

    [[self client] URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"[%@] Finish loading", NSStringFromClass([self class]));

    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"[%@] Failed With error: %@", NSStringFromClass([self class]), error.debugDescription);
    
    [[self client] URLProtocol:self didFailWithError:error];
}

#if WORKAROUND_MUTABLE_COPY_LEAK
@implementation NSURLRequest(AvoidMutableCopyLeak)

- (id) avoidMutableCopyLeak {
    
    NSMutableURLRequest *mutableURLRequest = [self mutableCopy];

    return mutableURLRequest;
}

@end
#endif

@end