xcodebuild -workspace XNGOAuth1Client.xcworkspace -scheme 'XNGOAuth1Client' clean build test -sdk iphonesimulator$OS | xcpretty -tc; exit ${PIPESTATUS[0]}
