# kind-Konfiguration (`kind.yaml`)

Die Datei [`kind.yaml`](../kind.yaml) beschreibt den lokalen Cluster für das Lab.

```bash
kind create cluster --name lab --config kind.yaml
```

## Felder

| Feld | Wert | Bedeutung |
| --- | --- | --- |
| `networking.ipFamily` | `ipv4` | Cluster nur mit IPv4 betreiben; verhindert IPv6-Probleme unter WSL/Podman (siehe [Fehlerbehebung.md](./Fehlerbehebung.md#ipv6-probleme-mit-kind-und-podman)) |
| `nodes[0].role` | `control-plane` | ein einzelner Node, der zugleich Control Plane und Worker ist |
| `nodes[0].labels.ingress-ready` | `"true"` | Markierung, auf welchem Node der Ingress-Controller laufen soll |
| `extraPortMappings` 80 → 8080 | TCP | HTTP-Traffic vom Host an den Ingress-Controller im Node |
| `extraPortMappings` 443 → 8443 | TCP | HTTPS-Traffic vom Host an den Ingress-Controller im Node |
| `extraMounts` `/etc/ssl/certs` | – | CA-Zertifikate des Hosts, damit der Node interne Registries mit Firmen-CA vertraut |
| `extraMounts` `/etc/containerd/certs.d` | – | Registry-Konfiguration für containerd, z. B. Mirror auf Artifactory |

## Voraussetzungen auf dem Host

- Beide Mount-Quellen müssen existieren, sonst schlägt `kind create cluster` fehl:

  ```bash
  sudo mkdir -p /etc/containerd/certs.d
  ```

- Die Firmen-CA muss im System von WSL installiert sein (`/usr/local/share/ca-certificates/` und `sudo update-ca-certificates`), damit sie unter `/etc/ssl/certs` auftaucht.
- Die Host-Ports 8080 und 8443 müssen frei sein.

## Registry-Mirror über `certs.d`

containerd liest unter `/etc/containerd/certs.d/<registry>/hosts.toml` Umleitungen für Registries. Eine Datei `/etc/containerd/certs.d/docker.io/hosts.toml` kann z. B. alle Docker-Hub-Pulls an ein Artifactory-Remote-Repo umleiten. Format: [containerd – Registry Configuration](https://github.com/containerd/containerd/blob/main/docs/hosts.md). Die genauen Adressen hängen von der Artifactory-Konfiguration ab (siehe Modul 04).

Damit containerd das Verzeichnis auswertet, muss in seiner Konfiguration `config_path` auf `/etc/containerd/certs.d` zeigen. Ob das im verwendeten kind-Node-Image bereits voreingestellt ist, hängt von der kind-Version ab; siehe [kind – Local Registry](https://kind.sigs.k8s.io/docs/user/local-registry/).

## Änderungen an `kind.yaml`

Der Cluster-Name wird beim Erstellen mit `--name lab` gesetzt; der kubectl-Kontext heißt dadurch `kind-lab`.

Die Konfiguration wird nur beim Erstellen des Clusters gelesen. Nach einer Änderung muss der Cluster neu erstellt werden:

```bash
kind delete cluster --name lab
kind create cluster --name lab --config kind.yaml
```
