# GitOps-Repo für das Azubi-Lab

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `cluster/argocd-apps/` | ArgoCD-Applications, eine Datei pro App |
| `apps/<app>/` | Helm-Chart der App inklusive `values-<umgebung>.yaml` |

## Umgebungen

| Datei | Umgebung |
| --- | --- |
| `values-lab.yaml` | lokaler kind-Cluster `lab` |

## Artefakte

- Images: `<artifactory-host>/<docker-push-repo>/<app>:<version>`
- Charts: `oci://<artifactory-host>/<helm-repo>/<app>`

## Workflow

1. Feature-Branch anlegen (`feature/<kurzbeschreibung>`)
2. Änderung durchführen und lokal mit `helm lint` und `helm template` prüfen
3. Merge Request nach `main` mit Beschreibung *was* und *warum*
4. Nach Review mergen – ArgoCD übernimmt den Rest
5. Rollback per `git revert`

## Regeln

- keine Klartext-Secrets, nur `SealedSecret`
- keine `latest`-Tags
- kein direktes `kubectl apply` auf Ressourcen, die ArgoCD verwaltet
