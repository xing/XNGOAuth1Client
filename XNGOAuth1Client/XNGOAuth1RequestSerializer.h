#import <AFNetworking/AFURLRequestSerialization.h>

@interface XNGOAuth1RequestSerializer : AFHTTPRequestSerializer

- (id)initWithService:(NSString *)service consumerKey:(NSString *)consumerKey secret:(NSString *)consumerSecret;

@end
