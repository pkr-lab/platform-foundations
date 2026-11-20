# Tools und Versionen

Das Lab ist mit den folgenden Mindestversionen erstellt worden. Neuere Versionen funktionieren in der Regel ebenfalls.

| Tool | Mindestversion | Wofür | Ab Modul |
| --- | --- | --- | --- |
| WSL 2 mit Ubuntu | 24.04 | Linux-Umgebung unter Windows; bringt Podman 4.9 mit | 01 |
| Podman | 4.x | Container (rootless), Provider für kind, Images bauen | 01 |
| kind | v0.27 | lokaler Kubernetes-Cluster; ab v0.27 liest containerd die Registry-Mirror-Konfiguration aus `/etc/containerd/certs.d` automatisch | 01 |
| kubectl | passend zur Kubernetes-Version des kind-Clusters (± 1 Minor-Version) | Cluster bedienen | 01 |
| Helm | v3.13 | Charts aus dem Artifactory installieren, paketieren, als OCI-Artefakt hochladen | 02 |
| git | 2.x | GitOps-Repo | 06 |
| kubeseal | passend zum Sealed-Secrets-Controller | Secrets verschlüsseln | 06 |
| argocd CLI | optional | ArgoCD von der Kommandozeile | 07 |

Prüfen der installierten Versionen:

```bash
podman --version
kind version
kubectl version --client
helm version
git --version
```

## Images, Charts und feste Versionen

Alle Images und Helm-Charts kommen aus dem Artifactory (siehe [Artifactory.md](./Artifactory.md)). Im Lab gilt: immer eine feste Version, nie `latest` oder `stable`.

| Artefakt | Version im Lab | Wo verwendet |
| --- | --- | --- |
| `nginx` | `1.28.0` | Modul 01, 02 |
| `nginxinc/nginx-unprivileged` | `1.28.0` | Modul 02, Chart `azubi-portal`, Basis-Image in Modul 05 |
| `alpine` | `3.20.3` | Build-Stage in Modul 05 |
| `curlimages/curl` | `8.10.1` | Modul 01 (Bonus), 02 |
| `busybox` | `1.36.1` | Mirror-Test in Modul 01 |
| `kindest/node` | passend zur kind-Version (Release Notes von kind) | Modul 01 |
| `ghcr.io/headlamp-k8s/headlamp` | `v0.25.0` | Modul 08 |

Für die öffentlichen Helm-Charts (Traefik, podinfo, Sealed Secrets, ArgoCD, Metrics Server, kube-prometheus-stack) steht in den Modulen `--version <chart-version>`. Ermittle die Version mit `helm search repo artifactory/<chart> --versions`, entscheide dich für eine und notiere sie. Wenn dein Ausbilder Versionen vorgibt, verwende diese. Sind die oben genannten Image-Versionen im Artifactory nicht (mehr) verfügbar oder von Xray gesperrt, nimm die nächste verfügbare feste Version.

## Installation (Ubuntu unter WSL)

Die offiziellen Anleitungen sind maßgeblich, da sich Download-Adressen ändern können:

- Podman: `sudo apt update && sudo apt install -y podman`
- kind: [Installationsanleitung](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- kubectl: [Installationsanleitung für Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- Helm: [Installationsanleitung](https://helm.sh/docs/intro/install/)
- kubeseal: [Sealed Secrets – Installation](https://github.com/bitnami-labs/sealed-secrets#installation)
- argocd CLI: [Installationsanleitung](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

Im Firmennetz kommen Binaries und Pakete idealerweise ebenfalls über das Artifactory (Generic- oder Remote-Repositories). Frag deinen Ausbilder nach den passenden Adressen.

## Umgebungsvariablen

| Variable | Wert | Zweck |
| --- | --- | --- |
| `KIND_EXPERIMENTAL_PROVIDER` | `podman` | kind nutzt Podman statt Docker; dauerhaft in `~/.bashrc` setzen |
