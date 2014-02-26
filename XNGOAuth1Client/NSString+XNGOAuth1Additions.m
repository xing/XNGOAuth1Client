#import "NSString+XNGOAuth1Additions.h"

@implementation NSString (XNGOAuth1Additions)

- (NSString *)xngo_URLEncode {
    return (__bridge_transfer NSString *)
            CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                    (__bridge CFStringRef)self,
                    NULL,
                    (__bridge CFStringRef)@"!*'\"();:@&=+$,/?%#[] ",
                    kCFStringEncodingUTF8);
}

- (NSString *)xngo_URLDecode {
    return (__bridge_transfer NSString *)
            CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                    (__bridge CFStringRef)self,
                    (__bridge CFStringRef)@"",
                    kCFStringEncodingUTF8);
}

@end
