
all: adhoc appstore

adhoc:
	PWD=`pwd`
	mkdir -p build
	rm -rf "build/.adhoc" "build/TestFairy-AdHoc.ipa"
	cordova prepare ios --release --device
	xcodebuild -workspace platforms/ios/TestFairy.xcodeproj/project.xcworkspace -scheme TestFairy -configuration "Ad Hoc" DSTROOT="$(PWD)/build/.adhoc" archive 
	xcrun -sdk iphoneos lipo -info $(PWD)/build/.adhoc/Applications/TestFairy.app/TestFairy | grep "armv7 armv7s arm64"
	mv build/.adhoc/Applications build/.adhoc/Payload
	(cd $(PWD)/build/.adhoc/; zip -rp9 ../TestFairy-AdHoc.ipa Payload)
	-rm -rf build/.adhoc

appstore:
	PWD=`pwd`
	mkdir -p build
	rm -rf "build/.appstore" "build/TestFairy-AppStore.ipa"
	cordova prepare ios --release --device
	xcodebuild -workspace platforms/ios/TestFairy.xcodeproj/project.xcworkspace -scheme TestFairy -configuration "App Store" DSTROOT="$(PWD)/build/.appstore" archive
	xcrun -sdk iphoneos lipo -info $(PWD)/build/.appstore/Applications/TestFairy.app/TestFairy | grep "armv7 armv7s arm64"
	mv build/.appstore/Applications build/.appstore/Payload
	(cd $(PWD)/build/.appstore/; zip -rp9 ../TestFairy-AppStore.ipa Payload)
	-rm -rf build/.appstore

clean:
	-rm -rf ./build
	-rm -rf ./platforms/ios/build/
	-rm -rf ./platforms/ios/CordovaLib/build/CordovaLib.build/
