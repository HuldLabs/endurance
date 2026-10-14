#!/usr/bin/env bash
# Feature kubectl-helm: kubectl (dl.k8s.io, com o .sha256 oficial ao lado do binario) e
# helm (get.helm.sh, com o .sha256sum oficial). Versoes fixas. O cluster e' do projeto.
#
# Idempotente: cada binario so' e' baixado se a versao pedida nao estiver instalada.
set -euo pipefail

KUBECTL_VERSION="${KUBECTLVERSION:-1.37.1}"
HELM_VERSION="${HELMVERSION:-4.3.0}"

case "$(dpkg --print-architecture)" in
  amd64|arm64) ARCH="$(dpkg --print-architecture)" ;;
  *) echo "kubectl-helm: arquitetura nao suportada: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

if ! { command -v kubectl >/dev/null 2>&1 && kubectl version --client 2>/dev/null | grep -qx "Client Version: v${KUBECTL_VERSION}"; }; then
  base="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}"
  curl -fsSL "$base/kubectl" -o "$tmp/kubectl"
  echo "$(curl -fsSL "$base/kubectl.sha256")  $tmp/kubectl" | sha256sum -c -
  install -m 0755 "$tmp/kubectl" /usr/local/bin/kubectl
fi

if ! { command -v helm >/dev/null 2>&1 && helm version --template '{{.Version}}' | grep -qx "v${HELM_VERSION}"; }; then
  file="helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz"
  curl -fsSL "https://get.helm.sh/$file" -o "$tmp/$file"
  curl -fsSL "https://get.helm.sh/$file.sha256sum" | (cd "$tmp" && sha256sum -c -)
  tar -xzf "$tmp/$file" -C "$tmp" "linux-${ARCH}/helm"
  install -m 0755 "$tmp/linux-${ARCH}/helm" /usr/local/bin/helm
fi

kubectl version --client | head -n1
helm version --template '{{.Version}}'; echo
echo "kubectl-helm: pronto (kubectl ${KUBECTL_VERSION}, helm ${HELM_VERSION})"
