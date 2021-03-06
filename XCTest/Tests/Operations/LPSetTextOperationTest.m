#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSetTextOperation.h"
#import "LPJSONUtils.h"

@interface LPSetTextOperation (LPXCTEST)

- (NSArray *) arguments;
- (NSString *) stringValueForArgument:(id) argument;

// Corrects type error warnings:  target is supposed to be a UIView
- (id) performWithTarget:(id) target error:(NSError *__autoreleasing *)error;

@end

SpecBegin(LPSetTextOperation)

describe(@"LPSetTextOperation", ^{

  describe(@"#stringValueForArgument:", ^{
    __block id argument;
    __block LPSetTextOperation *operation;

    before(^{
      operation = [[LPSetTextOperation alloc] init];
    });

    it(@"argument is string", ^{
      argument = @"argument";
      expect([operation stringValueForArgument:argument]).to.equal(argument);
    });

    it(@"argument responds to stringValue", ^{
      argument = @(5);
      expect([argument respondsToSelector:@selector(stringValue)]).to.equal(YES);
      expect([operation stringValueForArgument:argument]).to.equal(@"5");
    });

    it(@"argument does not respond to stringValue", ^{
      argument = [UIColor whiteColor];
      expect([argument respondsToSelector:@selector(stringValue)]).to.equal(NO);
      if (lp_ios_version_gte(@"10.0")) {
        expect([operation stringValueForArgument:argument]).to.equal(@"UIExtendedGrayColorSpace 1 1");
      } else {
        expect([operation stringValueForArgument:argument]).to.equal(@"UIDeviceWhiteColorSpace 1 1");
      }
    });
  });

  describe(@"#performWithTarget:error:", ^{

    __block LPSetTextOperation *operation;
    __block NSDictionary *dictionary;

    describe(@"returns nil when invalid arguments", ^{
      __block id target;

      before(^{
        target = [NSObject new];
      });

      it(@"arguments are nil", ^{
        dictionary = @{@"method_name" : @"setText"};
        operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
        id result = [operation performWithTarget:target error:nil];
        expect(result).to.equal(nil);
      });

      it(@"arguments does not have at least 1 value", ^{
        dictionary = @{@"method_name" : @"setText",
                       @"arguments": @[]};
        operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
        id result = [operation performWithTarget:target error:nil];
        expect(result).to.equal(nil);
      });
    });

    describe(@"target represents a WebView; it is a dictionary", ^{
      __block NSDictionary *target;

      before(^{
        dictionary = @{@"method_name" : @"setText",
                       @"arguments": @[@"new text"]};
        operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
      });

      describe(@"representation has invalid keys", ^{

        it(@"is missing webView key", ^{
          target = @{};
          id result = [operation performWithTarget:target error:nil];
          expect(result).to.equal(nil);
        });

        it(@"webView value is not a WebView", ^{
          target = @{@"webView" : [NSObject new]};
          id result = [operation performWithTarget:target error:nil];
          expect(result).to.equal(nil);
        });
      });

      describe(@"representation has valid keys", ^{

        __block UIWebView *webView;

        before(^{
          webView = [[UIWebView alloc] initWithFrame:CGRectZero];
          target = @{@"webView" : webView};
        });

        it(@"returns nil if the WebView cannot be serialized", ^{
          id mock = [OCMockObject niceMockForClass:[LPJSONUtils class]];
          [[[mock stub] andReturn:nil] serializeDictionary:OCMOCK_ANY];
          id result = [operation performWithTarget:target error:nil];
          expect(result).to.equal(nil);
          [mock verify];
        });

        it(@"returns the result of evaluating javascript", ^{
          id result = [operation performWithTarget:target error:nil];
          expect(result).notTo.equal(nil);
        });
      });
    });

    describe(@"target responds to setText", ^{

      __block UITextField *textField;

      before(^{
        textField = [[UITextField alloc] initWithFrame:CGRectZero];
      });

      describe(@"has correct arguments", ^{
        it(@"argument is an NSString", ^{
          dictionary = @{@"method_name" : @"setText",
                         @"arguments": @[@"new text"]};
          operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
          id result = [operation performWithTarget:textField error:nil];
          expect(result).to.equal(textField);
          expect(textField.text).to.equal(@"new text");
        });

        it(@"argument is not an NSString", ^{
          dictionary = @{@"method_name" : @"setText",
                         @"arguments": @[@(5)]};
          operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
          id result = [operation performWithTarget:textField error:nil];
          expect(result).to.equal(textField);
          expect(textField.text).to.equal(@"5");
        });
      });
    });

    it(@"target does not respond to setText", ^{
      dictionary = @{@"method_name" : @"setText",
                     @"arguments": @[@"new text"]};
      operation = [[LPSetTextOperation alloc] init];
      UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
      expect([operation performWithTarget:slider error:nil]).to.equal(nil);
    });
  });
});

SpecEnd
