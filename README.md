# platform-foundations – Azubi-Lab: Kubernetes Cluster Administration (IaC-basiert)

## Überblick

Dieses Projekt enthält ein Azubi-Lab für einen Ausbildungseinsatz im Bereich ZCPM / [Kubernetes-Cluster-Administration](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) mit Fokus auf Container, [Infrastructure as Code (IaC)](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code), Artefakt-Management mit JFrog Artifactory und [GitOps](https://opengitops.dev/).

Das Lab ist modular aufgebaut. Jedes Modul besteht aus:

- einer kurzen Einführung in das Thema
- klar formulierten Lernzielen
- mehreren praktischen Aufgaben mit mittlerer Detailtiefe
- einer Checkliste „Du bist fertig, wenn …“ und Verständnisfragen
- einer Musterlösung im Ordner [`solutions/`](./solutions/)

Die Module bauen aufeinander auf, haben aber keine feste Zeitplanung. Tempo und Reihenfolge lassen sich an den Einsatz anpassen.

## Wichtig: Alles kommt über das Artifactory

Im Firmennetz gibt es nur einen Weg zu Container-Images und Helm-Charts: das hauseigene **JFrog Artifactory**. Das Lab ist darauf ausgelegt – vom ersten `podman pull` in Modul 01 bis zum eigenen Image in Modul 05. Wie das funktioniert und welche Platzhalter (z. B. `<artifactory-host>`, `<docker-remote-repo>`) du durch eure Werte ersetzen musst, steht in [docs/Artifactory.md](./docs/Artifactory.md).

## Lernziele

Nach Abschluss aller Module soll der Azubi:

- Kubernetes-Grundlagen verstehen (Pods, Deployments, Services, Namespaces, Ingress)
- einen lokalen `kind`-Cluster unter WSL mit rootless Podman betreiben können
- mit JFrog Artifactory sicher umgehen: Images und Charts finden, beziehen, bewerten und eigene Artefakte veröffentlichen
- eigene Container-Images bauen, die als normaler Benutzer laufen
- Anwendungen per YAML und Helm deployen, aktualisieren und absichern können
- einen GitOps-Workflow mit GitLab und ArgoCD aufsetzen und nutzen können
- grundlegende Monitoring- und Betriebsaufgaben durchführen können

## Voraussetzungen

- WSL 2 mit Ubuntu 24.04 ist installiert und funktionsfähig
- Basis-Kenntnisse im Umgang mit der Shell (ls, cd, mkdir, etc.)
- Git-Basics (clone, commit, push) sind bekannt oder können parallel gelernt werden
- ein Benutzerkonto für das JFrog Artifactory und die Werte für die Platzhalter aus [docs/Artifactory.md](./docs/Artifactory.md#platzhalter)
- Zugriff auf eine GitLab-Instanz

Benötigte Tools und Versionen: [docs/Tools-und-Versionen.md](./docs/Tools-und-Versionen.md)

## Module

Empfohlene Reihenfolge:

1. [Modul 01 – Lab-Umgebung & Container/Kubernetes-Grundlagen](./01-grundlagen.md)
2. [Modul 02 – Manuelle Deployments & Basis-Security](./02-deployments-security.md)
3. [Modul 03 – Helm-Grundlagen](./03-helm-grundlagen.md)
4. [Modul 04 – JFrog Artifactory & Artefakt-Management](./04-artifactory-artefakte.md)
5. [Modul 05 – Container-Images bauen](./05-container-images.md)
6. [Modul 06 – GitLab & GitOps-Struktur](./06-gitlab-gitops-struktur.md)
7. [Modul 07 – ArgoCD & GitOps-Flow](./07-argocd-gitops-flow.md)
8. [Modul 08 – Monitoring & Betrieb](./08-monitoring-betrieb.md)
9. [Modul 09 – Abschlussprojekt (GitOps-Fokus)](./09-abschlussprojekt.md)

Durch alle Module zieht sich die Beispiel-App `azubi-portal`: vom einfachen YAML über ein Helm-Chart und ein eigenes Image im Artifactory bis zur von ArgoCD verwalteten Anwendung.

## Dateien im Repository

| Pfad | Inhalt |
| --- | --- |
| [`kind.yaml`](./kind.yaml) | lokaler kind-Cluster `lab` mit Zertifikats- und Registry-Mirror-Mounts und Port-Mappings 8080/8443 ([Doku](./docs/kind-Konfiguration.md)) |
| [`examples/azubi-portal-chart/`](./examples/azubi-portal-chart/) | Referenz-Helm-Chart ([Doku](./docs/azubi-portal-chart.md)) |
| [`kubernetes-headlamp.yaml`](./kubernetes-headlamp.yaml) | optionale Cluster-Oberfläche Headlamp ([Doku](./docs/Headlamp.md)) |
| [`solutions/`](./solutions/) | Musterlösungen je Modul |
| [`docs/`](./docs/) | Dokumentation: Artifactory, Tools, Ports, kind, Chart, Fehlerbehebung, Repo-Struktur |

Bei Problemen hilft [docs/Fehlerbehebung.md](./docs/Fehlerbehebung.md).
