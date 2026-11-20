# JFrog Artifactory im Lab

Bei uns gibt es genau einen Weg zu Container-Images und Helm-Charts: das hauseigene **JFrog Artifactory**. Direkte Downloads von Docker Hub, quay.io, ghcr.io oder registry.k8s.io sind im Firmennetz gesperrt. Diese Seite fasst zusammen, wie das Lab das Artifactory nutzt. Eingeführt wird es in Modul 01, vertieft in [Modul 04](../04-artifactory-artefakte.md) und [Modul 05](../05-container-images.md).

## Platzhalter

In allen Modulen stehen Platzhalter in spitzen Klammern. Die Werte bekommst du von deinem Ausbilder. Trag sie dir am besten gleich zu Beginn in eine eigene Notiz ein.

| Platzhalter | Bedeutung | Beispiel für den Aufbau |
| --- | --- | --- |
| `<artifactory-host>` | Hostname des Artifactory, ohne `https://` | `artifactory.example.com` |
| `<docker-remote-repo>` | Remote- oder virtuelles Docker-Repo, das Docker Hub spiegelt | `docker-remote` |
| `<quay-remote-repo>` | Remote-Repo, das quay.io spiegelt | `quay-remote` |
| `<ghcr-remote-repo>` | Remote-Repo, das ghcr.io spiegelt | `ghcr-remote` |
| `<k8s-remote-repo>` | Remote-Repo, das registry.k8s.io spiegelt | `k8s-remote` |
| `<docker-local-repo>` | lokales Docker-Repo für eigene Images (Modul 05) | `docker-local` |
| `<helm-repo>` | virtuelles Helm-Repo, das die öffentlichen Chart-Repos bündelt | `helm` |
| `<helm-oci-repo>` | OCI-Repo für eigene Helm-Charts (Modul 04) | `helm-oci-local` |

Die Spalte „Beispiel“ zeigt nur, wie die Namen typischerweise aussehen – die echten Namen können anders lauten.

## Repository-Typen

| Typ | Was es ist | Typische Nutzung im Lab |
| --- | --- | --- |
| **Remote** | Zwischenspeicher (Cache) für eine externe Quelle, z. B. Docker Hub. Beim ersten Pull holt Artifactory das Artefakt aus dem Internet und hebt eine Kopie auf. | öffentliche Images wie `nginx`, `traefik`, `kindest/node` |
| **Local** | Speicher für Artefakte, die bei uns entstehen. Nur hierhin kann man pushen. | dein eigenes Image `azubi-portal` (Modul 05), dein Chart (Modul 04) |
| **Virtual** | eine Adresse, hinter der mehrere Remote- und Local-Repos zusammengefasst sind | ein Helm-Repo für alle öffentlichen Charts |

## Adressen

| Artefakt | Adresse außerhalb der Firma | Adresse über Artifactory |
| --- | --- | --- |
| offizielles Image | `docker.io/library/nginx:1.28.0` | `<artifactory-host>/<docker-remote-repo>/nginx:1.28.0` |
| Image eines Herstellers | `docker.io/nginxinc/nginx-unprivileged:1.28.0` | `<artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:1.28.0` |
| Image von ghcr.io | `ghcr.io/yannh/kubeconform:v0.6.7` | `<artifactory-host>/<ghcr-remote-repo>/yannh/kubeconform:v0.6.7` |
| kind-Node-Image | `docker.io/kindest/node:<version>` | `<artifactory-host>/<docker-remote-repo>/kindest/node:<version>` |
| eigenes Image | – | `<artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0` |
| Helm-Repo | `https://traefik.github.io/charts` | `https://<artifactory-host>/artifactory/api/helm/<helm-repo>` |
| eigenes Chart | – | `oci://<artifactory-host>/<helm-oci-repo>/azubi-portal` |

Du musst dir diese Muster nicht merken. Artifactory zeigt dir unter **Packages** bei jeder Version den fertigen Pull-Befehl, und unter **Set Me Up** (bzw. „Set Up Client“) steht für jedes Repo, wie du es mit Podman oder Helm verwendest. Artifactory zeigt immer `docker`-Befehle; ersetze `docker` einfach durch `podman`.

## Anmelden

- **Web-Oberfläche:** `https://<artifactory-host>/` mit deinem Firmenkonto.
- **Token statt Passwort:** Wenn euer Artifactory es erlaubt, erzeugst du unter deinem Profil („Edit Profile“) ein **Identity Token** und verwendest es überall dort, wo nach einem Passwort gefragt wird. Ein Token kannst du jederzeit widerrufen, ohne dein Passwort zu ändern.
- **Podman:**

  ```bash
  podman login <artifactory-host>
  podman logout <artifactory-host>
  ```

  Rootless Podman speichert die Zugangsdaten unter `${XDG_RUNTIME_DIR}/containers/auth.json`.

- **Helm-Repo:**

  ```bash
  helm repo add artifactory https://<artifactory-host>/artifactory/api/helm/<helm-repo> --username <benutzer> --password-stdin
  ```

  Ohne Anmeldung reicht `helm repo add artifactory https://<artifactory-host>/artifactory/api/helm/<helm-repo>`.

- **Helm-OCI-Repo:** `helm registry login <artifactory-host>`

Zugangsdaten und Tokens gehören **nie** in ein Git-Repository, auch nicht in Values-Dateien.

## Helm-Charts aus dem Artifactory

Alle öffentlichen Charts des Labs (Traefik, podinfo, Metrics Server, kube-prometheus-stack, Sealed Secrets, ArgoCD) kommen über das virtuelle Repo `<helm-repo>`. Es wird einmalig in Modul 02 hinzugefügt und heißt lokal `artifactory`:

```bash
helm repo add artifactory https://<artifactory-host>/artifactory/api/helm/<helm-repo>
helm repo update
helm search repo artifactory/traefik --versions | head -n 5
helm install traefik artifactory/traefik --version <chart-version> -n traefik --create-namespace
```

Gib bei `helm install` immer `--version` an. Ohne Angabe nimmt Helm die neueste Version, und das Lab wäre nicht mehr reproduzierbar. Notiere dir, welche Version du installiert hast.

Falls euer Artifactory kein virtuelles Helm-Repo hat, gibt es pro öffentlichem Chart-Repo ein eigenes Remote-Repo. Dann fügst du jedes einzeln mit `helm repo add` hinzu und passt den Namen vor dem `/` an.

Eigene Charts lädst du in ein OCI-Repo hoch (Modul 04):

```bash
helm registry login <artifactory-host>
helm push azubi-portal-0.3.1.tgz oci://<artifactory-host>/<helm-oci-repo>
```

Hat euer Artifactory kein OCI-Helm-Repo, zeigt dir **Set Me Up** beim lokalen Helm-Repo den passenden Upload-Befehl.

## Registry-Mirror für den kind-Cluster

Im kind-Cluster zieht nicht Podman die Images, sondern **containerd** im Node-Container. containerd kennt dein `podman login` nicht und würde Images wie `docker.io/traefik/traefik` direkt aus dem Internet laden – das ist gesperrt. Fremde Helm-Charts verweisen aber fast immer auf die Original-Registries.

Die Lösung ist ein **Registry-Mirror**: Für jede Original-Registry legst du eine Datei `/etc/containerd/certs.d/<registry>/hosts.toml` an, die containerd auf das passende Remote-Repo im Artifactory umleitet. `kind.yaml` hängt das Verzeichnis in den Node ein (siehe [kind-Konfiguration.md](./kind-Konfiguration.md)).

| Registry | Verzeichnis | Remote-Repo |
| --- | --- | --- |
| Docker Hub | `/etc/containerd/certs.d/docker.io/` | `<docker-remote-repo>` |
| quay.io | `/etc/containerd/certs.d/quay.io/` | `<quay-remote-repo>` |
| ghcr.io | `/etc/containerd/certs.d/ghcr.io/` | `<ghcr-remote-repo>` |
| registry.k8s.io | `/etc/containerd/certs.d/registry.k8s.io/` | `<k8s-remote-repo>` |

Beispiel für Docker Hub:

```toml
server = "https://docker.io"

[host."https://<artifactory-host>/v2/<docker-remote-repo>"]
  capabilities = ["pull", "resolve"]
  override_path = true
```

- `server` ist die Original-Registry. Sie wird nur genutzt, wenn der Mirror nicht antwortet.
- `host` ist das Artifactory-Repo. `override_path = true` sagt containerd, dass der Pfad `/v2/<repo>` bereits Teil der Adresse ist.
- `capabilities` erlaubt nur Lesen.

Die URL passt zur Artifactory-Zugriffsmethode „Repository Path“. Nutzt euer Artifactory eine andere Methode (z. B. „Subdomain“), sieht die URL anders aus – frag in dem Fall deinen Ausbilder. Format-Referenz: [containerd – Registry Configuration](https://github.com/containerd/containerd/blob/main/docs/hosts.md).

containerd liest die Dateien bei jedem Pull neu. Du musst den Cluster nach einer Änderung nicht neu erstellen.

Die Befehle zum Anlegen aller vier Dateien stehen in Modul 01, Aufgabe 3.

Verlangt euer Artifactory auch für Remote-Repos eine Anmeldung, reicht der Mirror allein nicht. Dann klärt dein Ausbilder mit dir, ob ein technischer Benutzer über das Feld `header` in der `hosts.toml` eingetragen wird. Eine solche Datei enthält ein Token und darf nicht ins Git.

## Zugriff aus dem Cluster: Pull-Secret

Steht in einem Manifest die vollständige Artifactory-Adresse (z. B. `<artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0`) und braucht das Repo eine Anmeldung, bekommt der Pod die Zugangsdaten über ein **Pull-Secret**:

```bash
kubectl create secret docker-registry artifactory-pull -n azubi-portal \
  --docker-server=<artifactory-host> \
  --docker-username=<technischer-benutzer> \
  --docker-password=<token>
```

Im Chart `azubi-portal` verweist der Wert `imagePullSecrets` darauf:

```yaml
imagePullSecrets:
  - name: artifactory-pull
```

Ein Pull-Secret gilt nur in seinem Namespace. Im GitOps-Repo liegt es nur verschlüsselt als `SealedSecret` (Modul 06).

## Welche Adresse wann?

| Situation | Weg |
| --- | --- |
| eigene Manifeste und eigene Values-Dateien | immer die vollständige Artifactory-Adresse aus **Packages** |
| fremde Helm-Charts mit vielen Images | Registry-Mirror, Values bleiben unverändert |
| eigenes Image | pushen nach `<docker-local-repo>`, Adresse aus **Packages** |

Die Defaults im Referenz-Chart `examples/azubi-portal-chart` zeigen auf `docker.io`, damit das Chart überall funktioniert. Im Lab kommen sie über den Mirror trotzdem aus dem Artifactory. In deiner `values-lab.yaml` trägst du ab Modul 04 die Artifactory-Adresse ein.

## Sicherheits-Scans (Xray)

Artifactory prüft Images und Pakete mit **JFrog Xray** auf bekannte Sicherheitslücken (CVEs) und Lizenzprobleme. In der Ansicht einer Version unter **Packages** siehst du die Ergebnisse. Je nach Regel blockiert Artifactory den Download von Artefakten mit kritischen Lücken. Der Pull scheitert dann mit `403 Forbidden` und einem Hinweis auf eine Policy. In dem Fall: andere, aktuellere Version wählen oder den Ausbilder fragen.

## Werkzeuge über Artifactory

Auch Binaries wie `kind`, `kubectl`, `helm` oder `kubeseal` kommen im Firmennetz idealerweise über das Artifactory, z. B. über ein Generic-Remote-Repo. Die Adressen nennt dir dein Ausbilder.
