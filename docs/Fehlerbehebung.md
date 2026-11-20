# Fehlerbehebung

Diese Seite sammelt typische Fehler im Lab und wie man sie behebt. Bei einem neuen Problem gilt immer zuerst:

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

Das Lab nutzt **rootless Podman**. Alle `podman`- und `kind`-Befehle laufen ohne `sudo`. `sudo` brauchst du nur für Dateien unter `/etc`.

## kind mit rootless Podman

| Symptom | Ursache | Lösung |
| --- | --- | --- |
| `running kind with rootless provider requires cgroup v2` | WSL nutzt noch cgroup v1 | in Windows in `%UserProfile%\.wslconfig` unter `[wsl2]` die Zeile `kernelCommandLine = cgroup_no_v1=all` ergänzen, `wsl --shutdown`, danach `stat -fc %T /sys/fs/cgroup` prüfen (`cgroup2fs`) |
| Fehler zu fehlenden cgroup-Controllern (`cpu`, `memory`, `pids`) | systemd delegiert die Controller nicht an deinen Benutzer | Delegation aus Modul 01, Aufgabe 1, Schritt 5 einrichten und WSL neu starten |
| `kind create cluster` bricht trotz Delegation mit cgroup-Fehlern ab | kind läuft nicht in einer eigenen systemd-Scope | einmalig `systemd-run --scope --user kind create cluster …` versuchen |
| Fehler mit `iptables` oder `ip6tables` beim Start des Nodes | benötigte Kernel-Module nicht geladen | `sudo modprobe ip_tables iptable_nat ip6_tables ip6table_nat`; dauerhaft über eine Datei in `/etc/modules-load.d/` (siehe [kind – Rootless](https://kind.sigs.k8s.io/docs/user/rootless/)) |
| kind sucht Docker statt Podman | Provider nicht gesetzt | `export KIND_EXPERIMENTAL_PROVIDER=podman` (dauerhaft in `~/.bashrc`) |
| Fehler beim Mounten von `/etc/containerd/certs.d` | Verzeichnis fehlt auf dem Host | `sudo mkdir -p /etc/containerd/certs.d` |
| `kind get clusters` zeigt nichts | Cluster mit `sudo` erstellt oder ohne `--name lab` (heißt dann `kind`) | ohne `sudo` arbeiten; `kind get clusters` und `sudo kind get clusters` vergleichen, ggf. Cluster neu anlegen |
| `address already in use` für 8080/8443 | anderer Prozess nutzt die Ports | mit `ss -ltnp` den Prozess finden und beenden |
| `connection refused` bei `kubectl` nach WSL-Neustart | Node-Container gestoppt | `podman start lab-control-plane` |
| `kubectl` findet den Cluster nicht | kubeconfig fehlt oder anderer Kontext aktiv | `kind export kubeconfig --name lab`, danach `kubectl config current-context` (`kind-lab`) |
| Probleme mit IPv6-Adressen | IPv6 im Podman-Netzwerk `kind` | siehe Abschnitt „IPv6-Probleme mit kind und Podman“ |

## IPv6-Probleme mit kind und Podman

### Symptome

- `kind create cluster` bricht ab oder hängt beim Start der Control Plane
- Fehlermeldungen mit IPv6-Adressen (z. B. `fc00:…`, `::1`) beim Erstellen des Netzwerks oder des Nodes
- Pods können keine Images ziehen oder externe Adressen nicht erreichen, obwohl das Netzwerk in WSL funktioniert
- `kubectl` erreicht den API-Server nicht zuverlässig

### Ursache

kind legt beim ersten Start ein Podman-Netzwerk mit dem Namen `kind` an. Je nach Umgebung bekommt dieses Netzwerk zusätzlich ein IPv6-Subnetz. Unter WSL bzw. im Firmennetz funktioniert IPv6 oft nicht vollständig, und Cluster-Komponenten versuchen dann, über IPv6 zu kommunizieren.

### Lösung

1. Prüfen, dass in der `kind.yaml` IPv4 festgelegt ist (`networking.ipFamily: ipv4`).

2. Den bestehenden Cluster löschen, weil die Netzwerk-Einstellung nur beim Erstellen gelesen wird:

   ```bash
   kind delete cluster --name lab
   ```

3. Das alte Podman-Netzwerk `kind` löschen. Es enthält noch die IPv6-Konfiguration und wird sonst wiederverwendet:

   ```bash
   podman network ls
   podman network rm kind
   ```

   Falls `network is being used` gemeldet wird, laufen noch Container im Netzwerk. Diese mit `podman ps -a --filter network=kind` finden und mit `podman rm -f <name>` entfernen.

4. Das Netzwerk neu anlegen, diesmal ohne IPv6:

   ```bash
   podman network create kind
   podman network inspect kind | grep -i ipv6
   ```

   Die Ausgabe sollte `"ipv6_enabled": false` zeigen.

5. Den Cluster neu erstellen. kind schreibt die kubeconfig automatisch nach `~/.kube/config`:

   ```bash
   kind create cluster --name lab --config kind.yaml \
     --image <artifactory-host>/<docker-remote-repo>/kindest/node:<version>
   kubectl get nodes -o wide
   ```

   In der Spalte `INTERNAL-IP` sollte jetzt nur eine IPv4-Adresse stehen.

> Hinweis: Wird der Cluster gelöscht, sind alle darin installierten Ressourcen weg. Mit GitOps stellt ArgoCD die Anwendungen aus Git wieder her – aber nur, was in Git steht. Traefik, Sealed Secrets, ArgoCD selbst und das Repo-Secret für GitLab musst du neu installieren. Der Sealed-Secrets-Controller erzeugt dabei einen **neuen Schlüssel**: Die alten `SealedSecret`-Dateien im Repo lassen sich dann nicht mehr entschlüsseln. Sichere den Schlüssel vorher (Modul 06, Stolperfallen) oder verschlüssele die Secrets neu.

## WSL und Podman

| Symptom | Ursache | Lösung |
| --- | --- | --- |
| `podman: command not found` | Podman nicht installiert | `sudo apt update && sudo apt install -y podman` |
| Podman-Version 3.x | Ubuntu 22.04 bringt eine alte Version mit | Ubuntu 24.04 verwenden (Podman 4.9) |
| Warnungen zu `cgroupv2` oder `systemd` | systemd in WSL nicht aktiv | in `/etc/wsl.conf` unter `[boot]` `systemd=true` setzen, in Windows `wsl --shutdown` |
| `cannot find UID/GID for user` | keine Einträge in `/etc/subuid` und `/etc/subgid` | `sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER`, danach `podman system migrate` |
| Seite im Windows-Browser nicht erreichbar | Port-Weiterleitung von WSL | in WSL mit `curl localhost:<port>` testen, ggf. WSL neu starten |
| `x509: certificate signed by unknown authority` | Firmen-CA fehlt in WSL | CA als `.crt` nach `/usr/local/share/ca-certificates/` kopieren, `sudo update-ca-certificates` |
| `short-name … did not resolve to an alias` | Image ohne Registry angegeben | immer die vollständige Artifactory-Adresse verwenden |

## Kubernetes allgemein

| Symptom | Erster Befehl |
| --- | --- |
| Pod startet nicht | `kubectl describe pod <name> -n <ns>` (Abschnitt Events) |
| Container stürzt ab | `kubectl logs <pod> -n <ns> --previous` |
| Service liefert nichts | `kubectl get endpoints <service> -n <ns>` – leer heißt: Selector oder Readiness passt nicht |
| Ingress liefert 404 | Host-Name und `ingressClassName` prüfen, `kubectl logs -n traefik deploy/traefik` |
| `Forbidden` | `kubectl auth can-i <verb> <ressource> --as=<identität> -n <ns>` |
| Deployment wird abgelehnt: `must be less than or equal to … limit` | Requests sind größer als Limits – beide Werte anpassen |

## Artifactory und Images

| Symptom | Ursache | Lösung |
| --- | --- | --- |
| `unauthorized` bzw. `401` beim Pull mit Podman | nicht angemeldet oder Token abgelaufen | `podman login <artifactory-host>` |
| `unauthorized` beim Push | keine Schreibrechte oder Remote- statt Local-Repo | Ziel muss `<docker-local-repo>` sein; Rechte beim Ausbilder klären |
| `manifest unknown` | Tag oder Image-Name falsch | Pull-Befehl aus **Packages** kopieren statt abtippen |
| `403 Forbidden` mit Hinweis auf eine Policy | Xray blockiert das Artefakt wegen Sicherheitslücken | andere Version wählen, Ausbilder fragen |
| `ImagePullBackOff` mit `401` im Cluster | Pull-Secret fehlt oder liegt im falschen Namespace | `kubectl get secret -n <ns>`, `imagePullSecrets` prüfen ([Artifactory.md](./Artifactory.md#zugriff-aus-dem-cluster-pull-secret)) |
| `ImagePullBackOff` bei einem fremden Chart, Event zeigt eine Registry wie `public.ecr.aws` | für diese Registry gibt es keinen Mirror | Registry im Event ablesen; Ausbilder nach einem Remote-Repo fragen oder den Image-Wert des Charts auf eine Artifactory-Adresse setzen |
| `ImagePullBackOff` bei einem fremden Chart mit Timeout | Mirror greift nicht | `podman exec lab-control-plane cat /etc/containerd/certs.d/<registry>/hosts.toml` prüfen |
| eigenes Image im Cluster nicht gefunden (ohne Push) | Image wurde nicht in den Node geladen | `podman save` + `kind load image-archive … --name lab`, Adresse `localhost/<name>:<tag>` (Modul 05) |

## ArgoCD

| Symptom | Lösung |
| --- | --- |
| `repository not accessible` | Token prüfen, bei Firmen-CA das Zertifikat unter „Settings → Certificates“ hinterlegen |
| `app path does not exist` | `spec.source.path` muss auf den Ordner mit `Chart.yaml` zeigen |
| Application erscheint nicht | Application muss im Namespace `argocd` liegen |
| Änderungen kommen nicht an | „Refresh“ im UI, prüfen, ob auf `targetRevision` gepusht wurde |
| Sync schlägt fehl, `SealedSecret` wird nicht entschlüsselt | Controller-Schlüssel passt nicht (neuer Cluster) – Secret neu mit `kubeseal` verschlüsseln |
