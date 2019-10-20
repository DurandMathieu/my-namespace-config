SECRETS=$1/secrets.enc.env
DECRYPTED_SECRETS=$1/secrets.env
if test -f "$SECRETS"; then
    sops -d $SECRETS > $DECRYPTED_SECRETS
fi

kustomize build $1 | kubectl apply -f -

if test -f "$DECRYPTED_SECRETS"; then
    rm -f $DECRYPTED_SECRETS
fi