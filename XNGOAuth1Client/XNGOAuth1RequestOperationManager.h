#import <AFNetworking/AFHTTPRequestOperationManager.h>

@class XNGOAuth1RequestSerializer;
@class XNGOAuthToken;

FOUNDATION_EXPORT NSString *const XNGOAuth1ErrorDomain;

@interface XNGOAuth1RequestOperationManager : AFHTTPRequestOperationManager

@property (nonatomic) XNGOAuth1RequestSerializer *requestSerializer;
@property (nonatomic, readonly, getter=isAuthorized) BOOL authorized;

- (id)initWithBaseURL:(NSURL *)baseURL consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

- (BOOL)deauthorize;

- (void)authorizeUsingOAuthWithRequestTokenPath:(NSString *)requestTokenPath
                          userAuthorizationPath:(NSString *)userAuthorizationPath
                                    callbackURL:(NSURL *)callbackURL
                                accessTokenPath:(NSString *)accessTokenPath
                                   accessMethod:(NSString *)accessMethod
                                          scope:(NSString *)scope
                                        success:(void (^)(XNGOAuthToken *oAuthToken, id responseObject))success
                                        failure:(void (^)(NSError *error))failure;

- (void)acquireOAuthRequestTokenWithPath:(NSString *)path
                             callbackURL:(NSURL *)callbackURL
                            accessMethod:(NSString *)accessMethod
                            requestToken:(XNGOAuthToken *)requestToken
                                   scope:(NSString *)scope
                                 success:(void (^)(XNGOAuthToken *requestToken, id responseObject))success
                                 failure:(void (^)(NSError *error))failure;

@end
