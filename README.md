# platform-foundations – Azubi-Lab: Kubernetes Cluster Administration (IaC-basiert)

## Überblick

Dieses Projekt enthält ein Azubi-Lab für einen Ausbildungseinsatz im Bereich [Kubernetes-Cluster-Administration](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) mit Fokus auf [Infrastructure as Code (IaC)](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code) und [GitOps](https://opengitops.dev/).

Das Lab ist modular aufgebaut. Jedes Modul besteht aus:

- einer kurzen Einführung in das Thema
- klar formulierten Lernzielen
- mehreren praktischen Aufgaben mit mittlerer Detailtiefe

Die Module bauen aufeinander auf, haben aber keine feste Zeitplanung. Ihr könnt Tempo und Reihenfolge leicht an euren Einsatz anpassen.

## Lernziele

Nach Abschluss aller Module soll der Azubi:

- Kubernetes-Grundlagen verstehen (Pods, Deployments, Services, Namespaces)
- einen lokalen `kind`-Cluster unter WSL mit Podman betreiben können
- Anwendungen per YAML und Helm deployen und aktualisieren können
- einen GitOps-Workflow mit GitLab und ArgoCD aufsetzen und nutzen können
- grundlegende Monitoring- und Betriebsaufgaben durchführen können

## Voraussetzungen

- WSL (Ubuntu) ist installiert und funktionsfähig
- Basis-Kenntnisse im Umgang mit der Shell (ls, cd, mkdir, etc.)
- Git-Basics (clone, commit, push) sind bekannt oder können parallel gelernt werden
- Zugriff auf eine GitLab-Instanz

## Module

Empfohlene Reihenfolge:

1. [Modul 01 – Lab-Umgebung & Container/Kubernetes-Grundlagen](./01-grundlagen.md)
2. [Modul 02 – Manuelle Deployments & Basis-Security](./02-deployments-security.md)
3. [Modul 03 – Helm-Grundlagen](./03-helm-grundlagen.md)
4. [Modul 04 – GitLab & GitOps-Struktur](./04-gitlab-gitops-struktur.md)
5. [Modul 05 – ArgoCD & GitOps-Flow](./05-argocd-gitops-flow.md)
6. [Modul 06 – Monitoring & Betrieb](./06-monitoring-betrieb.md)
7. [Modul 07 – Abschlussprojekt (GitOps-Fokus)](./07-abschlussprojekt.md)

Alle Module liegen als einzelne Markdown-Dateien im Repository-Root und können vom Azubi in dieser Reihenfolge oder nach Bedarf durchlaufen werden.

Im Repo-Root liegt außerdem eine `kind.yaml`, die ein lokales `kind`-Cluster namens `lab` mit zu unserer Umgebung passenden Zertifikats-Mounts und Port-Mappings (8080/8443) definiert. Die Einrichtung wird in Modul 01 beschrieben.
