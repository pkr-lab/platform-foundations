# Lösung Modul 04

## Repository-Typen (Beispiel)

| Repo | Typ | Quelle |
| --- | --- | --- |
| `<docker-remote-repo>` | Remote | Docker Hub |
| `<docker-local-repo>` | Local | eigene Images |
| `<helm-repo>` | Virtual | bündelt die Remote-Repos der öffentlichen Chart-Repos |
| `<helm-oci-repo>` | Local | eigene Charts |

## Anmelden und Image auswählen

```bash
podman logout <artifactory-host>
podman login <artifactory-host> -u <benutzer>
podman pull <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:1.28.0
podman pull <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:stable
podman images --digests | grep nginx-unprivileged
```

Die Zugangsdaten liegen in `${XDG_RUNTIME_DIR}/containers/auth.json` – nur base64-kodiert. Wer deinen Benutzer in WSL nutzen kann, kann sie lesen.

## Image im Cluster

```bash
kubectl create secret docker-registry artifactory-pull -n azubi-portal \
  --docker-server=<artifactory-host> \
  --docker-username=<technischer-benutzer> \
  --docker-password=<token>
cd ~/k8s-lab/azubi-portal-chart
helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml
kubectl get pods -n azubi-portal -o jsonpath='{.items[*].spec.containers[*].image}'; echo
```

Eine passende `values-lab.yaml` steht in [values-lab.yaml](./values-lab.yaml). `<docker-remote-repo>` ist der Repository-Name aus dem kopierten Pull-Befehl.

Das dekodierte Pull-Secret enthält Benutzer und Token im Klartext. Wer im Namespace Secrets lesen darf, kann sich also mit dem technischen Benutzer am Artifactory anmelden – ein weiterer Grund für sparsame RBAC-Rechte (Modul 02).

## Helm-Charts

```bash
helm search repo artifactory/traefik --versions | head -n 5
helm pull artifactory/podinfo --version <chart-version> --untar -d ~/k8s-lab/charts
helm registry login <artifactory-host>
helm push ~/k8s-lab/packages/azubi-portal-0.3.1.tgz oci://<artifactory-host>/<helm-oci-repo>
helm install portal-oci oci://<artifactory-host>/<helm-oci-repo>/azubi-portal --version 0.3.1 -n portal-oci --create-namespace
```

Ein zweiter Push derselben Version wird abgelehnt oder überschreibt je nach Repo-Einstellung das Artefakt. Bei uns sollen veröffentlichte Versionen unveränderlich sein: Wer `0.3.1` installiert, soll immer exakt dasselbe bekommen. Für jede Änderung gibt es eine neue Version.

## Antworten auf die Verständnisfragen

1. Im Firmennetz ist das Artifactory der einzige erlaubte Weg. Es cacht die Artefakte, funktioniert ohne direkten Internetzugang, umgeht die Download-Limits von Docker Hub und prüft die Artefakte mit Xray auf Sicherheitslücken.
2. Ein Remote-Repo ist ein Cache für eine externe Quelle, ein Local-Repo speichert eigene Artefakte. Pushen kannst du nur in Local-Repos (bzw. in ein Virtual-Repo, das ein Local-Repo als Ziel hat).
3. `latest` und `stable` können jederzeit auf ein anderes Image zeigen. Mit einem festen Tag ist klar, welche Version läuft, und ein Deployment lässt sich reproduzieren.
4. Ein technischer Benutzer hat nur die nötigen Leserechte, lässt sich unabhängig von Personen verwalten und sperren, und dein persönliches Passwort landet nicht im Cluster.
5. Sonst könnte dieselbe Versionsnummer unterschiedliche Inhalte haben; Rollbacks und Fehlersuche wären nicht mehr verlässlich.
6. Der Mirror reicht für Images mit Original-Adresse (fremde Charts), wenn die Remote-Repos ohne Anmeldung lesbar sind. Ein Pull-Secret brauchst du, sobald das Repo eine Anmeldung verlangt, z. B. für eigene Images in `<docker-local-repo>`.
