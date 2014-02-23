#import <AFNetworking/AFHTTPRequestOperationManager.h>

@class XNGOAuth1RequestSerializer;

@interface XNGOAuth1RequestOperationManager : AFHTTPRequestOperationManager

@property (nonatomic) XNGOAuth1RequestSerializer *requestSerializer;
@property (nonatomic, readonly, getter=isAuthorized) BOOL authorized;

- (id)initWithBaseURL:(NSURL *)baseURL consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

- (BOOL)deauthorize;

@end
