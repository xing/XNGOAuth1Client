#import <Foundation/Foundation.h>

@interface XNGOAuthToken : NSObject

@property (readwrite, nonatomic, copy) NSString *key;
@property (readwrite, nonatomic, copy) NSString *secret;
@property (readwrite, nonatomic, copy) NSString *session;
@property (readwrite, nonatomic, strong) NSDate *expiration;
@property (nonatomic, copy) NSString *verifier;
@property (readwrite, nonatomic, assign, getter = canBeRenewed) BOOL renewable;
@property (readonly, nonatomic, assign, getter = isExpired) BOOL expired;
@property (nonatomic, strong) NSDictionary *userInfo;

- (id)initWithQueryString:(NSString *)queryString;
- (id)initWithKey:(NSString *)key
           secret:(NSString *)secret
          session:(NSString *)session
       expiration:(NSDate *)expiration
        renewable:(BOOL)canBeRenewed;
+ (NSDictionary *)parametersFromQueryString:(NSString *)queryString;

#ifdef _SECURITY_SECITEM_H_
///---------------------
/// @name Authenticating
///---------------------

/**
Stores the specified OAuth token for a given web service identifier in the Keychain
with the default Keychain Accessibility of kSecAttrAccessibleWhenUnlocked.

@param token The OAuth credential to be stored.
@param identifier The service identifier associated with the specified token.

@return Whether or not the credential was stored in the keychain.
*/
+ (BOOL)storeCredential:(XNGOAuthToken *)credential
         withIdentifier:(NSString *)identifier;

/**
Stores the specified OAuth token for a given web service identifier in the Keychain.

@param token The OAuth credential to be stored.
@param identifier The service identifier associated with the specified token.
@param securityAccessibility The Keychain security accessibility to store the credential with.

@return Whether or not the credential was stored in the keychain.
*/
+ (BOOL)storeCredential:(XNGOAuthToken *)credential
         withIdentifier:(NSString *)identifier
      withAccessibility:(id)securityAccessibility;

/**
Retrieves the OAuth credential stored with the specified service identifier from the Keychain.

@param identifier The service identifier associated with the specified credential.

@return The retrieved OAuth token.
*/
+ (XNGOAuthToken *)retrieveCredentialWithIdentifier:(NSString *)identifier;

/**
Deletes the OAuth token stored with the specified service identifier from the Keychain.

@param identifier The service identifier associated with the specified token.

@return Whether or not the token was deleted from the keychain.
*/
+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;

#endif

@end
