#import "NSURLRequest+DSL.h"
#import "LSHTTPRequestDSLRepresentation.h"
#import "NSURLRequest+LSHTTPRequest.h"

@implementation NSURLRequest (DSL)
- (NSString *)toNocillaDSL {
    return [[[LSHTTPRequestDSLRepresentation alloc] initWithRequest:self] description];
}
@end
