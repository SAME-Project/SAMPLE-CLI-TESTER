#!/bin/bash
set -
# # https://www.zimuel.it/blog/sign-and-verify-a-file-using-openssl
# https://gist.github.com/ezimuel/3cb601853db6ebc4ee49
# Verify the signature
# To verify the signature you need to convert the signature in binary and after apply the verification process of OpenSSL. You can achieve this using the following commands:
# openssl base64 -d -in same.signature.sha256 -out /tmp/sign.sha256
# openssl dgst -sha256 -verify public.pem -signature /tmp/sign.sha256 bin/same

# https://unix.stackexchange.com/questions/181937/how-create-a-temporary-file-in-shell-script

SAME_PRIVATE_KEY=$(<private.pem)
SAME_PUBLIC_KEY=$(<public.pem)
SAME_SIGNATURE=$(<same.sig)
SAME_TEMP_DIR=$(mktemp -d)
trap '{ rm -rf -- "$SAME_TEMP_DIR"; }' EXIT

same_private_key_file=$(mktemp $(SAME_TEMP_DIR)/same-private-key.XXXXXX)
same_public_key_file=$(mktemp $(SAME_TEMP_DIR)/same-public-key.XXXXXX)

#echo  "$SAME_PRIVATE_KEY;$SAME_PUBLIC_KEY;$SAME_PASSPHRASE" | xargs -d \; -t -I % \
echo  "$SAME_PUBLIC_KEY;$SAME_SIGNATURE" | xargs -d \; -t -I % \
sh -c 'openssl dgst -sha256 -verify "%" -signature "%" bin/same'