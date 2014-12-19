xcodebuild -workspace XNGOAuth1Client.xcworkspace -scheme 'XNGOAuth1Client' clean build test -sdk iphonesimulator | xcpretty -tc; exit ${PIPESTATUS[0]}
