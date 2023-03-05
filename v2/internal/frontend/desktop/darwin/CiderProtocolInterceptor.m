//
//  ReplacingImageURLProtocol.m
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "CiderProtocolInterceptor.h"

static NSString * const MyURLProtocolHandledKey = @"MyURLProtocolHandledKey";

@interface CiderProtocolInterceptor () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation CiderProtocolInterceptor

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:MyURLProtocolHandledKey inRequest:request]) {
        return NO;
    }

    if ( (!([[request.URL absoluteString] containsString:@".png"] || [[request.URL absoluteString] containsString:@".jpg"] || [[request.URL absoluteString] containsString:@".webp"] ))
         && ([[request.URL absoluteString] containsString:@"apple.com"] || [[request.URL absoluteString] containsString:@"cider.sh"])) {
        return YES;
    }
    return NO;
}

- (void)startLoading
{
        NSMutableURLRequest *interceptorRequest = [self.request mutableCopy];
        if ([[interceptorRequest.URL absoluteString] containsString:@"?cider-cheeky-query="]){
            NSRange findRange = [[interceptorRequest.URL absoluteString] rangeOfString:@"?cider-cheeky-query="];

            NSRange searchRange1 = NSMakeRange(0 , findRange.location);
            NSRange searchRange2 = NSMakeRange(findRange.location + 20  , [[interceptorRequest.URL absoluteString] length]  - findRange.location - 20 );
            NSString *b64body = [[interceptorRequest.URL absoluteString] substringWithRange:searchRange2]; 
            NSString *realURL = [[interceptorRequest.URL absoluteString] substringWithRange:searchRange1]; 
            NSURL *anotherURL = [NSURL URLWithString:realURL];
            NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:b64body options:0];
            NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            [interceptorRequest setHTTPBody:[decodedString dataUsingEncoding:NSUTF8StringEncoding]];
            [interceptorRequest setURL:anotherURL];
            // NSLog(@"%@", realURL);
            // NSLog(@"%@", b64body);
            // NSLog(@"%@", decodedString);
        }     
        [NSURLProtocol setProperty:@YES forKey:MyURLProtocolHandledKey inRequest:interceptorRequest];
        [interceptorRequest setValue:@"Cider-2;?client=dotnet" forHTTPHeaderField:@"User-Agent"];
        [interceptorRequest setValue:@"1" forHTTPHeaderField:@"DNT"];
        [interceptorRequest setValue:@"amp-api.music.apple.com" forHTTPHeaderField:@"Authority" ];
        [interceptorRequest setValue:@"https://beta.music.apple.com" forHTTPHeaderField:@"Origin" ];
        [interceptorRequest setValue:@"https://beta.music.apple.com" forHTTPHeaderField:@"Referer" ];
        [interceptorRequest setValue:@"empty" forHTTPHeaderField:@"sec-fetch-dest" ];
        [interceptorRequest setValue:@"cors" forHTTPHeaderField:@"sec-fetch-mode"];
        [interceptorRequest setValue:@"same-site" forHTTPHeaderField:@"sec-fetch-site"];
        self.connection = [NSURLConnection connectionWithRequest:interceptorRequest delegate:self];
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



