//
//  ReplacingImageURLProtocol.h
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CiderProtocolInterceptor : NSURLProtocol

@property (nonatomic, readwrite, strong) NSURLConnection *connection;

@end

NS_ASSUME_NONNULL_END