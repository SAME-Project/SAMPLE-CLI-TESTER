#!/bin/bash
set -
# # https://www.zimuel.it/blog/sign-and-verify-a-file-using-openssl
# When you have the private and public key you can use OpenSSL to sign the file. The default output format of the OpenSSL signature is binary. If you need to share the signature over internet you cannot use a binary format. You can use for instance Base64 format for file exchange.
# You can use the following commands to generate the signature of a file and convert it in Base64 format:

export SAME_PRIVATE_KEY=$(<private.pem)
export SAME_TEMP_DIR=$(mktemp -d -t same-install-tmpdir-XXXXXX)
export SAME_PRIVATE_KEY_PASSPHRASE="M4TUK0WaB34b"
trap '{ rm -rf -- "$SAME_TEMP_DIR"; }' EXIT
same_private_key_file=$(mktemp $SAME_TEMP_DIR/same-private-key.XXXXXX)

openssl dgst -sha256 -sign private.pem -passin pass:$SAME_PRIVATE_KEY_PASSPHRASE -out /tmp/sign.sha256 bin/same
openssl base64 -in /tmp/sign.sha256 -out same.signature.sha256

# where <private-key> is the file containing the private key, <file> is the file to sign and <signature> is the file name for the digital signature in Base64 format. I used the temporary folder (/tmp) to store the binary format of the digital signature. Remember, when you sign a file using the private key, OpenSSL will ask for the passphrase.
# The <signature> file can now be shared over internet without encoding issue.
