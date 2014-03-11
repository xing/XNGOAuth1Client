#import "XNGOAuth1RequestSerializer.h"
#import "XNGOAuthToken.h"
#import "XNGOAuth1RequestSerializer_Private.h"

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

- (XNGOAuthToken *)accessToken {
    NSMutableDictionary *dictionary = [self.keychainDictionary mutableCopy];
    dictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    dictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, (CFTypeRef *)&result);
    NSData *data = (__bridge_transfer NSData *)result;

    if (status == noErr && data) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        return nil;
    }
}

- (BOOL)saveAccessToken:(XNGOAuthToken *)oauthToken {
    NSMutableDictionary *dictionary = [self.keychainDictionary mutableCopy];

    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oauthToken];
    updateDictionary[(__bridge id)kSecValueData] = data;

    OSStatus status;
    if ([self accessToken]) {
        status = SecItemUpdate((__bridge CFDictionaryRef)dictionary, (__bridge CFDictionaryRef)updateDictionary);
    } else {
        [dictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    }

    return status == noErr;
}

- (BOOL)removeAccessToken {
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)self.keychainDictionary);
    return status == noErr;
}

#pragma mark - Helper

- (NSDictionary *)keychainDictionary {
    return @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService:self.service};
}

@end
