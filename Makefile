
.PHONY: secret
secret:
	mkdir Yomiage/Firebase
	echo $(FILE_FIREBASE_IOS_DEVELOPMENT) | base64 -d > Yomiage/Firebase/GoogleService-Info-dev.plist
	echo $(FILE_FIREBASE_IOS_PRODUCTION) | base64 -d > Yomiage/Firebase/GoogleService-Info-prod.plist


