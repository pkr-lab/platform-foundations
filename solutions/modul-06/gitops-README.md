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

- eigene Images: `<artifactory-host>/<docker-local-repo>/<app>:<version>`
- eigene Charts: `oci://<artifactory-host>/<helm-oci-repo>/<app>`
- öffentliche Charts: `https://<artifactory-host>/artifactory/api/helm/<helm-repo>`

## Workflow

1. Feature-Branch anlegen (`feature/<kurzbeschreibung>`)
2. Änderung durchführen und lokal mit `helm lint` und `helm template` prüfen
3. Merge Request nach `main` mit Beschreibung *was* und *warum*
4. Nach Review mergen – ArgoCD übernimmt den Rest
5. Rollback per `git revert`

## Regeln

- keine Klartext-Secrets, nur `SealedSecret`
- keine `latest`- oder `stable`-Tags, nur feste Versionen
- Images nur aus dem Artifactory
- kein direktes `kubectl apply` auf Ressourcen, die ArgoCD verwaltet
