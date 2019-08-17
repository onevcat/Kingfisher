#import "LSHTTPRequestDiff.h"

@interface LSHTTPRequestDiff ()
@property (nonatomic, strong) id<LSHTTPRequest>oneRequest;
@property (nonatomic, strong) id<LSHTTPRequest>anotherRequest;

- (BOOL)isMethodDifferent;
- (BOOL)isUrlDifferent;
- (BOOL)areHeadersDifferent;
- (BOOL)isBodyDifferent;

- (void)appendMethodDiff:(NSMutableString *)diff;
- (void)appendUrlDiff:(NSMutableString *)diff;
- (void)appendHeadersDiff:(NSMutableString *)diff;
- (void)appendBodyDiff:(NSMutableString *)diff;
@end

@implementation LSHTTPRequestDiff
- (id)initWithRequest:(id<LSHTTPRequest>)oneRequest andRequest:(id<LSHTTPRequest>)anotherRequest {
    self = [super init];
    if (self) {
        _oneRequest = oneRequest;
        _anotherRequest = anotherRequest;
    }
    return self;
}

- (BOOL)isEmpty {
    if ([self isMethodDifferent] ||
        [self isUrlDifferent] ||
        [self areHeadersDifferent] ||
        [self isBodyDifferent]) {
        return NO;
    }
    return YES;
}

- (NSString *)description {
    NSMutableString *diff = [@"" mutableCopy];
    if ([self isMethodDifferent]) {
        [self appendMethodDiff:diff];
    }
    if ([self isUrlDifferent]) {
        [self appendUrlDiff:diff];
    }
    if([self areHeadersDifferent]) {
        [self appendHeadersDiff:diff];
    }
    if([self isBodyDifferent]) {
        [self appendBodyDiff:diff];
    }
    return [NSString stringWithString:diff];
}

#pragma mark - Private Methods
- (BOOL)isMethodDifferent {
    return ![self.oneRequest.method isEqualToString:self.anotherRequest.method];
}

- (BOOL)isUrlDifferent {
    return ![self.oneRequest.url isEqual:self.anotherRequest.url];
}

- (BOOL)areHeadersDifferent {
    return ![self.oneRequest.headers isEqual:self.anotherRequest.headers];
}

- (BOOL)isBodyDifferent {
    return (((self.oneRequest.body) && (![self.oneRequest.body isEqual:self.anotherRequest.body])) ||
            ((self.anotherRequest.body) && (![self.anotherRequest.body isEqual:self.oneRequest.body])));
}

- (void)appendMethodDiff:(NSMutableString *)diff {
    [diff appendFormat:@"- Method: %@\n+ Method: %@\n", self.oneRequest.method, self.anotherRequest.method];
}

- (void)appendUrlDiff:(NSMutableString *)diff {
    [diff appendFormat:@"- URL: %@\n+ URL: %@\n", [self.oneRequest.url absoluteString], [self.anotherRequest.url absoluteString]];
}

- (void)appendHeadersDiff:(NSMutableString *)diff {
    [diff appendString:@"  Headers:\n"];
    NSSet *headersInOneButNotInTheOther = [self.oneRequest.headers keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![self.anotherRequest.headers objectForKey:key] || ![obj isEqual:[self.anotherRequest.headers objectForKey:key]];
    }];
    NSSet *headersInTheOtherButNotInOne = [self.anotherRequest.headers keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![self.oneRequest.headers objectForKey:key] || ![obj isEqual:[self.oneRequest.headers objectForKey:key]];
    }];
    
    NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"" ascending:YES]];
    NSArray * sortedHeadersInOneButNotInTheOther = [headersInOneButNotInTheOther sortedArrayUsingDescriptors:descriptors];
    NSArray * sortedHeadersInTheOtherButNotInOne = [headersInTheOtherButNotInOne sortedArrayUsingDescriptors:descriptors];
    for (NSString *header in sortedHeadersInOneButNotInTheOther) {
        NSString *value = [self.oneRequest.headers objectForKey:header];
        [diff appendFormat:@"-\t\"%@\": \"%@\"\n", header, value];
        
    }
    for (NSString *header in sortedHeadersInTheOtherButNotInOne) {
        NSString *value = [self.anotherRequest.headers objectForKey:header];
        [diff appendFormat:@"+\t\"%@\": \"%@\"\n", header, value];
    }
}

- (void)appendBodyDiff:(NSMutableString *)diff {
    NSString *oneBody = [[NSString alloc] initWithData:self.oneRequest.body encoding:NSUTF8StringEncoding];
    if (oneBody.length) {
        [diff appendFormat:@"- Body: \"%@\"\n", oneBody];
    }
    NSString *anotherBody = [[NSString alloc] initWithData:self.anotherRequest.body encoding:NSUTF8StringEncoding];
    if (anotherBody.length) {
        [diff appendFormat:@"+ Body: \"%@\"\n", anotherBody];
    }
}
@end
