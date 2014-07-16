#import "LinkReporterLine.h"

#import "Package.h"

@interface ReporterLine (Private)
@property(nonatomic, copy) NSString *title;
@end

@implementation LinkReporterLine

@synthesize recipients = recipients_;
@synthesize unlocalizedTitle = unlocalizedTitle_;
@synthesize url = url_;
@synthesize isEmail = isEmail_;
@synthesize isSupport = isSupport_;

+ (NSArray *)linkReportersForPackage:(Package *)package {
    NSMutableArray *result = [NSMutableArray array];

    if (package != nil) {
        if (package.isAppStore) {
            // Add AppStore link.
            long long item = [package.storeIdentifier longLongValue]; // we need long long here because there are 2 billion apps on AppStore already... :)
            NSString *line = [NSString stringWithFormat:@"link url \"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%lld&mt=8\" as \"View package in AppStore\"", item];
            LinkReporterLine *reporter = [self reporterWithLine:line];
            if (reporter != nil) {
                [result addObject:reporter];
            }
        } else {
            // Add email link.
            NSString *author = package.author;
            if (author != nil) {
                NSString *line = [NSString stringWithFormat:@"link email \"%@\" as \"Email author\" is_support yes", author];
                LinkReporterLine *reporter = [self reporterWithLine:line];
                if (reporter != nil) {
                    [result addObject:reporter];
                }
            }

            // Add Cydia link.
            NSString *line = [NSString stringWithFormat:@"link url \"cydia://package/%@\" as \"View package in Cydia\"", package.storeIdentifier];
            LinkReporterLine *reporter = [self reporterWithLine:line];
            if (reporter != nil) {
                [result addObject:reporter];
            }
        }

        // Add other (optional) link commands.
        for (NSString *line in package.config) {
            if ([line hasPrefix:@"link"]) {
                LinkReporterLine *reporter = [self reporterWithLine:line];
                if (reporter != nil) {
                    [result addObject:reporter];
                }
            }
        }
    }

    return result;
}

// NOTE: Format is:
//
//       link [as "<title>"] url <URL>
//       link [as "<title>"] email <comma-separated email addresses>
//
- (instancetype)initWithTokens:(NSArray *)tokens {
    self = [super initWithTokens:tokens];
    if (self != nil) {
        enum {
            ModeAttribute,
            ModeRecipients,
            ModeSupport,
            ModeTitle,
            ModeURL
        } mode = ModeAttribute;

        for (NSString *token in tokens) {
            switch (mode) {
                case ModeAttribute:
                    if ([token isEqualToString:@"as"]) {
                        mode = ModeTitle;
                    } else if ([token isEqualToString:@"email"]) {
                        mode = ModeRecipients;
                    } else if ([token isEqualToString:@"is_support"]) {
                        mode = ModeSupport;
                    } else if ([token isEqualToString:@"url"]) {
                        mode = ModeURL;
                    }
                    break;
                case ModeRecipients:
                    isEmail_ = YES;
                    recipients_ = [token retain];
                    mode = ModeAttribute;
                    break;
                case ModeSupport:
                    isSupport_ = [[token lowercaseString] isEqualToString:@"yes"];
                    mode = ModeAttribute;
                    break;
                case ModeTitle:
                    unlocalizedTitle_ = [token retain];
                    mode = ModeAttribute;
                    break;
                case ModeURL:
                    url_ = [[NSURL alloc] initWithString:token];
                    mode = ModeAttribute;
                    break;
                default:
                    break;
            }
        }

        if (unlocalizedTitle_ == nil) {
            unlocalizedTitle_ = [(isEmail_ ? recipients_ : [url_ absoluteString]) copy];
        }
        [self setTitle:[[NSBundle mainBundle] localizedStringForKey:unlocalizedTitle_ value:nil table:nil]];
    }
    return self;
}

- (void)dealloc {
    [recipients_ release];
    [unlocalizedTitle_ release];
    [url_ release];
    [super dealloc];
}

@end

/* vim: set ft=objc ff=unix sw=4 ts=4 tw=80 expandtab: */
