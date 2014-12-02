//
// Copyright (c) 2014 XING AG (http://xing.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "XNGOAuthToken.h"

@implementation XNGOAuthToken

+ (NSDictionary *)parametersFromQueryString:(NSString *)queryString {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (queryString) {
        NSScanner *parameterScanner = [[NSScanner alloc] initWithString:queryString];
        NSString *name = nil;
        NSString *value = nil;

        while (![parameterScanner isAtEnd]) {
            name = nil;
            [parameterScanner scanUpToString:@"=" intoString:&name];
            [parameterScanner scanString:@"=" intoString:NULL];

            value = nil;
            [parameterScanner scanUpToString:@"&" intoString:&value];
            [parameterScanner scanString:@"&" intoString:NULL];

            if (name && value) {
                parameters[[name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
        }
    }

    return parameters;
}

static inline BOOL AFQueryStringValueIsTrue(NSString *value) {
    return value && [[value lowercaseString] hasPrefix:@"t"];
}

NSString *const kAFOAuth1CredentialServiceName = @"AFOAuthCredentialService";

static NSDictionary *AFKeychainQueryDictionaryWithIdentifier(NSString *identifier) {
    return @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrAccount: identifier,
             (__bridge id)kSecAttrService: kAFOAuth1CredentialServiceName};
}

- (id)initWithQueryString:(NSString *)queryString {
    if (!queryString || [queryString length] == 0) {
        return nil;
    }

    NSDictionary *attributes = [self.class parametersFromQueryString:queryString];

    if ([attributes count] == 0) {
        return nil;
    }

    NSString *key = attributes[@"oauth_token"];
    NSString *secret = attributes[@"oauth_token_secret"];
    NSString *session = attributes[@"oauth_session_handle"];

    NSDate *expiration = nil;
    if (attributes[@"oauth_token_duration"]) {
        expiration = [NSDate dateWithTimeIntervalSinceNow:[attributes[@"oauth_token_duration"] doubleValue]];
    }

    BOOL canBeRenewed = NO;
    if (attributes[@"oauth_token_renewable"]) {
        canBeRenewed = AFQueryStringValueIsTrue(attributes[@"oauth_token_renewable"]);
    }

    self = [self initWithKey:key secret:secret session:session expiration:expiration renewable:canBeRenewed];
    if (!self) {
        return nil;
    }

    NSMutableDictionary *mutableUserInfo = [attributes mutableCopy];
    [mutableUserInfo removeObjectsForKeys:@[@"oauth_token", @"oauth_token_secret", @"oauth_session_handle", @"oauth_token_duration", @"oauth_token_renewable"]];

    if ([mutableUserInfo count] > 0) {
        self.userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
    }

    return self;
}

- (id)initWithKey:(NSString *)key
           secret:(NSString *)secret
          session:(NSString *)session
       expiration:(NSDate *)expiration
        renewable:(BOOL)canBeRenewed {
    NSParameterAssert(key);
    NSParameterAssert(secret);

    self = [super init];
    if (!self) {
        return nil;
    }

    self.key = key;
    self.secret = secret;
    self.session = session;
    self.expiration = expiration;
    self.renewable = canBeRenewed;

    return self;
}

- (BOOL)isExpired {
    return [self.expiration compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark -

+ (XNGOAuthToken *)retrieveCredentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *mutableQueryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];
    mutableQueryDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    mutableQueryDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)mutableQueryDictionary, (CFTypeRef *)&result);

    if (status != errSecSuccess) {
        NSLog(@"Unable to fetch credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
        return nil;
    }

    NSData *data = (__bridge_transfer NSData *)result;
    XNGOAuthToken *credential = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    return credential;
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *mutableQueryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)mutableQueryDictionary);

    if (status != errSecSuccess) {
        NSLog(@"Unable to delete credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
    }

    return (status == errSecSuccess);
}

+ (BOOL)storeCredential:(XNGOAuthToken *)credential
         withIdentifier:(NSString *)identifier {
    id securityAccessibility = nil;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 43000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    securityAccessibility = (__bridge id)kSecAttrAccessibleWhenUnlocked;
#endif

    return [[self class] storeCredential:credential withIdentifier:identifier withAccessibility:securityAccessibility];
}

+ (BOOL)storeCredential:(XNGOAuthToken *)credential
         withIdentifier:(NSString *)identifier
      withAccessibility:(id)securityAccessibility {
    NSMutableDictionary *mutableQueryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];

    if (!credential) {
        return [self deleteCredentialWithIdentifier:identifier];
    }

    NSMutableDictionary *mutableUpdateDictionary = [NSMutableDictionary dictionary];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credential];
    mutableUpdateDictionary[(__bridge id)kSecValueData] = data;
    if (securityAccessibility) {
        mutableUpdateDictionary[(__bridge id)kSecAttrAccessible] = securityAccessibility;
    }

    OSStatus status;
    BOOL exists = [self retrieveCredentialWithIdentifier:identifier] != nil;

    if (exists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)mutableQueryDictionary, (__bridge CFDictionaryRef)mutableUpdateDictionary);
    } else {
        [mutableQueryDictionary addEntriesFromDictionary:mutableUpdateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)mutableQueryDictionary, NULL);
    }

    if (status != errSecSuccess) {
        NSLog(@"Unable to %@ credential with identifier \"%@\" (Error %li)", exists ? @"update" : @"add", identifier, (long int)status);
    }

    return (status == errSecSuccess);
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.key = [decoder decodeObjectForKey:NSStringFromSelector(@selector(key))];
    self.secret = [decoder decodeObjectForKey:NSStringFromSelector(@selector(secret))];
    self.session = [decoder decodeObjectForKey:NSStringFromSelector(@selector(session))];
    self.verifier = [decoder decodeObjectForKey:NSStringFromSelector(@selector(verifier))];
    self.expiration = [decoder decodeObjectForKey:NSStringFromSelector(@selector(expiration))];
    self.renewable = [decoder decodeBoolForKey:NSStringFromSelector(@selector(canBeRenewed))];
    self.userInfo = [decoder decodeObjectForKey:NSStringFromSelector(@selector(userInfo))];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.key forKey:NSStringFromSelector(@selector(key))];
    [coder encodeObject:self.secret forKey:NSStringFromSelector(@selector(secret))];
    [coder encodeObject:self.session forKey:NSStringFromSelector(@selector(session))];
    [coder encodeObject:self.verifier forKey:NSStringFromSelector(@selector(verifier))];
    [coder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
    [coder encodeBool:self.renewable forKey:NSStringFromSelector(@selector(canBeRenewed))];
    [coder encodeObject:self.userInfo forKey:NSStringFromSelector(@selector(userInfo))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    XNGOAuthToken *copy = (XNGOAuthToken *)[[[self class] allocWithZone:zone] init];
    copy.key = self.key;
    copy.secret = self.secret;
    copy.session = self.session;
    copy.verifier = self.verifier;
    copy.expiration = self.expiration;
    copy.renewable = self.renewable;
    copy.userInfo = self.userInfo;

    return copy;
}

@end