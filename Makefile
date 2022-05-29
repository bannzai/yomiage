
.PHONY: secret
secret:
	mkdir -p Yomiage/Firebase
	echo $(FILE_FIREBASE) | base64 -d > Yomiage/Firebase/GoogleService-Info.plist
	./scripts/secret.sh


