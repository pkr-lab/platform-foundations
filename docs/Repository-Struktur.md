# Repository-Struktur

```text
platform-foundations/
├── README.md                      Einstieg und Modulübersicht
├── AGENTS.md                      Konventionen für Autoren und KI-Assistenten
├── 01-grundlagen.md … 09-abschlussprojekt.md
│                                  Lab-Module in empfohlener Reihenfolge
├── kind.yaml                      Konfiguration des lokalen kind-Clusters "lab"
├── kubernetes-headlamp.yaml       optionale Cluster-Oberfläche (Modul 08)
├── examples/
│   └── azubi-portal-chart/        Referenz-Helm-Chart (Module 03–09)
├── solutions/                     Musterlösungen je Modul
├── docs/                          diese Dokumentation
│   ├── Artifactory.md             Platzhalter, Repos, Mirror, Pull-Secrets
│   ├── Fehlerbehebung.md          typische Fehler und Lösungen
│   └── planung/                   ursprüngliche Planungs- und Design-Dokumente
├── .github/workflows/lint.yml     CI-Prüfungen
├── .markdownlint.yaml             Regeln für markdownlint
├── .yamllint.yaml                 Regeln für yamllint
└── .lychee.toml                   Konfiguration der Link-Prüfung
```

## Module

| Nr. | Datei | Thema |
| --- | --- | --- |
| 01 | `01-grundlagen.md` | rootless Podman, erster Pull aus dem Artifactory, Registry-Mirror, kind, kubectl |
| 02 | `02-deployments-security.md` | Deployments, ConfigMaps/Secrets, RBAC, Pod Security, NetworkPolicy, Ingress |
| 03 | `03-helm-grundlagen.md` | Helm-Charts, Releases, Paketierung |
| 04 | `04-artifactory-artefakte.md` | JFrog Artifactory: Repo-Typen, Packages, Tokens, feste Tags, Pull-Secret, Helm-Charts, Chart-Upload, Xray |
| 05 | `05-container-images.md` | Containerfile, Layer, non-root, Multi-Stage, Push ins Artifactory, `kind load` |
| 06 | `06-gitlab-gitops-struktur.md` | GitOps-Repo-Struktur, Merge Requests, Sealed Secrets |
| 07 | `07-argocd-gitops-flow.md` | ArgoCD, Sync, Drift, Self-Healing |
| 08 | `08-monitoring-betrieb.md` | Metrics Server, Prometheus/Grafana, Fehleranalyse, Headlamp |
| 09 | `09-abschlussprojekt.md` | Abschlussprojekt mit App-of-Apps |

Die Module 01–08 folgen demselben Aufbau: Kurzbeschreibung, Lernziele, Voraussetzungen, Theorie, Aufgaben, Bonus, „Du bist fertig, wenn …“, Verständnisfragen, Stolperfallen, Aufräumen, Weiterführend, Verweis auf die Musterlösung. Modul 09 ist ein Projekt und hat stattdessen Projektbeschreibung, Projektphasen und eine Bewertungs-Checkliste.

## Durchgängiges Beispiel

Die App `azubi-portal` zieht sich durch alle Module:

1. Modul 02: als einfaches YAML mit Images aus dem Artifactory
2. Modul 03: als Helm-Chart
3. Modul 04: mit vollständiger Artifactory-Adresse und Pull-Secret; das Chart liegt im Artifactory
4. Modul 05: mit eigenem Image aus dem Artifactory
5. Modul 06: im GitOps-Repo, Secrets als `SealedSecret`
6. Modul 07: von ArgoCD verwaltet
7. Modul 08: überwacht mit Prometheus/Grafana
8. Modul 09: über App-of-Apps gebootstrapt

## Platzhalter

Firmenspezifische Werte stehen nie im Repo, sondern als Platzhalter in spitzen Klammern. Die vollständige Liste der Artifactory-Platzhalter steht in [Artifactory.md](./Artifactory.md#platzhalter). Weitere Platzhalter: `<dein-gitlab-repo-url>`, `<chart-version>`, `<version>` (kind-Node-Image), `<technischer-benutzer>`, `<token>`.

## CI-Prüfungen

Der Workflow `.github/workflows/lint.yml` läuft bei jedem Push und Pull Request:

| Job | Prüfung |
| --- | --- |
| `markdown` | markdownlint mit den Regeln aus `.markdownlint.yaml` |
| `yaml` | yamllint für alle YAML-Dateien außer Helm-Templates |
| `kubernetes` | `helm lint` für das Chart, `kubeconform` für alle Manifeste und das gerenderte Chart mit den Values-Dateien aus `solutions/` |
| `links` | prüft alle Links in Markdown-Dateien mit lychee; schlägt nicht fehl, sondern meldet nur |

Lokal lassen sich die Prüfungen so ausführen:

```bash
npx markdownlint-cli2 "**/*.md"
yamllint .
helm lint examples/azubi-portal-chart
helm template ci examples/azubi-portal-chart --set ingress.enabled=true | kubeconform -strict -summary
for f in solutions/modul-03/values-lab.yaml solutions/modul-04/values-lab.yaml solutions/modul-05/values-lab.yaml solutions/modul-06/values-lab.yaml; do
  helm template ci examples/azubi-portal-chart -f "$f" | kubeconform -strict -summary
done
kubeconform -strict -summary -ignore-missing-schemas kubernetes-headlamp.yaml solutions/modul-01 solutions/modul-02/azubi-portal.yaml solutions/modul-02/np-test.yaml solutions/modul-07 solutions/modul-08 solutions/modul-09
```

Values-Dateien, `traefik-values.yaml` und `gitlab-ci.yml` sind keine Kubernetes-Manifeste und werden deshalb nicht direkt mit kubeconform geprüft.
