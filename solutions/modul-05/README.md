# Lösung Modul 05

## Erwartete Struktur im GitLab-Repo

```text
gitops/
├── README.md
├── .gitignore
├── cluster/
│   └── argocd-apps/
│       └── azubi-portal.yaml
└── apps/
    └── azubi-portal/
        ├── Chart.yaml
        ├── values.yaml
        ├── values-lab.yaml
        └── templates/
            ├── _helpers.tpl
            ├── configmap.yaml
            ├── deployment.yaml
            ├── ingress.yaml
            ├── sealedsecret.yaml
            └── service.yaml
```

Beispiele: [gitops-README.md](./gitops-README.md), [gitignore](./gitignore) (im Repo als `.gitignore` ablegen), [gitlab-ci.yml](./gitlab-ci.yml) (im Repo als `.gitlab-ci.yml` ablegen).

## Antworten auf die Verständnisfragen

1. Bei GitOps ist Git die einzige Quelle für den gewünschten Zustand. Ein Controller im Cluster zieht ihn selbst. Bei `helm upgrade` vom Laptop hängt der Zustand davon ab, wer zuletzt von welchem Rechner mit welchen lokalen Dateien deployt hat.
2. Images sind große Binärdateien, die gebaut und nicht von Hand bearbeitet werden. Git ist dafür nicht gemacht; das Artifactory bietet Versionierung, Caching, Scans und Rechte für Binärdateien.
3. Jeder Klon des Repos enthält die komplette Historie. Wer das Repo jemals geklont hat, hat auch das Secret.
4. Ein Merge Request dokumentiert *was* und *warum* geändert wurde, lässt CI-Prüfungen laufen und ist ein natürlicher Punkt für eine zweite Meinung.
