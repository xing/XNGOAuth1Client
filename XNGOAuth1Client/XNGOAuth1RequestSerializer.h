#import <AFNetworking/AFURLRequestSerialization.h>

@class XNGOAuthToken;

@interface XNGOAuth1RequestSerializer : AFHTTPRequestSerializer

- (id)initWithService:(NSString *)service consumerKey:(NSString *)consumerKey secret:(NSString *)consumerSecret;

- (XNGOAuthToken *)accessToken;

- (BOOL)saveAccessToken:(XNGOAuthToken *)oauthToken;

@end
