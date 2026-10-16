# Repository-Struktur

```text
platform-foundations/
├── README.md                      Einstieg und Modulübersicht
├── AGENTS.md                      Konventionen für Autoren und KI-Assistenten
├── 01-grundlagen.md … 08-abschlussprojekt.md
│                                  Lab-Module in empfohlener Reihenfolge
├── kind.yaml                      Konfiguration des lokalen kind-Clusters "lab"
├── kubernetes-headlamp.yaml       optionale Cluster-Oberfläche (Modul 07)
├── examples/
│   └── azubi-portal-chart/        Referenz-Helm-Chart (Module 03–08)
├── solutions/                     Musterlösungen je Modul
├── docs/                          diese Dokumentation
│   ├── Fehlerbehebung.md          typische Fehler und Lösungen
│   └── planung/                   Planungs- und Design-Dokumente
├── .github/workflows/lint.yml     CI-Prüfungen
├── .markdownlint.yaml             Regeln für markdownlint
├── .yamllint.yaml                 Regeln für yamllint
└── .lychee.toml                   Konfiguration der Link-Prüfung
```

## Module

| Nr. | Datei | Thema |
| --- | --- | --- |
| 01 | `01-grundlagen.md` | Podman, kind, kubectl |
| 02 | `02-deployments-security.md` | Deployments, ConfigMaps/Secrets, RBAC, Pod Security, NetworkPolicy, Ingress |
| 03 | `03-helm-grundlagen.md` | Helm-Charts, Releases, Paketierung |
| 04 | `04-artifactory-artefakte.md` | JFrog Artifactory: Images über Packages finden und herunterladen |
| 05 | `05-gitlab-gitops-struktur.md` | GitOps-Repo-Struktur, Merge Requests, Secrets in Git |
| 06 | `06-argocd-gitops-flow.md` | ArgoCD, Sync, Drift, Self-Healing |
| 07 | `07-monitoring-betrieb.md` | Metrics Server, Prometheus/Grafana, Fehleranalyse, Headlamp |
| 08 | `08-abschlussprojekt.md` | Abschlussprojekt mit App-of-Apps |

Jedes Modul folgt demselben Aufbau: Kurzbeschreibung, Lernziele, Voraussetzungen, Theorie, Aufgaben, Bonus, „Du bist fertig, wenn …“, Verständnisfragen, Stolperfallen, Aufräumen, Weiterführend, Verweis auf die Musterlösung.

## Durchgängiges Beispiel

Die App `azubi-portal` zieht sich durch alle Module:

1. Modul 02: als einfaches YAML
2. Modul 03: als Helm-Chart
3. Modul 04: Image aus JFrog Artifactory
4. Modul 05: im GitOps-Repo
5. Modul 06: von ArgoCD verwaltet
6. Modul 07: überwacht mit Prometheus/Grafana
7. Modul 08: über App-of-Apps gebootstrapt

## CI-Prüfungen

Der Workflow `.github/workflows/lint.yml` läuft bei jedem Push und Pull Request:

| Job | Prüfung |
| --- | --- |
| `markdown` | markdownlint mit den Regeln aus `.markdownlint.yaml` |
| `yaml` | yamllint für alle YAML-Dateien außer Helm-Templates |
| `kubernetes` | `helm lint` für das Chart, `kubeconform` für alle Manifeste und das gerenderte Chart |
| `links` | prüft alle Links in Markdown-Dateien mit lychee; schlägt nicht fehl, sondern meldet nur |

Lokal lassen sich die Prüfungen so ausführen:

```bash
npx markdownlint-cli2 "**/*.md"
yamllint .
helm lint examples/azubi-portal-chart
helm template ci examples/azubi-portal-chart --set ingress.enabled=true | kubeconform -strict -summary
kubeconform -strict -summary -ignore-missing-schemas kubernetes-headlamp.yaml solutions/
```
