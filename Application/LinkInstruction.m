#import "LinkInstruction.h"

#import "NSString+CrashReporter.h"
#import "Package.h"

@interface Instruction (Private)
@property(nonatomic, copy) NSString *title;
@end

@implementation LinkInstruction

@synthesize recipients = recipients_;
@synthesize unlocalizedTitle = unlocalizedTitle_;
@synthesize url = url_;
@synthesize isEmail = isEmail_;
@synthesize isSupport = isSupport_;

+ (NSArray *)linkInstructionsForPackage:(Package *)package {
    NSMutableArray *result = [NSMutableArray array];

    if (package != nil) {
        if (package.isAppStore) {
            // Add AppStore link.
            long long item = [package.storeIdentifier longLongValue]; // we need long long here because there are 2 billion apps on AppStore already... :)
            NSString *line = [NSString stringWithFormat:@"link url \"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%lld&mt=8\" as \"View package in AppStore\"", item];
            LinkInstruction *instruction = [self instructionWithLine:line];
            if (instruction != nil) {
                [result addObject:instruction];
            }
        } else {
            // Add email link.
            NSString *author = package.author;
            if (author != nil) {
                NSRange leftAngleRange = [author rangeOfString:@"<" options:NSBackwardsSearch];
                if (leftAngleRange.location != NSNotFound) {
                    NSRange rightAngleRange = [author rangeOfString:@">" options:NSBackwardsSearch];
                    if (rightAngleRange.location != NSNotFound) {
                        if (leftAngleRange.location < rightAngleRange.location) {
                            NSRange range = NSMakeRange(leftAngleRange.location + 1, rightAngleRange.location - leftAngleRange.location - 1);
                            NSString *emailAddress = [author substringWithRange:range];
                            NSString *line = [NSString stringWithFormat:@"link email %@ as \"Contact author\" is_support yes", emailAddress];
                            LinkInstruction *instruction = [self instructionWithLine:line];
                            if (instruction != nil) {
                                [result addObject:instruction];
                            }
                        }
                    }
                }
            }

            // Add Cydia link.
            NSString *line = [NSString stringWithFormat:@"link url \"cydia://package/%@\" as \"View package in Cydia\"", package.storeIdentifier];
            LinkInstruction *instruction = [self instructionWithLine:line];
            if (instruction != nil) {
                [result addObject:instruction];
            }
        }

        // Add other (optional) link commands.
        for (NSString *line in package.config) {
            if ([line hasPrefix:@"link"]) {
                LinkInstruction *instruction = [self instructionWithLine:line];
                if (instruction != nil) {
                    [result addObject:instruction];
                }
            }
        }
    }

    return result;
}

// NOTE: Format is:
//
//       link [as "<title>"] [is_support <yes/no>] url <URL>
//       link [as "<title>"] [is_support <yes/no>] email <comma-separated email addresses>
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
                    unlocalizedTitle_ = [[token stripQuotes] retain];
                    mode = ModeAttribute;
                    break;
                case ModeURL:
                    url_ = [[NSURL alloc] initWithString:[token stripQuotes]];
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