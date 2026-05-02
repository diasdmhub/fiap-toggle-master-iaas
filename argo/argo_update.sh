#!/usr/bin/env bash

# 1. Validação de requisitos
missing=()
for cmd in jq argocd; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done

if (( ${#missing[@]} )); then
    printf 'ERRO: os requisitos abaixo não foram encontrados. Por favor, verifique a instalação deles.\n' >&2
    for m in "${missing[@]}"; do
        printf ' Binário - %s\n' "$m" >&2
    done
    exit 1
fi

# 2. Atualização das URLs

cp argo/argo_deploy.yaml.example argo/argo_deploy.yaml

sed -i -E "s|^(\s+)repoURL: .*|\1repoURL: $(git config --get remote.origin.url)|" argo/argo_deploy.yaml

for serv in "auth" "flag" "targeting" "evaluation" "analytics"; do
    SERVICE=$(terraform output -json ecr_outputs | jq -r .ecr_repository_urls.$serv)
    sed -i "/name: ${serv}-service/,/value:/ s|^\(\s*\)value:\s*$|\1value: ${SERVICE}:latest|" argo/argo_deploy.yaml
done