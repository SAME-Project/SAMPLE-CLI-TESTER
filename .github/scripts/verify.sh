#!/bin/bash
set -
# # https://www.zimuel.it/blog/sign-and-verify-a-file-using-openssl
# Verify the signature
# To verify the signature you need to convert the signature in binary and after apply the verification process of OpenSSL. You can achieve this using the following commands:
openssl base64 -d -in same.signature.sha256 -out /tmp/sign.sha256
openssl dgst -sha256 -verify public.pem -signature /tmp/sign.sha256 bin/same