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

#import "XNGOAuth1Client.h"
#import "XNGOAuthToken.h"
#import <CommonCrypto/CommonHMAC.h>

static NSString *const kAFOAuth1Version = @"1.0";
NSString *const kAFApplicationLaunchedWithURLNotification = @"kAFApplicationLaunchedWithURLNotification";
#if __IPHONE_OS_VERSION_MIN_REQUIRED
NSString *const kAFApplicationLaunchOptionsURLKey = @"UIApplicationLaunchOptionsURLKey";
#else
NSString *const kAFApplicationLaunchOptionsURLKey = @"NSApplicationLaunchOptionsURLKey";
#endif

static NSString *AFEncodeBase64WithData(NSData *data) {
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];

    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];

    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (uint8_t)((i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=');
        output[idx + 3] = (uint8_t)((i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=');
    }

    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSString *AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString *const kAFCharactersToBeEscaped = @":/?&=;+!@#$()',*";
    static NSString *const kAFCharactersToLeaveUnescaped = @"[].";

    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAFCharactersToLeaveUnescaped, (__bridge CFStringRef)kAFCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static inline NSString *AFNounce() {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);

    return (NSString *)CFBridgingRelease(string);
}

static inline NSString *NSStringFromAFOAuthSignatureMethod(AFOAuthSignatureMethod signatureMethod) {
    switch (signatureMethod) {
        case AFPlainTextSignatureMethod:
            return @"PLAINTEXT";
        case AFHMACSHA1SignatureMethod:
            return @"HMAC-SHA1";
        default:
            return nil;
    }
}

static inline NSString *AFPlainTextSignature(NSString *consumerSecret, NSString *tokenSecret) {
    NSString *secret = tokenSecret ? tokenSecret : @"";
    NSString *signature = [NSString stringWithFormat:@"%@&%@", consumerSecret, secret];
    return signature;
}

static inline NSString *AFHMACSHA1Signature(NSURLRequest *request, NSString *consumerSecret, NSString *tokenSecret, NSStringEncoding stringEncoding) {
    NSString *secret = tokenSecret ? tokenSecret : @"";
    NSString *secretString = [NSString stringWithFormat:@"%@&%@", AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(consumerSecret, stringEncoding), AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(secret, stringEncoding)];
    NSData *secretStringData = [secretString dataUsingEncoding:stringEncoding];

    NSString *queryString = AFPercentEscapedQueryStringPairMemberFromStringWithEncoding([[[[[request URL] query] componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@"&"], stringEncoding);
    NSString *requestString = [NSString stringWithFormat:@"%@&%@&%@", [request HTTPMethod], AFPercentEscapedQueryStringPairMemberFromStringWithEncoding([[[request URL] absoluteString] componentsSeparatedByString:@"?"][0], stringEncoding), queryString];
    NSData *requestStringData = [requestString dataUsingEncoding:stringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA1, [secretStringData bytes], [secretStringData length]);
    CCHmacUpdate(&cx, [requestStringData bytes], [requestStringData length]);
    CCHmacFinal(&cx, digest);

    return AFEncodeBase64WithData([NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH]);
}

@implementation XNGOAuth1Client

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.url = url;
        self.signatureMethod = AFHMACSHA1SignatureMethod;
        self.oauthAccessMethod = @"GET";
        self.defaultHeaders = [NSMutableDictionary dictionary];
        self.parameterEncoding = AFFormURLParameterEncoding;
        self.stringEncoding = NSUTF8StringEncoding;
        self.responseSerializer = [AFHTTPResponseSerializer serializer];

        // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
        NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
        [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            float q = 1.0f - (idx * 0.1f);
            [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
            *stop = q <= 0.5f;
        }];
        [self setDefaultHeader:@"Accept-Language" value:[acceptLanguagesComponents componentsJoinedByString:@", "]];

        NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
        userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *) kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *) kCFBundleIdentifierKey], (__bridge id) CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *) kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleExecutableKey] ? :[[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ? :[[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
#pragma clang diagnostic pop
        if (userAgent) {
            if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                NSMutableString *mutableUserAgent = [userAgent mutableCopy];
                CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, kCFStringTransformToLatin, false);
                userAgent = mutableUserAgent;
            }
            [self setDefaultHeader:@"User-Agent" value:userAgent];
        }
    }

    return self;
}

- (instancetype)initWithBaseURL:(NSURL *)url
                            key:(NSString *)clientID
                         secret:(NSString *)secret {
    self = [self initWithBaseURL:url];
    if (self) {
        self.key = clientID;
        self.secret = secret;
    }

    return self;
}

- (void)dealloc {
    self.applicationLaunchNotificationObserver = nil;
}

- (void)setApplicationLaunchNotificationObserver:(id)applicationLaunchNotificationObserver {
    if (_applicationLaunchNotificationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationLaunchNotificationObserver];
    }

    [self willChangeValueForKey:@"applicationLaunchNotificationObserver"];
    _applicationLaunchNotificationObserver = applicationLaunchNotificationObserver;
    [self didChangeValueForKey:@"applicationLaunchNotificationObserver"];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
    [self.defaultHeaders setValue:value forKey:header];
}

- (NSDictionary *)OAuthParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"oauth_version"] = kAFOAuth1Version;
    parameters[@"oauth_signature_method"] = NSStringFromAFOAuthSignatureMethod(self.signatureMethod);
    parameters[@"oauth_consumer_key"] = self.key;
    parameters[@"oauth_timestamp"] = [@(floor([[NSDate date] timeIntervalSince1970]))stringValue];
    parameters[@"oauth_nonce"] = AFNounce();

    if (self.realm) {
        parameters[@"realm"] = self.realm;
    }

    return parameters;
}

- (NSString *)OAuthSignatureForMethod:(NSString *)method
                                 path:(NSString *)path
                           parameters:(NSDictionary *)parameters
                                token:(XNGOAuthToken *)token {
    NSMutableURLRequest *request = [self encodedRequestWithMethod:@"GET" path:path parameters:parameters];
    [request setHTTPMethod:method];

    NSString *tokenSecret = token ? token.secret : nil;

    switch (self.signatureMethod) {
        case AFPlainTextSignatureMethod :
            return AFPlainTextSignature(self.secret, tokenSecret);
        case AFHMACSHA1SignatureMethod :
            return AFHMACSHA1Signature(request, self.secret, tokenSecret, self.stringEncoding);
        default :
            return nil;
    }
}

- (NSString *)authorizationHeaderForMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters {
    static NSString *const kAFOAuth1AuthorizationFormatString = @"OAuth %@";

    NSMutableDictionary *mutableParameters = parameters ? [parameters mutableCopy] : [NSMutableDictionary dictionary];
    NSMutableDictionary *mutableAuthorizationParameters = [NSMutableDictionary dictionary];

    if (self.key && self.secret) {
        [mutableAuthorizationParameters addEntriesFromDictionary:[self OAuthParameters]];
        if (self.accessToken) {
            mutableAuthorizationParameters[@"oauth_token"] = self.accessToken.key;
        }
    }

    [mutableParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [key hasPrefix:@"oauth_"]) {
            mutableAuthorizationParameters[key] = obj;
        }
    }];

    [mutableParameters addEntriesFromDictionary:mutableAuthorizationParameters];
    mutableAuthorizationParameters[@"oauth_signature"] = [self OAuthSignatureForMethod:method path:path parameters:mutableParameters token:self.accessToken];
    NSArray *sortedComponents = [mutableAuthorizationParameters.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *mutableComponents = [NSMutableArray array];
    for (NSString *key in sortedComponents) {
        NSString *value = AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(mutableAuthorizationParameters[key], NSASCIIStringEncoding);
        [mutableComponents addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, value]];
    }

    NSString *authorizationHeader = [NSString stringWithFormat:kAFOAuth1AuthorizationFormatString, [mutableComponents componentsJoinedByString:@", "]];
    return authorizationHeader;
}

#pragma mark -

- (void)authorizeUsingOAuthWithRequestTokenPath:(NSString *)requestTokenPath
                          userAuthorizationPath:(NSString *)userAuthorizationPath
                                    callbackURL:(NSURL *)callbackURL
                                accessTokenPath:(NSString *)accessTokenPath
                                   accessMethod:(NSString *)accessMethod
                                          scope:(NSString *)scope
                                        success:(void (^)(XNGOAuthToken *accessToken, id responseObject))success
                                        failure:(void (^)(NSError *error))failure {
    [self acquireOAuthRequestTokenWithPath:requestTokenPath callbackURL:callbackURL accessMethod:accessMethod scope:scope success:^(XNGOAuthToken *requestToken, id responseObject) {
        __block XNGOAuthToken *currentRequestToken = requestToken;

        self.applicationLaunchNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAFApplicationLaunchedWithURLNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
                NSURL *url = [[notification userInfo] valueForKey:kAFApplicationLaunchOptionsURLKey];

                currentRequestToken.verifier = [[XNGOAuthToken parametersFromQueryString:[url query]] valueForKey:@"oauth_verifier"];

                [self acquireOAuthAccessTokenWithPath:accessTokenPath requestToken:currentRequestToken accessMethod:accessMethod success:^(XNGOAuthToken *accessToken, id secondResponseObject) {
                        if (self.serviceProviderRequestCompletion) {
                            self.serviceProviderRequestCompletion();
                        }

                        self.applicationLaunchNotificationObserver = nil;
                        if (accessToken) {
                            self.accessToken = accessToken;

                            if (success) {
                                success(accessToken, secondResponseObject);
                            }
                        } else {
                            if (failure) {
                                failure(nil);
                            }
                        }
                    } failure:^(NSError *error) {
                        self.applicationLaunchNotificationObserver = nil;
                        if (failure) {
                            failure(error);
                        }
                    }];
            }];

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"oauth_token"] = requestToken.key;
        NSMutableURLRequest *request = [self encodedRequestWithMethod:@"GET" path:userAuthorizationPath parameters:parameters];
        [request setHTTPShouldHandleCookies:NO];

        if (self.serviceProviderRequestHandler) {
            self.serviceProviderRequestHandler(request);
        } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
            [[UIApplication sharedApplication] openURL:[request URL]];
#else
            [[NSWorkspace sharedWorkspace] openURL:[request URL]];
#endif
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)acquireOAuthRequestTokenWithPath:(NSString *)path
                             callbackURL:(NSURL *)callbackURL
                            accessMethod:(NSString *)accessMethod
                                   scope:(NSString *)scope
                                 success:(void (^)(XNGOAuthToken *requestToken, id responseObject))success
                                 failure:(void (^)(NSError *error))failure {
    NSMutableDictionary *parameters = [[self OAuthParameters] mutableCopy];
    parameters[@"oauth_callback"] = [callbackURL absoluteString];
    if (scope && !self.accessToken) {
        parameters[@"scope"] = scope;
    }

    NSMutableURLRequest *request = [self requestWithMethod:accessMethod path:path parameters:parameters];
    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            XNGOAuthToken *accessToken = [[XNGOAuthToken alloc] initWithQueryString:operation.responseString];
            success(accessToken, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [self.operationQueue addOperation:requestOperation];
}

- (void)acquireOAuthAccessTokenWithPath:(NSString *)path
                           requestToken:(XNGOAuthToken *)requestToken
                           accessMethod:(NSString *)accessMethod
                                success:(void (^)(XNGOAuthToken *accessToken, id responseObject))success
                                failure:(void (^)(NSError *error))failure {
    if (requestToken.key && requestToken.verifier) {
        self.accessToken = requestToken;

        NSMutableDictionary *parameters = [[self OAuthParameters] mutableCopy];
        parameters[@"oauth_token"] = requestToken.key;
        parameters[@"oauth_verifier"] = requestToken.verifier;

        NSMutableURLRequest *request = [self requestWithMethod:accessMethod path:path parameters:parameters];
        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                XNGOAuthToken *accessToken = [[XNGOAuthToken alloc] initWithQueryString:operation.responseString];
                success(accessToken, responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(error);
            }
        }];

        [self.operationQueue addOperation:requestOperation];
    } else {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : NSLocalizedStringFromTable(@"Bad OAuth response received from the server.", @"AFNetworking", nil)};
        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        failure(error);
    }
}

#pragma mark -

- (void)setServiceProviderRequestHandler:(void (^)(NSURLRequest *request))block
                              completion:(void (^)())completion {
    self.serviceProviderRequestHandler = block;
    self.serviceProviderRequestCompletion = completion;
}

#pragma mark - AFHTTPClient

- (NSMutableURLRequest *)encodedRequestWithMethod:(NSString *)method
                                             path:(NSString *)path
                                       parameters:(NSDictionary *)parameters {
    NSParameterAssert(method);

    if (!path) {
        path = @"";
    }

    NSURL *url = [NSURL URLWithString:path relativeToURL:self.url];
    for (NSString *key in self.defaultHeaders.allKeys) {
        id value = (self.defaultHeaders)[key];
        [self.requestSerializer setValue:value forHTTPHeaderField:key];
    }
    return [self.requestSerializer requestWithMethod:method URLString:url.absoluteString parameters:parameters error:nil];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters {
    NSMutableDictionary *mutableParameters = [parameters mutableCopy];
    for (NSString *key in parameters) {
        if ([key hasPrefix:@"oauth_"]) {
            [mutableParameters removeObjectForKey:key];
        }
    }

    NSMutableURLRequest *request = [self encodedRequestWithMethod:method path:path parameters:mutableParameters];

    // Only use parameters in the request entity body (with a content-type of `application/x-www-form-urlencoded`).
    // See RFC 5849, Section 3.4.1.3.1 http://tools.ietf.org/html/rfc5849#section-3.4
    NSDictionary *authorizationParameters = parameters;
    if (!([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"])) {
        authorizationParameters = ([[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"application/x-www-form-urlencoded"] ? parameters : nil);
    }

    [request setValue:[self authorizationHeaderForMethod:method path:path parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block {
    NSError *error;
    NSMutableURLRequest *request = [[AFHTTPRequestOperationManager manager].requestSerializer multipartFormRequestWithMethod:method URLString:self.url.absoluteString parameters:parameters constructingBodyWithBlock:block error:&error];

    // Only use parameters in the HTTP POST request body (with a content-type of `application/x-www-form-urlencoded`).
    // See RFC 5849, Section 3.4.1.3.1 http://tools.ietf.org/html/rfc5849#section-3.4
    NSDictionary *authorizationParameters = ([[request valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"application/x-www-form-urlencoded"] ? parameters : nil);
    [request setValue:[self authorizationHeaderForMethod:method path:path parameters:authorizationParameters] forHTTPHeaderField:@"Authorization"];
    [request setHTTPShouldHandleCookies:NO];

    return request;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.key = [decoder decodeObjectForKey:NSStringFromSelector(@selector(key))];
    self.secret = [decoder decodeObjectForKey:NSStringFromSelector(@selector(secret))];
    self.signatureMethod = (AFOAuthSignatureMethod)[decoder decodeIntegerForKey : NSStringFromSelector(@selector(signatureMethod))];
    self.realm = [decoder decodeObjectForKey:NSStringFromSelector(@selector(realm))];
    self.accessToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(accessToken))];
    self.oauthAccessMethod = [decoder decodeObjectForKey:NSStringFromSelector(@selector(oauthAccessMethod))];
    self.defaultHeaders = [decoder decodeObjectForKey:@"defaultHeaders"];
    self.parameterEncoding = (AFHTTPClientParameterEncoding) [decoder decodeIntegerForKey : @"parameterEncoding"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.key forKey:NSStringFromSelector(@selector(key))];
    [coder encodeObject:self.secret forKey:NSStringFromSelector(@selector(secret))];
    [coder encodeInteger:self.signatureMethod forKey:NSStringFromSelector(@selector(signatureMethod))];
    [coder encodeObject:self.realm forKey:NSStringFromSelector(@selector(realm))];
    [coder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
    [coder encodeObject:self.oauthAccessMethod forKey:NSStringFromSelector(@selector(oauthAccessMethod))];
    [coder encodeObject:self.defaultHeaders forKey:@"defaultHeaders"];
    [coder encodeInteger:self.parameterEncoding forKey:@"parameterEncoding"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    XNGOAuth1Client *copy = [(XNGOAuth1Client *)[[self class] allocWithZone:zone] initWithBaseURL : self.url
                             key : self.key
                             secret : self.secret];
    copy.signatureMethod = self.signatureMethod;
    copy.realm = self.realm;
    copy.accessToken = self.accessToken;
    copy.oauthAccessMethod = self.oauthAccessMethod;
    copy.defaultHeaders = [self.defaultHeaders mutableCopyWithZone:zone];
    copy.parameterEncoding = self.parameterEncoding;

    return copy;
}

@end
