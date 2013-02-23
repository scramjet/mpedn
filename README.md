# MPEdn

An EDN ([Extensible Data Notation](http://github.com/edn-format/edn)) I/O library for OS X and iOS.

The library includes:

* `MPEdnParser`, a parser for reading EDN and generating equivalent Cocoa data structures.

* `MPEdnWriter`, which writes Cocoa data structures as EDN.

For most uses, parsing EDN is just:

    [@"{:a 1} ednStringToObject];
    
And generating EDN is simply:

    [myObject objectToEdnString];
    
See the headers for API docs.

## Using It In Your Project

To use the library, either:

* Generate `libMPEdn.a` using the supplied Xcode project and copy that and the `.h` files to your project, or;

* Use a workspace containing your project and MPEdn as described [here][xcode_static_lib]. You may also need to add the `-all_load` flag to the "Other Linker Flags" section of your project if the `ednStringToObject` and `objectToEdnString` category methods are not linked in.

[xcode_static_lib]: http://developer.apple.com/library/ios/#documentation/Xcode/Conceptual/ios_development_workflow/AA-Developing_a_Static_Library_and_Incorporating_It_in_Your_Application/archiving_an_application_that_uses_a_static_library.html

## EDN To Cocoa Mapping

* EDN map <-> NSDictionary (but see `[MPEdnParser newDictionary]` to override).
  
* EDN list or vector <-> `NSArray` (but see `[MPEdnParser newArray]` to override).
  
* EDN set <-> `NSSet` (but see `[MPEdnParser newSet]` to override).
  
* EDN string <-> `NSString`.

* EDN float <-> `NSNumber` (`numberWithDouble`). The `N` suffix is not supported.
  
* EDN int <-> `NSNumber` (`numberWithLong`). The `M` suffix is not supported.

* EDN boolean <-> `NSNumber` (`numberWithBool`).

* EDN character <-> `NSNumber` (`numberWithUnsignedChar`). `NSNumber` appears to be quite broken for representing characters. For example, `[NSNumber numberWithChar: 'a']` produces an `NSNumber` that correctly indicates it wraps a character, but when using `numberWithChar` with `\n` it does not (meaning `\n` will be emitted as `10`). As as workaround, you can force a number to be seen as a character using `MPEdnTagAsCharacter()`.

* EDN keyword <-> `NSString`. If the `MPEdnWriter.useKeywordsInMaps` property is true (the default), strings used as keys in maps will be output as keys if possible.

* EDN symbol <-> `MPEdnSymbol`.

* EDN tagged values: Use `+[MPEdnParser tagForValue]` to retrieve the tag associated with the value.


## Notes

* Tagged values would probably be better handled by registering a custom reader for them, since this is their usual purpose.

* Symbols would probably be better handled by resolving them to a value, either through a symbol table or a user-defined callback.

* Floats are output in full to avoid loss of precision.

* Newlines in strings are output in their escaped form (e.g. `\n` rather than `0x0a`), even though the raw form is legal, in order to make it straightforward to use generated EDN strings in line-oriented protocols.

* The parser and writer fully support all Unicode characters (i.e. both 'normal' characters and UTF-16 surrogate pairs) in strings, but not elsewhere. General support could easily be added, at the cost of some speed, but since EDN syntax is defined in terms of ASCII character classes it's not clear that using UTF-16 outside of strings would be valid EDN in any case.

## Author And License

MPEDn is developed by Matthew Phillips (<m@mattp.name>). It is licensed under the same open source license as Clojure, the [Eclipse Public License v1.0][epl] .


[epl]: http://opensource.org/licenses/eclipse-1.0.php
