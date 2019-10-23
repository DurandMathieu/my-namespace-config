#!/bin/bash

#Decrypt secrets
for i in $1/*.enc.*; do
    decryptedFile="${i/.enc/}"
    echo "Decrypting $i >> $decryptedFile"
    sops -d $i > $decryptedFile
done

kustomize build $1
kustomize build $1 | kubectl apply -f -

#Remove decrypted files
for i in $1/*.enc.*; do
    decryptedFile="${i/.enc/}"
    rm -f $decryptedFile
done