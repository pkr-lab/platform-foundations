# Helm-Chart `azubi-portal`

Das Referenz-Chart liegt unter [`examples/azubi-portal-chart/`](../examples/azubi-portal-chart/). Es stellt eine statische Nginx-Seite bereit, läuft als normaler Benutzer und wird ab Modul 03 verwendet. Aktuelle Chart-Version: `0.3.0`.

## Dateien

| Datei | Inhalt |
| --- | --- |
| `Chart.yaml` | Name `azubi-portal`, Chart-Version, App-Version |
| `values.yaml` | Standardwerte (siehe unten) |
| `.helmignore` | Dateien, die beim `helm package` nicht ins Paket kommen |
| `templates/_helpers.tpl` | gemeinsame Labels (`azubi-portal.labels`) und Selector-Labels (`azubi-portal.selectorLabels`) |
| `templates/configmap.yaml` | ConfigMap `azubi-portal-html` mit der `index.html`, gerendert aus `welcomeMessage` |
| `templates/deployment.yaml` | Deployment `azubi-portal` mit Security-Kontext, Probes, Ressourcen, optionalem HTML-Volume und optionalem Secret |
| `templates/service.yaml` | Service `azubi-portal` |
| `templates/ingress.yaml` | optionaler Ingress (nur wenn `ingress.enabled: true`) |

## Werte

| Wert | Standard | Beschreibung |
| --- | --- | --- |
| `replicaCount` | `2` | Anzahl der Pods |
| `image.repository` | `docker.io/nginxinc/nginx-unprivileged` | Image ohne Tag; im Lab über den Registry-Mirror aus dem Artifactory, in eigenen Values die Artifactory-Adresse |
| `image.tag` | `"1.28.0"` | fester Image-Tag |
| `image.pullPolicy` | `IfNotPresent` | `Always`, `IfNotPresent` oder `Never` (`Never` für Images aus `kind load`) |
| `containerPort` | `8080` | Port, auf dem der Container lauscht; `nginx-unprivileged` nutzt 8080 |
| `imagePullSecrets` | `[]` | Liste von Secrets für das Artifactory, z. B. `[{name: artifactory-pull}]` |
| `podSecurityContext` | `runAsNonRoot: true`, `seccompProfile: RuntimeDefault` | Security-Kontext für den Pod |
| `securityContext` | `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]` | Security-Kontext für den Container |
| `service.type` | `ClusterIP` | Service-Typ |
| `service.port` | `80` | Port des Services |
| `welcomeMessage` | `Willkommen im Azubi-Portal` | Überschrift der HTML-Seite |
| `htmlFromConfigMap` | `true` | `true`: HTML kommt aus der ConfigMap. `false`: keine ConfigMap, das Image liefert seine eigene Seite (Modul 05) |
| `existingSecret` | `""` | Name eines vorhandenen Secrets, dessen Schlüssel als Umgebungsvariablen in den Container kommen (z. B. aus einem `SealedSecret`, Modul 06) |
| `resources` | Requests 10m/32Mi, Limits 100m/64Mi | CPU- und Memory-Requests/-Limits; Requests dürfen nicht größer als Limits sein |
| `ingress.enabled` | `false` | Ingress anlegen |
| `ingress.className` | `traefik` | IngressClass des Controllers |
| `ingress.host` | `azubi-portal.localhost` | Hostname für die Ingress-Regel |

## Verhalten

- **Selector:** Deployment und Service wählen Pods über `app: azubi-portal`. Das ist kompatibel zum manuellen YAML aus Modul 02.
- **Labels:** Zusätzlich werden die empfohlenen Labels `app.kubernetes.io/*` und `helm.sh/chart` gesetzt.
- **Security:** Die Standardwerte erfüllen den Pod Security Standard `restricted`. Das Image muss dafür eine numerische User-ID haben (wie `nginx-unprivileged` mit `101`).
- **Rollout bei Textänderung:** Die Annotation `checksum/config` enthält einen SHA-256-Hash der gerenderten ConfigMap. Ändert sich `welcomeMessage`, ändert sich der Hash und damit das Pod-Template, wodurch Kubernetes neue Pods ausrollt.
- **Probes:** readiness- und livenessProbe prüfen per HTTP `GET /` den benannten Port `http` (= `containerPort`).
- **Secret:** Ist `existingSecret` gesetzt, bindet das Deployment das Secret per `envFrom` ein. Das Secret selbst legt das Chart nicht an.
- **Namespace:** Das Chart setzt keinen Namespace; er kommt aus `helm install -n` bzw. aus `destination.namespace` der ArgoCD-Application.

## Beispiele

```bash
helm install azubi-portal examples/azubi-portal-chart -n azubi-portal --create-namespace
helm upgrade azubi-portal examples/azubi-portal-chart -n azubi-portal --set ingress.enabled=true
helm template azubi-portal examples/azubi-portal-chart -f solutions/modul-04/values-lab.yaml
helm template azubi-portal examples/azubi-portal-chart -f solutions/modul-05/values-lab.yaml
```

## Versionierung

Bei jeder Änderung am Chart wird `version` in `Chart.yaml` nach SemVer erhöht. Sobald das Chart ins Artifactory hochgeladen ist (Modul 04), darf eine einmal veröffentlichte Version nicht mehr verändert werden.

| Version | Änderung |
| --- | --- |
| `0.3.0` | Standard-Image `nginx-unprivileged:1.28.0` auf Port 8080, `podSecurityContext`/`securityContext`, `existingSecret` |
| `0.2.0` | Ingress, Pull-Secrets, `checksum/config`, `htmlFromConfigMap` |
