#!/bin/bash

function kustomizeYaml() {
  local overlayFolder=$1
  #Decrypt secrets
  for i in $overlayFolder/*.enc.*; do
      decryptedFile="${i/.enc/}"
      sops -d $i > $decryptedFile
  done

  kustomize build $overlayFolder
  #kustomize build $overlayFolder | kubectl apply -f -

  #Remove decrypted files
  for i in $overlayFolder/*.enc.*; do
      decryptedFile="${i/.enc/}"
      rm -f $decryptedFile
  done
}

function helmYaml() {
  local stageFolder=$1
  local repo=$(jq -r .repo $stageFolder/helm.json)
  local chart=$(jq -r .chart $stageFolder/helm.json)
  local version=$(jq -r .version $stageFolder/helm.json)
  helm fetch --untar --destination $stageFolder/_chart $repo/$chart --version $version
  
  sops -d $stageFolder/secrets.enc.yaml > $stageFolder/secrets.yaml
  cat $stageFolder/values.yaml > $stageFolder/values-with-secrets.yaml
  echo -e "" >> $stageFolder/values-with-secrets.yaml
  cat $stageFolder/secrets.yaml >> $stageFolder/values-with-secrets.yaml

  helm template --values $stageFolder/values-with-secrets.yaml $stageFolder/_chart/$chart > $stageFolder/heml_output.yaml
  kubectl apply -f $stageFolder/heml_output.yaml
  
  #rm -f $stageFolder/heml_output.yaml
  #rm -rf $stageFolder/_chart
  #rm -f $stageFolder/values-with-secrets.yaml
  #rm -f $stageFolder/secrets.yaml
}

if [ -z "$1" ]
then
    echo "Usage, apply.sh <stage>"
else
  target=$1

  for d in */ ; do
    #ignore folder starting with underscore
    if [[ $d != _* ]]
    then
      echo "###### Templates for application $d ######"
      if test -d "${d}overlays/$target"; then
        kustomizeYaml "${d}overlays/$target"
      elif test -f "${d}/$target/helm.json"; then
        helmYaml "${d}/$target"
      fi
    fi
  done
fi
