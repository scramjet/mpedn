#import "MPEdnWriterTests.h"

#import "MPEdnWriter.h"
#import "MPEdn.h"
#import "MPEdnSymbol.h"
#import "MPEdnBase64Codec.h"
#import "MPEdnTaggedValue.h"
#import "MPEdnURLCodec.h"
#import "NSString+MPEdnParser.h"

#define MPAssertSerialisesOK(value, correct)             \
{                                                        \
  MPEdnWriter *writer = [MPEdnWriter new];               \
                                                         \
  NSString *str = [writer serialiseToEdn: value];        \
                                                         \
  XCTAssertEqualObjects (str, correct, @"Serialise");     \
}

#define MPAssertSerialisesAutoKeywordsOK(value, correct) \
{                                                        \
  MPEdnWriter *writer = [MPEdnWriter new];               \
  writer.useKeywordsInMaps = YES;                        \
                                                         \
  NSString *str = [writer serialiseToEdn: value];        \
                                                         \
  XCTAssertEqualObjects (str, correct, @"Serialise");     \
}

@implementation MPEdnWriterTests

- (void) testNumbers
{
  MPAssertSerialisesOK (@1, @"1");
  MPAssertSerialisesOK (@-1, @"-1");
  
  MPAssertSerialisesOK ([NSNumber numberWithShort: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedInt: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithLongLong: 1234], @"1234");
  MPAssertSerialisesOK ([NSNumber numberWithUnsignedLongLong: 1234], @"1234");
  
  MPAssertSerialisesOK ([NSNumber numberWithDouble: 1.1], @"1.100000000000000E+00");
  MPAssertSerialisesOK ([NSNumber numberWithFloat: 1.1], @"1.1000000E+00");
  MPAssertSerialisesOK (@1.1e-5, @"1.100000000000000E-05");
  MPAssertSerialisesOK (@(1.1e-5), @"1.100000000000000E-05");

  {
    int8_t foo = 1;
    MPAssertSerialisesOK (@(foo), @"1");
  }

  {
    uint8_t foo = 1;
    MPAssertSerialisesOK (@(foo), @"1");
  }

  // decimals
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"0"], @"0M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"0.00"], @"0M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"1.2300"], @"1.23M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"123E-2"], @"1.23M");
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"0.123E1"], @"1.23M");
  
  MPAssertSerialisesOK ([NSDecimalNumber decimalNumberWithString: @"5.568E15"], @"5568000000000000M");
  
  // boolean
  MPAssertSerialisesOK (@YES, @"true");
  MPAssertSerialisesOK (@NO, @"false");
  
  // characters
  // NSNumber is pretty broken wrt characters. [NSNumber numberWithChar: 'a']
  // produces a number that is reported as a character, but '\n' doesn't. As
  // as workaround, you can force a single char string to be seen as an EDN character using
  // MPEdnTagAsCharacter. See discussion here:
  // http://www.cocoabuilder.com/archive/cocoa/136956-nsnumber-is-completely-broken.html
  // you might assume this works: it doesn't
  // MPAssertSerialisesOK (@'a', @"\\a");
  MPAssertSerialisesOK (@'a', @"97");

  //  NSLog (@"********** %s", [[NSNumber numberWithChar: '\n'] objCType]);
  //  NSLog (@"********** %@", [[NSNumber numberWithChar: '\n'] class]);
  //  NSLog (@"********** %li", CFNumberGetType ((CFNumberRef)[NSNumber numberWithChar: '\n']));

  // this also does not work
  //  {
  //    NSNumber *newline = [[NSNumber alloc] initWithChar: '\n'];
  //
  //    // BUT the test passes: it seems numberWithChar is fixed
  //    XCTAssertEqual ((char)'c', (char)[newline objCType][0], @"NSNumber numberWithChar");
  //
  //    MPAssertSerialisesOK (newline, @"\\\n");
  //  }
}

- (void) testStrings
{
  MPAssertSerialisesOK (@"", @"\"\"");
  MPAssertSerialisesOK (@"hello", @"\"hello\"");
  MPAssertSerialisesOK (@"a \n in it", @"\"a \\n in it\"");
  MPAssertSerialisesOK (@"a \" in it", @"\"a \\\" in it\"");
  MPAssertSerialisesOK (@"a \" and a \\ in it", @"\"a \\\" and a \\\\ in it\"");
  MPAssertSerialisesOK (@"\\", @"\"\\\\\"");
  MPAssertSerialisesOK (@"\\\"", @"\"\\\\\\\"\"");
  MPAssertSerialisesOK (@"\\ abc", @"\"\\\\ abc\"");
  MPAssertSerialisesOK (@"abc \\", @"\"abc \\\\\"");
  MPAssertSerialisesOK (@"abc \\e", @"\"abc \\\\e\"");
  MPAssertSerialisesOK (@"a\\", @"\"a\\\\\"");
  
  MPAssertSerialisesOK (@"line 1\nline 2", @"\"line 1\\nline 2\"");
  MPAssertSerialisesOK (@"line 1\r\nline 2", @"\"line 1\\r\\nline 2\"");
  
  XCTAssertEqualObjects ([@{@"a" : @1} objectToEdnString], @"{\"a\" 1}", @"Test category");
  XCTAssertEqualObjects ([@{@"a" : @1} objectToEdnStringAutoKeywords], @"{:a 1}", @"Test category");
}

- (void) testCharacters
{
  MPAssertSerialisesOK ([MPEdnCharacter character: 'a'], @"\\a");
  MPAssertSerialisesOK ([MPEdnCharacter character: '+'], @"\\+");
  // INVERTED QUESTION MARK
  MPAssertSerialisesOK ([MPEdnCharacter character: 0x00BF], @"\\¿");

  MPAssertSerialisesOK ([MPEdnCharacter character: '\t'], @"\\tab");
  MPAssertSerialisesOK ([MPEdnCharacter character: '\n'], @"\\newline");
  MPAssertSerialisesOK ([MPEdnCharacter character: '\r'], @"\\return");
}

- (void) testNil
{
  MPAssertSerialisesOK (nil, @"nil");
  MPAssertSerialisesOK ([NSNull null], @"nil");
}

- (void) testMaps
{
  MPAssertSerialisesOK (@{}, @"{}");
  MPAssertSerialisesOK (@{@"a" : @1}, @"{\"a\" 1}");
  MPAssertSerialisesOK (@{[@"a" ednKeyword] : @1}, @"{:a 1}");
  MPAssertSerialisesAutoKeywordsOK (@{@"a" : @1}, @"{:a 1}");
  MPAssertSerialisesOK (@{@"a non keyword" : @1}, @"{\"a non keyword\" 1}");
}

- (void) testLists
{
  MPAssertSerialisesOK (@[], @"[]");
  MPAssertSerialisesOK (@[@1], @"[1]");
  
  {
    NSArray *list = @[@"hello", @1];
    MPAssertSerialisesOK (list, @"[\"hello\",1]");
  }

  // test useSpaceAsSeparator
  {
    MPEdnWriter *writer = [MPEdnWriter new];
    writer.useSpaceAsSeparator = YES;

    NSString *str = [writer serialiseToEdn: @[@1, @2]];

    XCTAssertEqualObjects (str, @"[1 2]", @"Serialise");
  }
}

- (void) testSets
{
  {
    NSSet *set = [NSSet set];
    MPAssertSerialisesOK (set, @"#{}");
  }
  
  {
    NSSet *set = [NSSet setWithArray: @[@1, @"a"]];
    MPAssertSerialisesOK (set, @"#{\"a\",1}");
  }
}

- (void) testSymbols
{
  MPAssertSerialisesOK ([MPEdnSymbol symbolWithName: @"my-symbol"], @"my-symbol");
}

- (void) testKeywords
{
  MPAssertSerialisesOK ([@"abc" ednKeyword], @":abc");
  MPAssertSerialisesOK ([@"abc/def" ednKeyword], @":abc/def");

  {
    NSArray *list = @[[@"abc" ednKeyword], [@"def" ednKeyword]];
    
    MPAssertSerialisesOK (list, @"[:abc,:def]");
  }
  
  // check auto keywords keyword character validity
  MPAssertSerialisesAutoKeywordsOK (@{@"abc" : @1}, @"{:abc 1}");
  MPAssertSerialisesAutoKeywordsOK (@{@":abc" : @1}, @"{\":abc\" 1}");
  MPAssertSerialisesAutoKeywordsOK (@{@"e4faee275bb1740e2001d285a052474300c6921a" : @1}, @"{:e4faee275bb1740e2001d285a052474300c6921a 1}");
}

- (void) testTags
{
  // date
  {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: 63115200];
    
    MPEdnWriter *writer = [MPEdnWriter new];
    
    XCTAssertEqualObjects ([writer serialiseToEdn: date],
                          @"#inst \"1972-01-01T12:00:00.000-00:00\"", @"Serialise");
  }
  
  // UUID
  {
    NSUUID *uuid =
      [[NSUUID alloc] initWithUUIDString: @"F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6"];
    
    MPEdnWriter *writer = [MPEdnWriter new];
    
    XCTAssertEqualObjects ([writer serialiseToEdn: uuid],
                          @"#uuid \"F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6\"", @"Serialise");
  }

  // custom tag (base 64)
  {
    uint8_t data [10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    
    id map = @{[@"a" ednKeyword] : [NSData dataWithBytes: data length: sizeof (data)]};
    
    MPEdnWriter *writer = [MPEdnWriter new];
    [writer addTagWriter: [MPEdnBase64Codec sharedInstance]];
  
    XCTAssertEqualObjects ([writer serialiseToEdn: map], @"{:a #base64 \"AAECAwQFBgcICQ==\"}", @"Serialise");
  }
  
  // unknown tag
  {
    MPEdnWriter *writer = [MPEdnWriter new];
    
    id map = @{[@"a" ednKeyword] : [[MPEdnTaggedValue alloc] initWithTag: @"gutentag" value: @"ja"]};
    
    XCTAssertEqualObjects ([writer serialiseToEdn: map], @"{:a #gutentag \"ja\"}", @"Tag");
  }
}

- (void) testURL
{
  MPEdnWriter *writer = [MPEdnWriter new];
  [writer addTagWriter: [[MPEdnURLCodec alloc] initWithTag: @"test/url"]];

  XCTAssertEqualObjects ([writer serialiseToEdn: @{[@"a" ednKeyword] : [[NSURL alloc] initWithString: @"http://example.com"]}],
                        @"{:a #test/url \"http://example.com\"}", @"Serialise");
}

@end
