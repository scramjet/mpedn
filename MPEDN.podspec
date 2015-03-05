# coding: utf-8

Pod::Spec.new do |s|

  s.name         = "MPEDN"
  s.version      = "1.0.0"
  s.summary      = "An EDN (Extensible Data Notation) Objective C library for OS X and iOS."

  s.description  = <<-DESC
    The library includes:

    * `MPEdnParser`, a parser for reading EDN and generating equivalent Cocoa data
      structures.

    * `MPEdnWriter`, which writes Cocoa data structures as EDN.

    For most uses, parsing EDN is as simple as:

        [@"{:a 1}" ednStringToObject];

    Which returns the parsed object or nil on error.

    And to generate EDN from a Cocoa object:

        [myObject objectToEdnString];

    See the headers for API docs.
    DESC

  s.homepage     = "https://github.com/scramjet/mpedn"
  s.license      = { :type => "Eclipse", :file => "LICENSE" }
  s.author       = { "Matthew Phillips" => "m@mattp.name" }
  s.source       = { :git => "https://github.com/scramjet/mpedn.git", :tag => "1.0.0" }
  s.source_files = "MPEdn"
  s.requires_arc = true
end
