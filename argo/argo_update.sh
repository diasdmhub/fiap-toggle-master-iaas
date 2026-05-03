#!/usr/bin/env bash

# 1. Validação de requisitos
missing=()
for cmd in jq argocd aws; do
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
    sed -i "/name: ${serv}-service/,/value:/ s|^\(\s*\)value:\s*$|\1value: ${SERVICE}:latest|" argo/argo_deploy.yaml && \
    echo "URL do $serv-service atualizada"
done

# 3. Criação de uma conta de serviço

# Variáveis
NAME_PREFIX="$(grep '^name_prefix' terraform.tfvars | cut -d '"' -f 2)"

SERVICE_ACC_NAME="${NAME_PREFIX}-serv-acc"
CLUSTER_NAME="${NAME_PREFIX}-eks-cluster"
ROLE_NAME="${NAME_PREFIX}-role"
POLICY_NAME="${NAME_PREFIX}-extra-policy"
NAMESPACE="toggle"

# Variáveis dinâmicas - Dependem do AWS CLI
ACC_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

# CARREGA O ARQUIVO DE POLÍTICAS EXTRAS
POLICY_LOAD=$(sed "s/_ACCOUNT_ID_/$ACC_ID/g" ./argo/toggle-policy.json)

# CRIA O PROVEDOR IAM OPENID PARA O CLUSTER
eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER_NAME" --approve

# CRIA A POLÍTICA EXTRA DA TOGGLEMASTER
aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$POLICY_LOAD" 2>/dev/null || true

# CRIA UMA CONTA DE SERVIÇO GERENCIADA POR OPENID COM AS POLÍTICAS PADRÕES E EXTRAS
eksctl create iamserviceaccount \
  --override-existing-serviceaccounts \
  --name "$SERVICE_ACC_NAME" \
  --namespace "$NAMESPACE" \
  --cluster "$CLUSTER_NAME" \
  --role-name "$ROLE_NAME" \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKSServiceRolePolicy \
  --attach-policy-arn arn:aws:iam::aws:policy/AWSServiceRoleForAmazonEKSNodegroup \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore \
  --attach-policy-arn arn:aws:iam::"${ACC_ID}":policy/"${POLICY_NAME}" \
  --approve

echo -e "\n\nROLE \"$ROLE_NAME\" CRIADO COM SUCESSO:"
echo "######"
aws iam get-role --role-name "$ROLE_NAME" --query Role.AssumeRolePolicyDocument --output yaml
echo "######"

echo -e "\n\nPOLÍTICAS ASSOCIADAS AO ROLE:"
aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[].PolicyArn" --output table

echo -e "\n\nCONTA DE SERVIÇO COM A ROLE NA ANOTAÇÃO:"
echo "######"
kubectl describe serviceaccount "$SERVICE_ACC_NAME" -n "$NAMESPACE"