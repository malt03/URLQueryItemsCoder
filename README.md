# URLQueryItemsCoder [![Build Status](https://travis-ci.org/malt03/URLQueryItemsCoder.svg?branch=master)](https://travis-ci.org/malt03/URLQueryItemsCoder) [![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg)](https://github.com/apple/swift-package-manager) ![License](https://img.shields.io/github/license/malt03/URLQueryItemsCoder.svg)
I used [Kingfisher](https://github.com/onevcat/Kingfisher) as reference. Great thanks to onevcat !

Macduff is a library for downloading, caching and displaying images on SwiftUI.  
You can create ProgressView or ErrorView, and customize ImageView.  

## Usage

```swift
struct Property: Encodable {
    let a = 1
    let b = [2, 3]
    let c = C()

    struct C: Encodable {
        let a = 4
    }
}

var urlComponents = URLComponents(string: "http://example.com")
urlComponents?.queryItems = try! URLQueryItemsEncoder().encode(Property())
print(urlComponents?.url?.absoluteString ?? "") // http://example.com?a=1&b%5B0%5D=2&b%5B1%5D=3&c%5Ba%5D=4 => a=1&b[0]=2&b[1]=3&c[a]=4
```

## Installation

### [SwiftPM](https://github.com/apple/swift-package-manager) (Recommended)

- On Xcode, click `File` > `Swift Packages` > `Add Package Dependency...`
- Input `https://github.com/malt03/URLQueryItemsCoder.git`
