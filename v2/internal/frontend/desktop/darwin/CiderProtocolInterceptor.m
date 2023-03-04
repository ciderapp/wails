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
    
    if ([request.URL.absoluteString hasPrefix:@"https"] || [request.URL.absoluteString hasPrefix:@"http"]) {
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
}

@end