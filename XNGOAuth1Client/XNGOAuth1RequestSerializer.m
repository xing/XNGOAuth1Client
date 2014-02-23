#import "XNGOAuth1RequestSerializer.h"

@interface XNGOAuth1RequestSerializer ()

@property (nonatomic) NSString *service;
@property (nonatomic) NSString *consumerKey;
@property (nonatomic) NSString *consumerSecret;

@end

@implementation XNGOAuth1RequestSerializer

- (id)initWithService:(NSString *)service consumerKey:(NSString *)consumerKey secret:(NSString *)consumerSecret {
    self = [super init];

    if (self) {
        _service = service;
        _consumerKey = consumerKey;
        _consumerSecret = consumerSecret;
    }

    return self;
}

@end
