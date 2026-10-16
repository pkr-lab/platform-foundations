# Tools und Versionen

Das Lab ist mit den folgenden Mindestversionen erstellt worden. Neuere Versionen funktionieren in der Regel ebenfalls.

| Tool | Mindestversion | Wofür | Ab Modul |
| --- | --- | --- | --- |
| WSL 2 mit Ubuntu | 22.04 | Linux-Umgebung unter Windows | 01 |
| Podman | 4.x | Container, Provider für kind | 01 |
| kind | v0.24 | lokaler Kubernetes-Cluster (ab v0.24 mit NetworkPolicy-Support) | 01 |
| kubectl | passend zur Kubernetes-Version des kind-Clusters (± 1 Minor-Version) | Cluster bedienen | 01 |
| Helm | v3.13 | Charts installieren, paketieren, `helm push --plain-http` | 02 |
| git | 2.x | GitOps-Repo | 05 |
| kubeseal | passend zum Sealed-Secrets-Controller | Secrets verschlüsseln | 05 |
| argocd CLI | optional | ArgoCD von der Kommandozeile | 06 |

Prüfen der installierten Versionen:

```bash
podman --version
kind version
kubectl version --client
helm version
git --version
```

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
| `KIND_EXPERIMENTAL_PROVIDER` | `podman` | kind nutzt Podman statt Docker |
