//
// Copyright (c) 2014 XING AG (http://xing.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM (NSUInteger, AFOAuthSignatureMethod) {
    AFPlainTextSignatureMethod = 1,
    AFHMACSHA1SignatureMethod = 2,
};

typedef NS_ENUM (NSUInteger, AFHTTPClientParameterEncoding) {
    AFFormURLParameterEncoding,
    AFJSONParameterEncoding,
    AFPropertyListParameterEncoding,
};

typedef void (^AFServiceProviderRequestHandlerBlock)(NSURLRequest *request);
typedef void (^AFServiceProviderRequestCompletionBlock)();

@class XNGOAuthToken;

@interface XNGOAuth1Client : AFHTTPRequestOperationManager

@property (readwrite, nonatomic, copy) NSURL *url;
@property (readwrite, nonatomic, copy) NSString *key;
@property (readwrite, nonatomic, copy) NSString *secret;
@property (readwrite, nonatomic, strong) id applicationLaunchNotificationObserver;
@property (readwrite, nonatomic, copy) AFServiceProviderRequestHandlerBlock serviceProviderRequestHandler;
@property (readwrite, nonatomic, copy) AFServiceProviderRequestCompletionBlock serviceProviderRequestCompletion;

#pragma mark - Managing OAuth Configuration

@property (nonatomic, assign) AFOAuthSignatureMethod signatureMethod;
@property (nonatomic, assign) AFHTTPClientParameterEncoding parameterEncoding;
@property (nonatomic, copy) NSString *realm;
@property (nonatomic) XNGOAuthToken *accessToken;
@property (nonatomic) NSString *oauthAccessMethod;
@property (nonatomic) NSMutableDictionary *defaultHeaders;
@property (nonatomic) NSStringEncoding stringEncoding;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters;

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
                  key:(NSString *)key
               secret:(NSString *)secret;

#pragma mark - Authenticating

- (void)authorizeUsingOAuthWithRequestTokenPath:(NSString *)requestTokenPath
                          userAuthorizationPath:(NSString *)userAuthorizationPath
                                    callbackURL:(NSURL *)callbackURL
                                accessTokenPath:(NSString *)accessTokenPath
                                   accessMethod:(NSString *)accessMethod
                                          scope:(NSString *)scope
                                        success:(void (^)(XNGOAuthToken *accessToken, id responseObject))success
                                        failure:(void (^)(NSError *error))failure;

- (void)acquireOAuthRequestTokenWithPath:(NSString *)path
                             callbackURL:(NSURL *)url
                            accessMethod:(NSString *)accessMethod
                                   scope:(NSString *)scope
                                 success:(void (^)(XNGOAuthToken *requestToken, id responseObject))success
                                 failure:(void (^)(NSError *error))failure;

- (void)acquireOAuthAccessTokenWithPath:(NSString *)path
                           requestToken:(XNGOAuthToken *)requestToken
                           accessMethod:(NSString *)accessMethod
                                success:(void (^)(XNGOAuthToken *accessToken, id responseObject))success
                                failure:(void (^)(NSError *error))failure;

/**
 *  Configuring Service Provider Request Handling
 */
- (void)setServiceProviderRequestHandler:(void (^)(NSURLRequest *request))block
                              completion:(void (^)())completion;
@end

#pragma mark - Constants

extern NSString *const kAFApplicationLaunchedWithURLNotification;
extern NSString *const kAFApplicationLaunchOptionsURLKey;
