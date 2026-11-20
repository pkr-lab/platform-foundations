# Lösung Modul 06

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
            ├── artifactory-pull-sealedsecret.yaml
            ├── ingress.yaml
            ├── sealedsecret.yaml
            └── service.yaml
```

Beispiele: [gitops-README.md](./gitops-README.md), [gitignore](./gitignore) (im Repo als `.gitignore` ablegen), [gitlab-ci.yml](./gitlab-ci.yml) (im Repo als `.gitlab-ci.yml` ablegen), [values-lab.yaml](./values-lab.yaml).

## Secrets verschlüsseln

```bash
helm install sealed-secrets artifactory/sealed-secrets --version <chart-version> -n kube-system \
  --set-string fullnameOverride=sealed-secrets-controller
kubectl create secret generic azubi-portal-secret -n azubi-portal \
  --from-literal=PASSWORD=supergeheim --dry-run=client -o yaml \
  | kubeseal --format yaml > gitops/apps/azubi-portal/templates/sealedsecret.yaml
kubectl create secret docker-registry artifactory-pull -n azubi-portal \
  --docker-server=<artifactory-host> \
  --docker-username=<technischer-benutzer> \
  --docker-password=<token> --dry-run=client -o yaml \
  | kubeseal --format yaml > gitops/apps/azubi-portal/templates/artifactory-pull-sealedsecret.yaml
git log -p | grep -c supergeheim
```

Die `SealedSecret`-Dateien dürfen ins Repo, weil nur der Controller im Cluster sie mit seinem privaten Schlüssel entschlüsseln kann. Der Name `PASSWORD` steht weiterhin lesbar darin, der Wert nicht.

Falls das Pull-Secret aus Modul 04 schon im Namespace existiert und nicht vom Sealed-Secrets-Controller verwaltet wird, verweigert der Controller das Überschreiben. Lösche es dann einmalig mit `kubectl delete secret artifactory-pull -n azubi-portal`, bevor ArgoCD synchronisiert.

## Antworten auf die Verständnisfragen

1. Bei GitOps ist Git die einzige Quelle für den gewünschten Zustand. Ein Controller im Cluster zieht ihn selbst. Bei `helm upgrade` vom Laptop hängt der Zustand davon ab, wer zuletzt von welchem Rechner mit welchen lokalen Dateien deployt hat.
2. Images sind große Binärdateien, die gebaut und nicht von Hand bearbeitet werden. Git ist dafür nicht gemacht; das Artifactory bietet Versionierung, Caching, Scans und Rechte für Binärdateien.
3. Jeder Klon des Repos enthält die komplette Historie. Wer das Repo jemals geklont hat, hat auch das Secret.
4. Ein Merge Request dokumentiert *was* und *warum* geändert wurde, lässt CI-Prüfungen laufen und ist ein natürlicher Punkt für eine zweite Meinung.
