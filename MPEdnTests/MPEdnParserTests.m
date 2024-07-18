#import "MPEdnParserTests.h"

#import "MPEdn.h"
#import "MPEdnParser.h"
#import "MPEdnSymbol.h"
#import "MPEdnBase64Codec.h"
#import "MPEdnTaggedValue.h"
#import "MPEdnURLCodec.h"

#define MPAssertParseOK(expr, correctValue, message)    \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  XCTAssertEqualObjects (value, correctValue, message);         \
  XCTAssertNil (parser.error, message);     \
  XCTAssertTrue (parser.complete, message); \
}

#define MPAssertParseError(expr, message)  \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  XCTAssertNil (value, message);            \
  XCTAssertNotNil (parser.error, message);  \
  XCTAssertTrue (parser.complete, message); \
  NSLog (@"Error: %@", parser.error);      \
}

@implementation MPEdnParserTests

- (void) testNumbers
{
  // int
  MPAssertParseOK (@"1", @1, @"Integer");
  MPAssertParseOK (@"+1", @1, @"Integer");
  MPAssertParseOK (@"-1", @-1, @"Integer");
  MPAssertParseOK (@" 1 ", @1, @"Integer (whitespace)");
  
  // double
  MPAssertParseOK (@"1.2", @1.2, @"Float");
  MPAssertParseOK (@"1.2e4", @1.2e4, @"Float");
  MPAssertParseOK (@"-42.2e-2", @-42.2e-2, @"Float");
  MPAssertParseOK (@".2", @.2, @"Float");

  // decimal
  MPAssertParseOK (@"1.0M", [NSDecimalNumber decimalNumberWithString: @"1.0"], @"Decimal");
  MPAssertParseOK (@"3.14159M", [NSDecimalNumber decimalNumberWithString: @"3.14159"], @"Decimal");
  MPAssertParseOK (@"42.221E10M", [NSDecimalNumber decimalNumberWithString: @"42.221E10M"], @"Decimal");
  MPAssertParseOK (@"1234E-3M", [NSDecimalNumber decimalNumberWithString: @"1234E-3M"], @"Decimal");
  
  // does not allow N (not implemented)
  MPAssertParseError (@"1.0N", @"Float");

  // errors
  MPAssertParseError (@"1.", @"Float");
  MPAssertParseError (@"1e", @"Float");
  
  // do not allow more than one value for parseString
  MPAssertParseError (@"1 1", @"More than one value");
}

- (void) testWhitespaceAndComments
{
  MPAssertParseOK (@"\t 1", @1, @"Tabs and space");
  MPAssertParseOK (@"\n 1", @1, @"Newlines and space");
  MPAssertParseOK (@"\r\n 1", @1, @"Newlines and space");
  MPAssertParseOK (@",1,", @1, @"Commas");
  MPAssertParseOK (@" ; comment\n 1", @1, @"Comment and space");
  
  // errors
  MPAssertParseError (@"; comment", @"Comment with no value");
}

- (void) testMultipleValues
{
  MPEdnParser *parser = [MPEdnParser new];
  
  parser.inputString = @"1 2 ";
  
  id value1 = [parser parseNextValue];
  id value2 = [parser parseNextValue];
  
  XCTAssertEqualObjects (value1, @1, @"Value 1");
  XCTAssertEqualObjects (value2, @2, @"Value 2");
  XCTAssertTrue (parser.complete, @"Complete");
}

- (void) testStrings
{
  MPAssertParseOK (@"\"\"", @"", @"String");
  MPAssertParseOK (@"\"hello\"", @"hello", @"String");
  MPAssertParseOK (@"\"hello\\t\\\"there\\\"\"", @"hello\t\"there\"", @"String with escapes");
  MPAssertParseOK (@"\"\\\"\"", @"\"", @"String");
  
  // unicode (UTF-16)
  NSString *smiley = [NSString stringWithUTF8String: "hello \xF0\x9F\x98\x84 smiley"];
  NSString *str = [NSString stringWithFormat: @"\"%@\"", smiley];
  MPAssertParseOK (str, smiley, @"String with Unicode");
  
  // errors
  MPAssertParseError (@"\"hello", @"Unterminated string");
  MPAssertParseError (@"\"\\a\"", @"Invalid escape");
  MPAssertParseError (@"\"\\\"", @"Invalid escape");
}

- (void) testSymbols
{
  MPAssertParseOK (@"a", [MPEdnSymbol symbolWithName: @"a"], @"Symbol");
  MPAssertParseOK (@"abc/de:fg", [MPEdnSymbol symbolWithName: @"abc/de:fg"], @"Symbol");
  MPAssertParseOK (@"+abc", [MPEdnSymbol symbolWithName: @"+abc"], @"Symbol");
  MPAssertParseOK (@".abc", [MPEdnSymbol symbolWithName: @".abc"], @"Symbol");
  
  MPAssertParseOK (@"true", @YES, @"Boolean");
  MPAssertParseOK (@"false", @NO, @"Boolean");
  
  MPAssertParseOK (@"nil", [NSNull null], @"Nil");
  
  MPAssertParseOK (@"+", [MPEdnSymbol symbolWithName: @"+"], @"Symbol");
  MPAssertParseOK (@"+-", [MPEdnSymbol symbolWithName: @"+-"], @"Symbol");
  MPAssertParseOK (@"[+]", @[[MPEdnSymbol symbolWithName: @"+"]], @"Symbol");
  MPAssertParseOK (@"[-]", @[[MPEdnSymbol symbolWithName: @"-"]], @"Symbol");
  MPAssertParseOK (@"[.]", @[[MPEdnSymbol symbolWithName: @"."]], @"Symbol");
  MPAssertParseOK (@"[+a]", @[[MPEdnSymbol symbolWithName: @"+a"]], @"Symbol");
  MPAssertParseOK (@"-", [MPEdnSymbol symbolWithName: @"-"], @"Symbol");
  MPAssertParseOK (@"<", [MPEdnSymbol symbolWithName: @"<"], @"Symbol");
  MPAssertParseOK (@"<:>", [MPEdnSymbol symbolWithName: @"<:>"], @"Symbol");
  MPAssertParseOK (@"+a", [MPEdnSymbol symbolWithName: @"+a"], @"Symbol");
  MPAssertParseOK (@"?", [MPEdnSymbol symbolWithName: @"?"], @"Symbol");
  MPAssertParseOK (@"?a", [MPEdnSymbol symbolWithName: @"?a"], @"Symbol");
  MPAssertParseOK (@"a?", [MPEdnSymbol symbolWithName: @"a?"], @"Symbol");
  MPAssertParseOK (@"/a", [MPEdnSymbol symbolWithName: @"/a"], @"Symbol");

  MPAssertParseError (@"}", @"Not a symbol");
  MPAssertParseError (@"]", @"Not a symbol");
  MPAssertParseError (@")", @"Not a symbol");
  MPAssertParseError (@"@", @"Not a symbol");
}

/*
 * ' (quote) is not in the EDN spec, and doesn't make any sense outside of an evaluated environment
 * and yet:
 *
 *   user> (pr-str (clojure.edn/read-string "'a"))
 *   "'a"
 *
 * Since Clojure can generate EDN like this, we also accept it (but do not generate it).
 */
- (void) testQuote
{
  MPAssertParseOK (@"'", [MPEdnSymbol symbolWithName: @"'"], @"Quote");
  MPAssertParseOK (@"''", [MPEdnSymbol symbolWithName: @"''"], @"Quote");
  MPAssertParseOK (@"'a", [MPEdnSymbol symbolWithName: @"'a"], @"Quote");
  MPAssertParseOK (@"'.1", [MPEdnSymbol symbolWithName: @"'.1"], @"Quote");
  MPAssertParseOK (@"'a/a", [MPEdnSymbol symbolWithName: @"'a/a"], @"Quote");

  // this should be an error according to clojure.edn, but no idea why. since we would need a special
  // logic path for this edge case, leaving for now
  // MPAssertParseError (@"'/", @"Quote");
}

- (void) testKeywords
{
  MPAssertParseOK (@":a", [@"a" ednKeyword], @"Keyword");
  MPAssertParseOK (@":abc", [@"abc" ednKeyword], @"Keyword");
  MPAssertParseOK (@":abc.def/ghi", [@"abc.def/ghi" ednKeyword], @"Keyword");
  
  MPAssertParseError (@":", @"Keyword");
  
  // keyword accessed after parsing
  XCTAssertTrue ([@":a" ednStringToObject] == [@"a" ednKeyword], @"Equal keyword");
  
  // keyword accessed before parsing
  MPEdnKeyword *kwdB = [@"b" ednKeyword];
  XCTAssertTrue ([@":b" ednStringToObject] == kwdB, @"Equal keyword");
  
  // keywords as strings
  XCTAssertEqualObjects ([@":b" ednStringToObjectNoKeywords], @"b", @"Equal keyword");

  // test comparison uses namespace like Clojure does (this test doesn't really belong here...)
  XCTAssert ([[@"z" ednKeyword] compare: [@"a/a" ednKeyword]] < 0, @"Compare using ns");
  XCTAssert ([[@"a/z" ednKeyword] compare: [@"z/a" ednKeyword]] < 0, @"Compare using ns");
}

- (void) testSets
{
  MPAssertParseOK (@"#{}", [NSSet set], @"Empty set");
  MPAssertParseOK (@"#{1}", [NSSet setWithArray: @[@1]], @"Set");
  {
    id items = [NSSet setWithArray: @[@1, @2, @3]];
    MPAssertParseOK (@"#{1, 2, 3}", items, @"Set");
  }
  {
    id items = [NSSet setWithArray: @[@1, @"abc", [@"def" ednKeyword]]];
    MPAssertParseOK (@"#{1, \"abc\", :def}", items, @"Set");
  }
  
  // errors
  MPAssertParseError (@"#{", @"Set");
  MPAssertParseError (@"#{}}", @"Set");
}

- (void) testMaps
{
  MPAssertParseOK (@"{}", [NSDictionary dictionary], @"Empty map");
  {
    id map = @{[@"a" ednKeyword] : @1};
    MPAssertParseOK (@"{:a, 1}", map, @"Map");
  }
  {
    id map = @{[@"a" ednKeyword] : @1, @"b" : [@"c" ednKeyword]};
    MPAssertParseOK (@"{:a 1, \"b\" :c}", map, @"Map");
  }
 
  // errors
  MPAssertParseError (@"{", @"Map");
  MPAssertParseError (@"{}}", @"Map");
}

- (void) testLists
{
  MPAssertParseOK (@"[]", @[], @"Empty list");
  {
    id list = @[[@"a" ednKeyword], @1];
    MPAssertParseOK (@"[:a, 1]", list, @"List");
    MPAssertParseOK (@"(:a 1)", list, @"List");
    MPAssertParseOK (@"(:a,,,, 1)", list, @"List");
    MPAssertParseOK (@"(:a 1)", list, @"List");
  }
  
  {
    id list = @[@{[@"a" ednKeyword] : @1}, @2];
    MPAssertParseOK (@"[{:a 1}, 2]", list, @"List");
  }
  
  // errors
  MPAssertParseError (@"[", @"List");
  MPAssertParseError (@"(", @"List");
  MPAssertParseError (@"(]", @"List");
  MPAssertParseError (@"(:a, :b]", @"List");
  MPAssertParseError (@"[]]", @"List");
}

- (void) testDiscard
{
  MPAssertParseOK (@"#_ 1 2", @2, @"Discard");
  MPAssertParseOK (@"#_1 2", @2, @"Discard");
  MPAssertParseOK (@"#_[1 2 3] 2", @2, @"Discard");
  
  MPAssertParseError (@"#_", @"Discard");
  MPAssertParseError (@"#_ \"", @"Discard");
  MPAssertParseError (@"#_ 1 \"", @"Discard");
}

- (void) testCharacters
{
  MPAssertParseOK (@"\\a", [MPEdnCharacter character: 'a'], @"Character");
  MPAssertParseOK (@"\\ ", [MPEdnCharacter character: ' '], @"Character");
  MPAssertParseOK (@"\\newline", [MPEdnCharacter character: '\n'], @"Character");
  MPAssertParseOK (@"\\tab", [MPEdnCharacter character: '\t'], @"Character");
  MPAssertParseOK (@"\\return", [MPEdnCharacter character: '\r'], @"Character");
  MPAssertParseOK (@"\\space", [MPEdnCharacter character: ' '], @"Character");

  MPAssertParseError (@"\\", @"Character");
  MPAssertParseError (@"\\hello", @"Character");
}

- (void) testTaggedValues
{
  MPAssertParseError (@"#", @"Tag");
  MPAssertParseError (@"# {", @"Tag");
  MPAssertParseError (@"# #", @"Tag");
  MPAssertParseError (@"#tag #tag {}", @"Tag");
  
  // date
  {
    NSDate *correctDate = [NSDate dateWithTimeIntervalSince1970: 63115200];

    MPAssertParseOK (@"#inst \"1972-01-01T12:00:00.00-00:00\"", correctDate, @"Date");
    MPAssertParseOK (@"#inst \"1972-01-01T22:30:00.00+10:30\"", correctDate, @"Date");
    MPAssertParseOK (@"#inst \"1972-01-01T12:00:00.000Z\"", correctDate, @"Date");
    MPAssertParseOK (@"#inst \"1972-01-01T12:00:00.000\"", correctDate, @"Date");
  }

  // UUID
  {
    NSUUID *uuid =
      [[NSUUID alloc] initWithUUIDString: @"F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6"];
    
    MPAssertParseOK (@"#uuid \"F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6\"", uuid, @"UUID");
  }

  // check custom tag reader
  {
    MPEdnParser *parser = [MPEdnParser new];

    [parser addTagReader: [MPEdnBase64Codec sharedInstance]];
    
    {
      id map = [parser parseString: @"{:a #base64 \"AAECAwQFBgcICQ==\"}"];
      
      uint8_t dataContents [10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
      
      NSData *data = [NSData dataWithBytes: dataContents length: sizeof (dataContents)];

      XCTAssertTrue ([map [[@"a" ednKeyword]] isKindOfClass: [NSData class]], @"Data decoded");
      XCTAssertEqualObjects ([map objectForKey: [@"a" ednKeyword]], data, @"Data decoded");
    }
    
    // check Base 64 error reporting
    [parser parseString: @"#base64 {}"];
    
    XCTAssertTrue (parser.error != nil, @"Base 64 needs a string value");
    
    [parser parseString: @"#base64 \"<hello!>\""];
    
    XCTAssertTrue (parser.error != nil, @"Bad Base64 data");
    
    // check allowUnknownTags
    MPEdnTaggedValue *taggedMap = [parser parseString: @"#non-existent-tag {}"];
    
    XCTAssertTrue ([taggedMap isKindOfClass: [MPEdnTaggedValue class]], @"Tagged");
    XCTAssertEqualObjects (taggedMap.tag, @"non-existent-tag", @"Tagged");
    XCTAssertEqualObjects (taggedMap.value, @{}, @"Tagged");
    
    parser.allowUnknownTags = NO;
    
    [parser parseString: @"#non-existent-tag {}"];
    XCTAssertNotNil (parser.error, @"Tagged");
  }
}

- (void) testURLReader
{
  MPEdnParser *parser = [MPEdnParser new];

  [parser addTagReader: [[MPEdnURLCodec alloc] initWithTag: @"test/url"]];

  {
    id map = [parser parseString: @"{:a #test/url \"http://example.com\"}"];
    
    XCTAssertTrue ([map [[@"a" ednKeyword]] isKindOfClass: [NSURL class]], @"Data decoded");
    XCTAssertEqualObjects (map [[@"a" ednKeyword]], [[NSURL alloc] initWithString: @"http://example.com"], @"Data decoded");
  }
}

- (void) testGeneralUsage
{
  MPEdnParser *parser = [MPEdnParser new];
  
  parser.inputString = @"1 \"abc\" {:a 1, :foo [1 2 3]}";
  
  while (!parser.complete)
  {
    id value = [parser parseNextValue];
    
    NSLog (@"Value %@", value);
    
    XCTAssertNotNil (value, @"Value");
  }
  
  parser.inputString = @"[:unterminated";
  
  id value = [parser parseNextValue];
  
  XCTAssertNil (value, @"Nil on parse error");
  XCTAssertNotNil (parser.error, @"Error set on parse error");
  
  NSLog (@"Error: %@", parser.error);
}

@end
