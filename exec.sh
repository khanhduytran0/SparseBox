# ./exec $@

zsign -k ct.p12 -p password -m embedded.mobileprovision -o Payload.ipa Payload/BaseApp.app

# zip --symlinks -r Payload.ipa Payload