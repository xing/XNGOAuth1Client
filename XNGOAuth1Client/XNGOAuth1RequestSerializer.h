#import <AFNetworking/AFURLRequestSerialization.h>

@class XNGOAuthToken;

@interface XNGOAuth1RequestSerializer : AFHTTPRequestSerializer

@property (nonatomic) XNGOAuthToken *requestToken;

- (id)initWithService:(NSString *)service consumerKey:(NSString *)consumerKey secret:(NSString *)consumerSecret;

- (XNGOAuthToken *)accessToken;

- (BOOL)saveAccessToken:(XNGOAuthToken *)oauthToken;

- (BOOL)removeAccessToken;

@end
