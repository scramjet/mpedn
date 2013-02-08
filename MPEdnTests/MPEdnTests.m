#import "MPEdnTests.h"

#import "MPEDN.h"

@implementation MPEdnTests

//- (void)setUp
//{
//    [super setUp];
//    
//    // Set-up code here.
//}
//
//- (void)tearDown
//{
//    // Tear-down code here.
//    
//    [super tearDown];
//}

- (void) testNumbers
{
  // int
  STAssertEqualObjects ([@"1" ednStringToObject], @1, @"Integer");
  STAssertEqualObjects ([@"+1" ednStringToObject], @1, @"Integer");
  STAssertEqualObjects ([@"-1" ednStringToObject], @-1, @"Integer");
  STAssertEqualObjects ([@" 1 " ednStringToObject], @1, @"Integer (whitespace)");
  
  // double
  STAssertEqualObjects ([@"1.2" ednStringToObject], @1.2, @"Float");
  STAssertEqualObjects ([@"1.2e4" ednStringToObject], @1.2e4, @"Float");
  STAssertEqualObjects ([@"-42.2e-2" ednStringToObject], @-42.2e-2, @"Float");
  STAssertEqualObjects ([@".2" ednStringToObject], @.2, @"Float");
  
  // errors
  STAssertNil ([@"." ednStringToObject], @"Float");
  STAssertNil ([@"1." ednStringToObject], @"Float");
  STAssertNil ([@"-+1" ednStringToObject], @"Float");
  STAssertNil ([@"1e" ednStringToObject], @"Float");
}

@end
