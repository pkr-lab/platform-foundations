# Helm-Chart `azubi-portal`

Das Referenz-Chart liegt unter [`examples/azubi-portal-chart/`](../examples/azubi-portal-chart/). Es stellt eine statische Nginx-Seite bereit und wird ab Modul 03 verwendet.

## Dateien

| Datei | Inhalt |
| --- | --- |
| `Chart.yaml` | Name `azubi-portal`, Chart-Version, App-Version |
| `values.yaml` | Standardwerte (siehe unten) |
| `.helmignore` | Dateien, die beim `helm package` nicht ins Paket kommen |
| `templates/_helpers.tpl` | gemeinsame Labels (`azubi-portal.labels`) und Selector-Labels (`azubi-portal.selectorLabels`) |
| `templates/configmap.yaml` | ConfigMap `azubi-portal-html` mit der `index.html`, gerendert aus `welcomeMessage` |
| `templates/deployment.yaml` | Deployment `azubi-portal` mit Probes, Ressourcen und optionalem HTML-Volume |
| `templates/service.yaml` | Service `azubi-portal` |
| `templates/ingress.yaml` | optionaler Ingress (nur wenn `ingress.enabled: true`) |

## Werte

| Wert | Standard | Beschreibung |
| --- | --- | --- |
| `replicaCount` | `2` | Anzahl der Pods |
| `image.repository` | `docker.io/library/nginx` | Image ohne Tag |
| `image.tag` | `stable` | Image-Tag |
| `image.pullPolicy` | `IfNotPresent` | `Always`, `IfNotPresent` oder `Never` |
| `containerPort` | `80` | Port, auf dem der Container lauscht; `8080` für `nginx-unprivileged` |
| `imagePullSecrets` | `[]` | Liste von Secrets für private Registries, z. B. `[{name: artifactory-pull}]` |
| `service.type` | `ClusterIP` | Service-Typ |
| `service.port` | `80` | Port des Services |
| `welcomeMessage` | `Willkommen im Azubi-Portal` | Überschrift der HTML-Seite |
| `htmlFromConfigMap` | `true` | `true`: HTML kommt aus der ConfigMap. `false`: keine ConfigMap, das Image liefert seine eigene Seite |
| `resources` | Requests 10m/32Mi, Limits 100m/64Mi | CPU- und Memory-Requests/-Limits |
| `ingress.enabled` | `false` | Ingress anlegen |
| `ingress.className` | `traefik` | IngressClass des Controllers |
| `ingress.host` | `azubi-portal.localhost` | Hostname für die Ingress-Regel |

## Verhalten

- **Selector:** Deployment und Service wählen Pods über `app: azubi-portal`. Das ist kompatibel zum manuellen YAML aus Modul 02.
- **Labels:** Zusätzlich werden die empfohlenen Labels `app.kubernetes.io/*` und `helm.sh/chart` gesetzt.
- **Rollout bei Textänderung:** Die Annotation `checksum/config` enthält einen SHA-256-Hash der gerenderten ConfigMap. Ändert sich `welcomeMessage`, ändert sich der Hash und damit das Pod-Template, wodurch Kubernetes neue Pods ausrollt.
- **Probes:** readiness- und livenessProbe prüfen per HTTP `GET /` den benannten Port `http` (= `containerPort`).
- **Namespace:** Das Chart setzt keinen Namespace; er kommt aus `helm install -n` bzw. aus `destination.namespace` der ArgoCD-Application.

## Beispiele

```bash
helm install azubi-portal examples/azubi-portal-chart -n azubi-portal --create-namespace
helm upgrade azubi-portal examples/azubi-portal-chart -n azubi-portal --set ingress.enabled=true
helm template azubi-portal examples/azubi-portal-chart -f solutions/modul-04/values-lab.yaml
```

## Versionierung

Bei jeder Änderung am Chart wird `version` in `Chart.yaml` nach SemVer erhöht. Sobald das Chart in eine Registry gepusht wird, darf eine einmal veröffentlichte Version nicht mehr verändert werden.
