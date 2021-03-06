#!/bin/bash
set -e
# https://www.zimuel.it/blog/sign-and-verify-a-file-using-openssl
# If you need to sign and verify a file you can use the OpenSSL command line tool. OpenSSL is a common library used by many operating systems (I tested the code using Ubuntu Linux).
# I was working on a prototype to sign the source code of open source projects in order to release it including the signature. More or less the same idea implemented in Git to sign tag or a commit. Git uses GnuPG, I wanted to do the same using OpenSSL to be more general.
# Sign a file
# To sign a file using OpenSSL you need to use a private key. If you don't have an OpenSSL key pair you can create it using the following commands:
export SAME_PRIVATE_KEY_PASSPHRASE="M4TUK0WaB34b"

openssl genrsa -aes128 -passout pass:$SAME_PRIVATE_KEY_PASSPHRASE -out private.pem 4096
openssl rsa -in private.pem -passin pass:$SAME_PRIVATE_KEY_PASSPHRASE -pubout -out public.pem

# where <phrase> is the passphrase used to encrypt the private key stored in private.pem file. The private key is stored in private.pem file and the public key in the public.pem file.
# For security reason, I suggest to use 4096 bits for the keys, you can read the reason in this blog post.

