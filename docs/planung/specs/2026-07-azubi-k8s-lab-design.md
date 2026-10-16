# Design: Azubi-Lab Kubernetes Cluster Administration (IaC-basiert)

## 1. Zielbild

Dieses Lab richtet sich an einen Azubi mit Einstiegsniveau in Kubernetes/Container.
Ziel ist, dass der Azubi nach Abschluss:

- grundlegende Kubernetes-Konzepte sicher versteht (Nodes, Pods, Deployments, Services, Namespaces)
- einen lokalen Kubernetes-Lab-Cluster eigenständig betreiben kann (Start, Stop, einfache Fehleranalyse)
- Anwendungen manuell und per Helm deployen kann
- ein GitOps-Setup mit GitLab und ArgoCD für einfache Anwendungen aufbauen und betreiben kann
- grundlegende Betriebsaspekte (Monitoring, Logs, einfache Alerts, Rollbacks) kennt und anwenden kann

Das Lab ist bewusst als **Modul-Lab ohne feste Zeitplanung** gestaltet. Die Module bauen aufeinander auf und können flexibel über mehrere Wochen eingesetzt werden.

## 2. Rahmenbedingungen

- Arbeitsumgebung: Windows-Client mit WSL (Ubuntu) und Podman
- Kubernetes-Lab-Cluster: lokales `kind`-Cluster in WSL
- Container-Laufzeit: Podman als Backend für `kind` (sofern technisch möglich; alternativ docker-kompatible Runtime nach Abstimmung)
- Git-Hosting: GitLab (SaaS oder bestehende externe Instanz)
- GitOps-Controller: ArgoCD im lokalen `kind`-Cluster
- IaC-Fokus: Helm, GitOps mit ArgoCD, GitLab-Repo-Struktur (kein harter Fokus auf Terraform/Ansible in diesem Lab)
- Security: Basis-Themen (RBAC, Secrets, einfache NetworkPolicies) in passendem Umfang
- Sprache der Unterlagen: Deutsch (Commands, Code, Ressourcennamen typischerweise Englisch)
- Theorieanteil: Kurz bis mittellang pro Modul, immer gekoppelt mit praktischen Aufgaben

## 3. Lab-Struktur und Dateien

Alle Inhalte leben in Markdown-Dateien im Repository. Vorgeschlagene Struktur:

- `docs/azubi-k8s-lab/README.md`
  - Überblick, Lernziele, Voraussetzungen, Modulübersicht, Hinweise zur Nutzung
- `docs/azubi-k8s-lab/modul-01-grundlagen.md`
- `docs/azubi-k8s-lab/modul-02-deployments-security.md`
- `docs/azubi-k8s-lab/modul-03-helm.md`
- `docs/azubi-k8s-lab/modul-04-gitlab-gitops-struktur.md`
- `docs/azubi-k8s-lab/modul-05-argocd-gitops-flow.md`
- `docs/azubi-k8s-lab/modul-06-monitoring-betrieb.md`
- `docs/azubi-k8s-lab/modul-07-abschlussprojekt.md`

Jede Modul-Datei folgt demselben groben Aufbau:

1. Kurzbeschreibung
2. Lernziele
3. Voraussetzungen (welche Module/Skills sollten vorher erledigt sein)
4. Theorie-Kurzabschnitt zum Thema
5. Praktische Aufgaben (3–6 Aufgaben, mittlere Detailtiefe)
6. Optional: Weiterführende Ideen

Die Aufgaben werden **nicht** als Issues/Tickets geführt, sondern vollständig in den Markdown-Dateien beschrieben. Wenn gewünscht, können später einzelne Aufgaben zusätzlich in GitLab-Issues gespiegelt werden, das gehört aber nicht zum Kern dieses Designs.

## 4. Modulübersicht

### Modul 01 – Lab-Umgebung & Kubernetes-Grundlagen

Fokus: Arbeitsumgebung aufsetzen und erste Berührung mit Kubernetes-Konzepten.

Lernziele:

- WSL, Podman und `kind` lokal einrichten
- `kubectl` bedienen (get, describe, logs, exec)
- grundlegende Objekttypen verstehen: Node, Pod, Deployment, Service, Namespace

Inhalte & Aufgaben (Beispiele für spätere Ausarbeitung):

- WSL Ubuntu installieren/prüfen, Podman installieren und einfachen Container starten
- `kind`-Cluster erstellen, Verbindung mit `kubectl` testen
- einfache Demo-App (z. B. nginx) im Cluster deployen
- Unterschied Pod vs. Deployment erklären
- Namespaces anlegen, Ressourcen in verschiedenen Namespaces bereitstellen

Voraussetzungen: Grundlegende CLI-Bedienung, Git-Basics (clone, commit, push) sind bekannt oder werden kurz aufgefrischt.

### Modul 02 – Manuelle Deployments & Basis-Security

Fokus: klassische YAML-Deployments, Services und erste Security-Aspekte.

Lernziele:

- Deployments, Services, ConfigMaps und Secrets per YAML definieren und ausrollen
- grundlegende RBAC-Konzepte verstehen (User/ServiceAccount, Role, RoleBinding)
- einfache NetworkPolicies konzipieren und anwenden können (mindestens ein Beispiel)

Inhalte & Aufgaben (Beispiele):

- Deployment und Service für einfache Web-App schreiben und mit `kubectl apply` ausrollen
- ConfigMap und Secret definieren und in Pods einbinden (Umgebungsvariablen/Volumes)
- ServiceAccount und Role/RoleBinding für eine simple Anwendung anlegen
- Eine NetworkPolicy definieren, die Traffic z. B. auf einen Namespace oder Port einschränkt und deren Wirkung testen

Voraussetzungen: Modul 01 abgeschlossen.

### Modul 03 – Helm-Grundlagen

Fokus: Anwendungen als Helm-Charts strukturieren, konfigurieren und versionieren.

Lernziele:

- Aufbau eines Helm-Charts verstehen (Chart.yaml, values.yaml, Templates)
- bestehende Helm-Charts installieren und anpassen
- eigene einfache Helm-Charts erstellen
- Helm-Lebenszyklus (install, upgrade, rollback) praktisch anwenden

Inhalte & Aufgaben (Beispiele):

- Helm installieren und ein offizielles Demo-Chart deployen
- Chart-Struktur analysieren und wichtige Dateien erklären
- `values.yaml` anpassen (Replikas, Ports, Image, Config)
- absichtlich fehlerhaftes Release ausrollen und per Rollback korrigieren
- eigenes kleines Chart für einfache App aufbauen (Minimalvariante ausreichend)

Voraussetzungen: Modul 01 und 02 abgeschlossen.

### Modul 04 – GitLab & GitOps-Struktur

Fokus: Repository-Struktur und Arbeitsweise für GitOps vorbereiten.

Lernziele:

- sinnvolle Verzeichnisstruktur für GitOps-Repo entwerfen
- grundlegende GitLab-Workflows verstehen (Branches, Merge Requests, Code-Review auf Basis generischer Best Practices)
- Trennung von Cluster-Basis-Konfiguration und Anwendungs-Konfiguration planen

Inhalte & Aufgaben (Beispiele):

- neues GitLab-Repo für das Lab anlegen (oder bestehendes nutzen)
- Struktur vorschlagen, z. B. `cluster/base`, `cluster/apps`, `apps/<app-name>`
- README schreiben, das Aufbau und Zweck der Struktur erklärt
- einfache Regeln für MRs definieren (z. B. keine Commits direkt auf main, mindestens ein Review für wichtige Änderungen), ohne firmenspezifische Details vorzugeben

Voraussetzungen: Modul 01–03 abgeschlossen.

### Modul 05 – ArgoCD & GitOps-Flow

Fokus: GitOps-Deployment mit ArgoCD und GitLab aufsetzen.

Lernziele:

- ArgoCD im `kind`-Cluster installieren und konfigurieren
- ArgoCD mit GitLab-Repo verbinden
- Anwendungen als ArgoCD Applications definieren (Helm-basierend)
- GitOps-Flow Ende-zu-Ende verstehen: Commit → ArgoCD-Sync → Rollout
- Self-Healing und Config-Drift nachvollziehen

Inhalte & Aufgaben (Beispiele):

- ArgoCD-Installation im Lab-Cluster (via Helm oder offizielle Manifeste)
- Zugang zum ArgoCD Web-UI herstellen und dokumentieren
- erste ArgoCD Application erstellen, die ein Helm-Chart aus dem GitLab-Repo deployt
- Änderung in GitLab committen und beobachten, wie ArgoCD deployt
- manuelle Änderung im Cluster erzeugen (Drift) und ArgoCD bei der Korrektur beobachten

Voraussetzungen: Modul 01–04 abgeschlossen.

### Modul 06 – Monitoring & Betrieb

Fokus: Cluster-Zustand beobachten, Metriken und Logs nutzen, einfache Störungen behandeln.

Lernziele:

- grundlegende Werkzeuge zur Beobachtung kennen (`kubectl logs`, `kubectl describe`, `kubectl top`, Events)
- einfachen Monitoring-Stack aufsetzen (z. B. Prometheus + Grafana oder vergleichbare Lösung) und ein Dashboard erstellen
- erste Alerts definieren (z. B. hoher CPU-Verbrauch, Pod-Restarts) und interpretieren
- einfache Incident-Szenarien analysieren und beheben

Inhalte & Aufgaben (Beispiele):

- Metrics Server oder geeigneten Monitoring-Stack im Lab-Cluster deployen
- Dashboard erstellen, das grundlegende Metriken für eine Beispiel-App zeigt
- Szenario: Ressourcengrenzen absichtlich zu niedrig setzen, Auswirkungen beobachten
- Szenario: Anwendung fehlerhaft konfigurieren (z. B. falsche URL, fehlende Env-Var) und via Logs/Events Ursache finden
- klar dokumentieren, welche Schritte zur Fehleranalyse genutzt wurden

Voraussetzungen: Modul 01–05 abgeschlossen.

### Modul 07 – Abschlussprojekt (GitOps-Fokus)

Fokus: kleines, in sich geschlossenes Projekt, das den vollständigen GitOps-Flow demonstriert.

Projektumfang: bewusst **klein gehalten**, damit ein Azubi auf Einstiegsniveau es überschaubar umsetzen kann.

Lernziele:

- eigenständig ein kleines Anwendungsszenario planen (eine einfache App, z. B. Webservice)
- Anwendung als Helm-Chart modellieren
- GitOps-Flow mit GitLab + ArgoCD vollständig aufbauen und demonstrieren
- kurze Dokumentation und Abschluss-Reflexion erstellen

Inhalte & Aufgaben (Beispiele):

- kleine Beispielanwendung auswählen (z. B. statische Website oder einfacher API-Service)
- Helm-Chart erstellen oder vorhandenes Chart anpassen
- GitLab-Repo-Struktur nutzen, um App-Konfiguration sauber zu halten
- ArgoCD Application definieren, die diese App ausrollt
- mindestens ein Update über GitLab-Commit durchführen und Deployment beobachten
- kurze Markdown-Dokumentation im Repo erstellen, die Aufbau und GitOps-Flow beschreibt

Voraussetzungen: alle vorherigen Module abgeschlossen.

## 5. Lernkontrolle und Evaluation

Die Verständniskontrolle erfolgt über:

1. kontinuierliche praktische Aufgaben in jedem Modul
2. Rückfragen und kurze mündliche Erklärungsphasen während der Betreuung
3. Abschlussprojekt in Modul 07 mit Fokus auf GitOps-Flow

Empfohlenes Vorgehen:

- Betreuende Personen führen 2–3 kurze Check-ins pro Woche (oder vergleichbaren Rhythmus) durch
- Code und Konfigurationsänderungen werden via GitLab-Review grob gegengecheckt
- Am Ende des Abschlussprojekts präsentiert der Azubi kurz den aufgebauten Flow (informell, z. B. internes Mini-Review)

## 6. Betreuungs- und Schwierigkeitsgrad

- Aufgabenbeschreibung mit mittlerer Detailtiefe: Ziel und grobe Hinweise sind gegeben, der Azubi muss Details und konkrete Befehle teilweise selbst recherchieren
- keine starre Zeitvorgabe pro Modul; Tempo kann an Vorkenntnisse und Einsatzdauer angepasst werden
- Betreuung auf mittlerem Niveau: regelmäßige Check-ins, Reviews, Unterstützung bei Blockern, aber kein permanentes Pairing

## 7. Nächste Schritte

1. Obige Modul-Struktur und Ziele final mit dem Team abstimmen.
2. Markdown-Dateien unter `docs/azubi-k8s-lab/` gemäß diesem Design anlegen.
3. Pro Modul konkrete Aufgabenlisten (inkl. Beispielbefehle, wo sinnvoll) ausformulieren.
4. Optional: Beispiel-Lösungen oder Lösungs-Snippets separat ablegen (nicht direkt im Azubi-Lab-Dokument, um Eigenarbeit zu fördern).

Nach Freigabe dieses Designs kann ein detaillierter Umsetzungsplan erstellt werden (z. B. welche Datei wann geschrieben wird, wer was vorbereitet, etc.).
