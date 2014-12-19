xcodebuild -workspace XNGOAuth1Client.xcworkspace -scheme 'XNGOAuth1Client' -destination name='iPhone 6' clean build test -sdk iphonesimulator | xcpretty -tc; exit ${PIPESTATUS[0]}
