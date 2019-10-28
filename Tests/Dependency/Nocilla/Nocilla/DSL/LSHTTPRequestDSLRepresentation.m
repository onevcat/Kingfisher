#import "LSHTTPRequestDSLRepresentation.h"

@interface LSHTTPRequestDSLRepresentation ()
@property (nonatomic, strong) id<LSHTTPRequest> request;
@end

@implementation LSHTTPRequestDSLRepresentation
- (id)initWithRequest:(id<LSHTTPRequest>)request {
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"stubRequest(@\"%@\", @\"%@\")", self.request.method, [self.request.url absoluteString]];
    if (self.request.headers.count) {
        [result appendString:@".\nwithHeaders(@{ "];
        NSMutableArray *headerElements = [NSMutableArray arrayWithCapacity:self.request.headers.count];
        
        NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES]];
        NSArray * sortedHeaders = [[self.request.headers allKeys] sortedArrayUsingDescriptors:descriptors];
        
        for (NSString * header in sortedHeaders) {
            NSString *value = [self.request.headers objectForKey:header];
            [headerElements addObject:[NSString stringWithFormat:@"@\"%@\": @\"%@\"", header, value]];
        }
        [result appendString:[headerElements componentsJoinedByString:@", "]];
        [result appendString:@" })"];
    }
    if (self.request.body.length) {
        NSString *escapedBody = [[NSString alloc] initWithData:self.request.body encoding:NSUTF8StringEncoding];
        escapedBody = [escapedBody stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        [result appendFormat:@".\nwithBody(@\"%@\")", escapedBody];
    }
    return [NSString stringWithFormat:@"%@;", result];
}
@end
