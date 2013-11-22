# MPEdn

An EDN ([Extensible Data Notation](http://github.com/edn-format/edn)) Objective C I/O library for OS X and iOS.

The library includes:

* `MPEdnParser`, a parser for reading EDN and generating equivalent Cocoa data structures.

* `MPEdnWriter`, which writes Cocoa data structures as EDN.

For most uses, parsing EDN is as simple as:

    [@"{:a 1}" ednStringToObject];

Which returns the parsed object or nil on error.

And to generate EDN from a Cocoa object:

    [myObject objectToEdnString];

See the headers for API docs.

## Note To Users MPEdn 0.1

Release 0.2 will break existing -- sorry! The default setting for automatically outputting NSDictionary string keys as keywords (the `MPEdnWriter useKeywordsInMaps` property) has changed from YES to NO in 0.2. If you wish to preserve the 0.1 behaviour, use `objectToEdnStringAutoKeywords` rather than `objectToEdnString` to generate EDN output.

Also, keywords are now realised as `MPEdnKeyword` instances rather than strings as in 0.1. To get the old behaviour, set the `keywordsAsStrings` property on MPEdnParser or use `[NSString ednStringToObjectKeywordsAsStrings]`.


## Using It In Your Project

To use the library, either:

* Generate `libMPEdn.a` using the supplied Xcode project and copy that and the `.h` files to your project, or;

* Use a workspace containing your project and MPEdn as described [here][xcode_static_lib]. You may also need to add the `-all_load` flag to the "Other Linker Flags" section of your project if the `ednStringToObject` and `objectToEdnString` category methods do not get linked in.

[xcode_static_lib]: http://developer.apple.com/library/ios/#documentation/Xcode/Conceptual/ios_development_workflow/AA-Developing_a_Static_Library_and_Incorporating_It_in_Your_Application/archiving_an_application_that_uses_a_static_library.html


## EDN To Cocoa Mapping

* EDN map <-> `NSDictionary` (but see `[MPEdnParser newDictionary]` to override).

* EDN list or vector <-> `NSArray` (but see `[MPEdnParser newArray]` to override).

* EDN set <-> `NSSet` (but see `[MPEdnParser newSet]` to override).

* EDN string <-> `NSString`.

* EDN float <-> `NSNumber` (`numberWithDouble`). The `N` suffix is not supported.

* EDN int <-> `NSNumber` (`numberWithLong`). The `M` suffix is not supported.

* EDN boolean <-> `NSNumber` (`numberWithBool`).

* EDN character <-> `NSNumber` (`numberWithUnsignedChar`). Note however that `NSNumber` appears to be broken when representing characters. For example, `[NSNumber numberWithChar: 'a']` produces a `NSNumber` that correctly indicates it wraps a character, but `numberWithChar` with `\n` does not, meaning `\n` will be emitted as `10`. As as workaround, you can force a number to be seen as a character using `MPEdnTagAsCharacter()`.

* EDN keyword <-> `MPEdnKeyword`. If the `MPEdnWriter.useKeywordsInMaps` property is true (the default is false as of 0.2), strings used as keys in `NSDictionary` will be output as keywords if possible. Note that strings and keywords never compare as equal, so this could get confusing when reading a dictionary from an external service that uses keywords: in general, prefer explicit use of keywords where possible.

* EDN symbol <-> `MPEdnSymbol`.

* EDN tagged values can be translated by tag reader/writer classes implementing `MPEdnTaggedValueWriter` and/or `MPEdnTaggedValueReader` (see `MPEdnBase64Codec` for an example). You can accept  any tag regardless of whether there is a reader for it or not by setting the `allowUnknownTags` property on `MPEdnParser`, which will represent unknown tagged values with `MPEdnTaggedValue` instances. `MPEdnWriter` knows how to output `MPEdnTaggedValue`'s which enables round-tripping of EDN with unknown tags.


## Notes

* Symbols would probably be better handled in future by resolving them to a mapped value, either through a symbol table or a user-defined callback.

* Floats are output in full to avoid loss of precision.

* Newlines in strings are output in their escaped form (`\n` rather than a raw `0x0a`) even though the raw form is legal in order to make it straightforward to use generated EDN strings in line-oriented protocols.

* The parser and writer fully support all Unicode code points in string values (i.e. both 'normal' characters and UTF-16 surrogate pairs), but not elsewhere. Adding general support would be straightforward, at the cost of some speed, but since EDN syntax is defined in terms of ASCII character classes it's not clear that using anything but ASCII outside of strings would be valid EDN in any case.


## Author And License

MPEdn is developed by Matthew Phillips (<m@mattp.name>). It is licensed under the same open source license as Clojure, the [Eclipse Public License v1.0][epl] .

[epl]: http://opensource.org/licenses/eclipse-1.0.php
