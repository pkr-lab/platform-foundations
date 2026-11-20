# kind-Konfiguration (`kind.yaml`)

Die Datei [`kind.yaml`](../kind.yaml) beschreibt den lokalen Cluster für das Lab. Er läuft mit **rootless Podman**, also ohne `sudo`. Das Node-Image kommt aus dem Artifactory und wird beim Erstellen mit `--image` angegeben:

```bash
kind create cluster --name lab --config kind.yaml \
  --image <artifactory-host>/<docker-remote-repo>/kindest/node:<version>
```

Welche Version von `kindest/node` zu deiner kind-Version passt, steht in den [Release Notes von kind](https://github.com/kubernetes-sigs/kind/releases). Das Image steht bewusst nicht in `kind.yaml`, damit die Datei keine firmenspezifische Adresse enthält.

## Felder

| Feld | Wert | Bedeutung |
| --- | --- | --- |
| `networking.ipFamily` | `ipv4` | Cluster nur mit IPv4 betreiben; verhindert IPv6-Probleme unter WSL/Podman (siehe [Fehlerbehebung.md](./Fehlerbehebung.md#ipv6-probleme-mit-kind-und-podman)) |
| `nodes[0].role` | `control-plane` | ein einzelner Node, der zugleich Control Plane und Worker ist |
| `nodes[0].labels.ingress-ready` | `"true"` | Markierung, auf welchem Node der Ingress-Controller laufen soll |
| `extraPortMappings` 80 → 8080 | TCP | HTTP-Traffic vom Host an den Ingress-Controller im Node |
| `extraPortMappings` 443 → 8443 | TCP | HTTPS-Traffic vom Host an den Ingress-Controller im Node |
| `extraMounts` `/etc/ssl/certs` | – | CA-Zertifikate des Hosts, damit der Node dem Artifactory mit Firmen-CA vertraut |
| `extraMounts` `/etc/containerd/certs.d` | – | Registry-Mirror-Konfiguration für containerd: leitet docker.io, quay.io, ghcr.io und registry.k8s.io auf das Artifactory um |

Die Host-Ports 8080 und 8443 liegen über 1024. Das ist für rootless Podman nötig, denn ein normaler Benutzer darf keine niedrigeren Ports belegen.

## Voraussetzungen auf dem Host

- rootless Podman mit cgroup v2 und systemd-Delegation (Modul 01, Aufgabe 1)
- `KIND_EXPERIMENTAL_PROVIDER=podman` ist gesetzt
- Beide Mount-Quellen existieren, sonst schlägt `kind create cluster` fehl:

  ```bash
  sudo mkdir -p /etc/containerd/certs.d
  ```

- Die Firmen-CA ist im System von WSL installiert (`/usr/local/share/ca-certificates/` und `sudo update-ca-certificates`), damit sie unter `/etc/ssl/certs` auftaucht.
- Die Host-Ports 8080 und 8443 sind frei.

## Registry-Mirror über `certs.d`

containerd liest unter `/etc/containerd/certs.d/<registry>/hosts.toml` Umleitungen für Registries. So kommen auch Images, die in fremden Helm-Charts mit ihrer Original-Adresse stehen, über das Artifactory. Aufbau der Dateien und Befehle: [Artifactory.md](./Artifactory.md#registry-mirror-für-den-kind-cluster) und Modul 01, Aufgabe 3.

Damit containerd das Verzeichnis auswertet, muss in seiner Konfiguration `config_path` auf `/etc/containerd/certs.d` zeigen. Bei aktuellen kind-Node-Images (ab kind v0.27) ist das voreingestellt; bei älteren Versionen siehe [kind – Local Registry](https://kind.sigs.k8s.io/docs/user/local-registry/).

Prüfen, ob die Dateien im Node ankommen:

```bash
podman exec lab-control-plane ls /etc/containerd/certs.d
```

## Änderungen an `kind.yaml`

Der Cluster-Name wird beim Erstellen mit `--name lab` gesetzt; der kubectl-Kontext heißt dadurch `kind-lab`. Ohne `--name` heißt der Cluster `kind`, und alle Befehle mit `--name lab` finden ihn nicht.

Die Konfiguration wird nur beim Erstellen des Clusters gelesen. Nach einer Änderung muss der Cluster neu erstellt werden:

```bash
kind delete cluster --name lab
kind create cluster --name lab --config kind.yaml \
  --image <artifactory-host>/<docker-remote-repo>/kindest/node:<version>
```

Änderungen an den `hosts.toml`-Dateien brauchen dagegen keinen neuen Cluster.

## Nach einem Neustart von WSL

Rootless Podman startet den Node-Container nicht automatisch neu:

```bash
podman start lab-control-plane
kubectl get nodes
```
