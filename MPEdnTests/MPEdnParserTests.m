#import "MPEdnParserTests.h"

#import "MPEdn.h"
#import "MPEdnSymbol.h"

#define MPAssertParseOK(expr, correctValue, message)    \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  STAssertEqualObjects (value, correctValue, message);         \
  STAssertNil (parser.error, message);     \
  STAssertTrue (parser.complete, message); \
}

#define MPAssertParseError(expr, message)  \
{                                          \
  MPEdnParser *parser = [MPEdnParser new]; \
                                           \
  id value = [parser parseString: expr];   \
                                           \
  STAssertNil (value, message);            \
  STAssertNotNil (parser.error, message);  \
  STAssertTrue (parser.complete, message); \
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
  
  // does not allow M or N (not implemented)
  MPAssertParseError (@"1.0M", @"Float");
  
  // errors
  MPAssertParseError (@".", @"Float");
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
  
  STAssertEqualObjects (value1, @1, @"Value 1");
  STAssertEqualObjects (value2, @2, @"Value 2");
  STAssertTrue (parser.complete, @"Complete");
}

- (void) testStrings
{
  MPAssertParseOK (@"\"\"", @"", @"String");
  MPAssertParseOK (@"\"hello\"", @"hello", @"String");
  MPAssertParseOK (@"\"hello\t\\\"there\\\"\"", @"hello\t\"there\"", @"String with escapes");
  
  // unicode (UTF-16)
  NSString *smiley = [NSString stringWithUTF8String: "hello \xF0\x9F\x98\x84 smiley"];
  NSString *str = [NSString stringWithFormat: @"\"%@\"", smiley];
  MPAssertParseOK (str, smiley, @"String with Unicode");
  
  // errors
  MPAssertParseError (@"\"hello", @"Unterminated string");
  MPAssertParseError (@"\"\\a\"", @"Invalid escape");
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
  
  MPAssertParseError (@"}", @"Not a symbol");
  MPAssertParseError (@"]", @"Not a symbol");
  MPAssertParseError (@")", @"Not a symbol");
}

- (void) testKeywords
{
  MPAssertParseOK (@":a", @"a", @"Keyword");
  MPAssertParseOK (@":abc", @"abc", @"Keyword");
  MPAssertParseOK (@":abc.def/ghi", @"abc.def/ghi", @"Keyword");
  
  MPAssertParseError (@":", @"Keyword");
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
    id items = [NSSet setWithArray: @[@1, @"abc", @"def"]];
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
    id map = @{@"a" : @1};
    MPAssertParseOK (@"{:a, 1}", map, @"Map");
  }
  {
    id map = @{@"a" : @1, @"b" : @"c"};
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
    id list = @[@"a", @1];
    MPAssertParseOK (@"[:a, 1]", list, @"List");
    MPAssertParseOK (@"(:a, 1)", list, @"List");
  }
  
  {
    id list = @[@{@"a" : @1}, @2];
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
  MPAssertParseOK (@"\\a", @'a', @"Character");
  MPAssertParseOK (@"\\ ", @' ', @"Character");
  MPAssertParseOK (@"\\newline", @'\n', @"Character");
  MPAssertParseOK (@"\\tab", @'\t', @"Character");
  MPAssertParseOK (@"\\return", @'\r', @"Character");
  MPAssertParseOK (@"\\space", @' ', @"Character");
  
  MPAssertParseError (@"\\", @"Character");
  MPAssertParseError (@"\\hello", @"Character");
}

- (void) testTaggedValues
{
  id map = [@"#hello {:a 1}" ednStringToObject];
  
  STAssertEqualObjects (@"hello", [MPEdnParser tagForValue: map], @"Tag");
  
  MPAssertParseError (@"#", @"Tag");
  MPAssertParseError (@"# {", @"Tag");
  MPAssertParseError (@"# #", @"Tag");
  MPAssertParseError (@"#tag #tag {}", @"Tag");
}

- (void) testGeneralUsage
{
  MPEdnParser *parser = [MPEdnParser new];
  
  parser.inputString = @"1 \"abc\" {:a 1, :foo [1 2 3]}";
  
  while (!parser.complete)
  {
    id value = [parser parseNextValue];
    
    NSLog (@"Value %@", value);
    
    STAssertNotNil (value, @"Value");
  }
  
  parser.inputString = @"[:unterminated";
  
  id value = [parser parseNextValue];
  
  STAssertNil (value, @"Nil on parse error");
  STAssertNotNil (parser.error, @"Error set on parse error");
  
  NSLog (@"Error: %@", parser.error);
}

@end
