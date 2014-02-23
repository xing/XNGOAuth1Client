#import "XNGOAuth1RequestOperationManager.h"
#import "XNGOAuth1RequestSerializer.h"
#import "XNGOAuthToken.h"

@implementation XNGOAuth1RequestOperationManager

- (id)initWithBaseURL:(NSURL *)baseURL consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    self = [super initWithBaseURL:baseURL];

    if (self) {
        self.requestSerializer = [[XNGOAuth1RequestSerializer alloc] initWithService:baseURL.host
                                                                         consumerKey:consumerKey
                                                                              secret:consumerSecret];
    }

    return self;
}

- (BOOL)isAuthorized {
    return (self.requestSerializer.accessToken && !self.requestSerializer.accessToken.isExpired);
}

- (BOOL)deauthorize {
    return [self.requestSerializer removeAccessToken];
}

@end
