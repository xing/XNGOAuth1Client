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

+ (NSString *)queryStringFromParameters:(NSDictionary *)parameters encoding:(NSStringEncoding)stringEncoding;

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
