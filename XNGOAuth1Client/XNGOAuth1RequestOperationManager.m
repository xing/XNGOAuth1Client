#import "XNGOAuth1RequestOperationManager.h"
#import "XNGOAuthToken.h"

NSString * const XNGOAuth1ErrorDomain = @"XNGOAuth1ErrorDomain";

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

- (void)authorizeUsingOAuthWithRequestTokenPath:(NSString *)requestTokenPath
                          userAuthorizationPath:(NSString *)userAuthorizationPath
                                    callbackURL:(NSURL *)callbackURL
                                accessTokenPath:(NSString *)accessTokenPath
                                   accessMethod:(NSString *)accessMethod
                                          scope:(NSString *)scope
                                        success:(void (^)(XNGOAuthToken *oAuthToken, id responseObject))success
                                        failure:(void (^)(NSError *error))failure {
    self.requestSerializer.requestToken = nil;

    AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
    self.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"oauth_callback"] = [callbackURL absoluteString];
    if (scope && !self.requestSerializer.accessToken)
        parameters[@"scope"] = scope;

    NSString *URLString = [[NSURL URLWithString:requestTokenPath relativeToURL:self.baseURL] absoluteString];
    NSError *error;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:accessMethod URLString:URLString parameters:parameters error:&error];

    if (error)
    {
        failure(error);
        return;
    }

    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.responseSerializer = defaultSerializer;
        XNGOAuthToken *requestToken = [[XNGOAuthToken alloc] initWithQueryString:operation.responseString];
        self.requestSerializer.requestToken = requestToken;
        if (success) {
            success(requestToken, operation.responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.responseSerializer = defaultSerializer;
        if (failure) {
            failure(error);
        }
    }];

    [self.operationQueue addOperation:operation];
}

- (void)acquireOAuthRequestTokenWithPath:(NSString *)path
                             callbackURL:(NSURL *)callbackURL
                            accessMethod:(NSString *)accessMethod
                            requestToken:(XNGOAuthToken *)requestToken
                                   scope:(NSString *)scope
                                 success:(void (^)(XNGOAuthToken *requestToken, id responseObject))success
                                 failure:(void (^)(NSError *error))failure {

    if (requestToken.token && requestToken.verifier) {
        AFHTTPResponseSerializer *defaultSerializer = self.responseSerializer;
        self.responseSerializer = [AFHTTPResponseSerializer serializer];

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"oauth_token"]    = requestToken.token;
        parameters[@"oauth_verifier"] = requestToken.verifier;

        NSString *URLString = [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
        NSError *error;
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:accessMethod URLString:URLString parameters:parameters error:&error];

        if (error) {
            failure(error);
            return;
        }

        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            self.responseSerializer = defaultSerializer;
            self.requestSerializer.requestToken = nil;
            XNGOAuthToken *accessToken = [[XNGOAuthToken alloc] initWithQueryString:operation.responseString];
            [self.requestSerializer saveAccessToken:accessToken];
            if (success) {
                success(accessToken, operation.responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            self.responseSerializer = defaultSerializer;
            self.requestSerializer.requestToken = nil;
            if (failure) {
                failure(error);
            }
        }];

        [self.operationQueue addOperation:operation];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:XNGOAuth1ErrorDomain
                                                    code:NSURLErrorBadServerResponse
                                                userInfo:@{NSLocalizedFailureReasonErrorKey:@"Invalid OAuth response received from server."}];
        failure(error);
    }
}

@end
