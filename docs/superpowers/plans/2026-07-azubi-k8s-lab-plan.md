# Azubi-K8s-Lab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aus dem Design-Dokument für das Azubi-Kubernetes-IaC-Lab konkrete Markdown-Module unter `docs/azubi-k8s-lab/` erstellen, die ein Azubi selbstständig durchlaufen kann.

**Architecture:** Lab-Inhalte liegen als modulare Markdown-Dateien vor. Jedes Modul hat klar definierte Lernziele, einen kurzen Theorie-Teil und mehrere praxisorientierte Aufgaben. Die Module bauen logisch aufeinander auf, sind aber zeitlich flexibel.

**Tech Stack:**
- Git-Repo (dieses Projekt)
- Markdown-Dokumentation unter `docs/`
- Kubernetes (kind), Helm, GitLab, ArgoCD, Monitoring-Stack (als Themen, nicht als Code in diesem Plan)

## Global Constraints

- Struktur und Inhalte folgen dem Design-Dokument: `docs/superpowers/specs/2026-07-azubi-k8s-lab-design.md`.
- Sprache in den Lab-Dokumenten ist Deutsch; Commands/Code bleiben im Original.
- Keine firmenspezifischen Prozesse hart verdrahten; GitLab-/MR-Standards bleiben generisch.
- Aufgaben mit mittlerer Detailtiefe: Ziel + Hinweise, keine vollständigen Musterlösungen.

---

## Task 1: Lab-Ordner und README-Gerüst anlegen

**Files:**
- Create: `docs/azubi-k8s-lab/README.md`

**Interfaces:**
- Consumes: Design aus `docs/superpowers/specs/2026-07-azubi-k8s-lab-design.md`.
- Produces: Einstiegspunkt für alle Azubi-Module, referenziert alle Modul-Dateien.

- [ ] **Step 1: README Grundstruktur schreiben**

Inhaltliches Gerüst (leicht anpassbar):

```markdown
# Azubi-Lab: Kubernetes Cluster Administration (IaC-basiert)

## Überblick

Kurzbeschreibung, wofür das Lab gedacht ist (Azubi-Einsatz, Fokus Kubernetes + GitOps + IaC).

## Lernziele

- Kubernetes-Grundlagen verstehen (Pods, Deployments, Services, Namespaces)
- Lokalen kind-Cluster aufsetzen und nutzen
- Anwendungen mit YAML und Helm deployen
- GitOps-Workflow mit GitLab und ArgoCD einrichten und bedienen
- Monitoring/Logging-Grundlagen anwenden

## Voraussetzungen

- Grundkenntnisse in Linux/WSL und Shell
- Basiswissen Git (clone, commit, push)
- Zugriff auf GitLab-Instanz

## Module

- Modul 01 – Lab-Umgebung & Kubernetes-Grundlagen
- Modul 02 – Manuelle Deployments & Basis-Security
- Modul 03 – Helm-Grundlagen
- Modul 04 – GitLab & GitOps-Struktur
- Modul 05 – ArgoCD & GitOps-Flow
- Modul 06 – Monitoring & Betrieb
- Modul 07 – Abschlussprojekt (GitOps-Fokus)

Kurze Erklärung, dass Module in Reihenfolge empfohlen sind, aber zeitlich flexibel.
```

- [ ] **Step 2: Datei speichern und grob gegen Design abgleichen**

Prüfen, ob alle Module aus dem Design aufgeführt sind und die Lernziele grob passen.

- [ ] **Step 3: Optional: Kurze Notiz zum erwarteten Zeitrahmen ergänzen**

Hinweis, dass Module typischerweise über mehrere Wochen verteilt werden können, aber keine harte Planung enthalten.

---

## Task 2: Modul 01 – Grundlagen-Datei erstellen

**Files:**
- Create: `docs/azubi-k8s-lab/modul-01-grundlagen.md`

**Interfaces:**
- Consumes: Abschnitt „Modul 01“ aus Design-Dokument.
- Produces: Konkrete Einstiegsaufgaben; wird in README referenziert.

- [ ] **Step 1: Kopfbereich und Lernziele eintragen**

Beispiel:

```markdown
# Modul 01 – Lab-Umgebung & Kubernetes-Grundlagen

## Kurzbeschreibung

In diesem Modul richtest du deine lokale Lab-Umgebung ein und machst erste Schritte mit Kubernetes.

## Lernziele

- WSL, Podman und einen lokalen kind-Cluster einrichten
- `kubectl`-Grundbefehle anwenden (get, describe, logs)
- grundlegende Kubernetes-Objekte verstehen: Node, Pod, Deployment, Service, Namespace

## Voraussetzungen

- WSL (Ubuntu) ist installiert
- Du kannst einfache Shell-Befehle ausführen
```

- [ ] **Step 2: Theorie-Kurzabschnitt ergänzen**

Kurz erklären, was Kubernetes grob macht (Orchestrierung von Containern, Cluster mit Control Plane und Workern) und was ein Pod/Deployment/Service ist, jeweils in 1–3 Sätzen.

- [ ] **Step 3: 3–5 praktische Aufgaben formulieren**

Aufgaben mit mittlerer Detailtiefe z. B.:

```markdown
### Aufgabe 1: WSL und Podman prüfen

Ziel: Sicherstellen, dass du Container lokal starten kannst.

- Prüfe, ob WSL Ubuntu funktioniert (`ls`, `pwd`).
- Installiere Podman (falls noch nicht vorhanden) und starte einen Test-Container (z. B. `podman run --rm -p 8080:80 nginx`).
- Öffne im Browser `http://localhost:8080` und überprüfe, ob die Seite erreichbar ist.

Notiere die verwendeten Befehle in einer Datei `notes/modul-01.md` (oder ähnlichem Ort deiner Wahl).
```

Weitere Aufgaben: kind-Cluster anlegen, kubectl testen, einfache Demo-App deployen, Namespaces ausprobieren.

- [ ] **Step 4: Abschnitt „Weiterführend“ ergänzen**

Optional 1–2 Ideen wie „Lies die offizielle Kubernetes-Übersichtsseite“ oder „Probiere weitere `kubectl`-Befehle“.

---

## Task 3: Modul 02 – Deployments & Basis-Security-Datei erstellen

**Files:**
- Create: `docs/azubi-k8s-lab/modul-02-deployments-security.md`

**Interfaces:**
- Consumes: Abschnitt „Modul 02“ aus Design-Dokument, Kenntnisse aus Modul 01.
- Produces: Aufgaben zu YAML-Deployments, ConfigMaps, Secrets, RBAC-Basics, einfacher NetworkPolicy.

- [ ] **Step 1: Modul-Kopf mit Kurzbeschreibung und Lernzielen schreiben**

Lernziele aus Design übernehmen (Deployments/Services/ConfigMaps/Secrets, RBAC-Grundlagen, einfache NetworkPolicies).

- [ ] **Step 2: Theorie-Kurzabschnitt zu Deployments, Services und Security schreiben**

Je 1–2 Sätze pro Thema:
- warum Deployments über Pod-Definitionen hinausgehen (Replikate, Self-Healing)
- was Services leisten (stabile Erreichbarkeit, Service-Typen ggf. kurz anreißen)
- was RBAC grob bedeutet (wer darf was)
- was NetworkPolicies grob tun (Netzwerkzugriff regeln)

- [ ] **Step 3: 3–6 Aufgaben formulieren**

Beispielaufgaben:
- Deployment + Service für Web-App als YAML schreiben und ausrollen
- ConfigMap und Secret erstellen und in Pod einbinden
- ServiceAccount + Role + RoleBinding definieren und Wirkung testen
- einfache NetworkPolicy erstellen und Wirkung per Test-Pod überprüfen

Die Aufgaben sollen klare Ziele und Hinweise enthalten (Ressourcen-Namen vorschlagen, welche Befehle nützlich sind), aber keine vollständigen Lösungsyamls.

---

## Task 4: Modul 03 – Helm-Datei erstellen

**Files:**
- Create: `docs/azubi-k8s-lab/modul-03-helm.md`

**Interfaces:**
- Consumes: Abschnitt „Modul 03“ aus Design-Dokument, Grundlagen aus Modulen 01–02.
- Produces: Aufgaben zu Helm-Grundlagen, Chart-Struktur, Values, Upgrade/Rollback, eigenes kleines Chart.

- [ ] **Step 1: Modul-Kopf und Lernziele schreiben**

Lernziele aus Design übernehmen (Chart-Aufbau, Values, Templates, Helm-Lifecycle).

- [ ] **Step 2: Theorie-Kurzabschnitt zu Helm schreiben**

Kurz erklären, warum Helm genutzt wird (Wiederverwendbarkeit, Templating, Versionierung) und wie ein Chart grob aufgebaut ist.

- [ ] **Step 3: 3–6 Aufgaben formulieren**

Beispielaufgaben:
- offizielles Demo-Chart installieren und Struktur erklären
- `values.yaml` anpassen (Port, Replikas, Config)
- fehlerhaftes Release ausrollen und mittels Rollback fixen
- kleines eigenes Chart für einfache App erstellen

---

## Task 5: Modul-04–07-Dateien anlegen (Gerüst)

**Files:**
- Create: `docs/azubi-k8s-lab/modul-04-gitlab-gitops-struktur.md`
- Create: `docs/azubi-k8s-lab/modul-05-argocd-gitops-flow.md`
- Create: `docs/azubi-k8s-lab/modul-06-monitoring-betrieb.md`
- Create: `docs/azubi-k8s-lab/modul-07-abschlussprojekt.md`

**Interfaces:**
- Consumes: Design-Abschnitte zu Modulen 04–07.
- Produces: Grundgerüste, die später detailliert werden können.

- [ ] **Step 1: Modul-Gerüste erzeugen**

Für jedes Modul:

```markdown
# Modul XX – <Name>

## Kurzbeschreibung

Kurzer 2–3-Satz-Text, was in diesem Modul passiert.

## Lernziele

- Liste der Lernziele aus dem Design-Dokument

## Voraussetzungen

- Aufzählung der vorherigen Module

## Theorie

Kurzer Platzhalter-Satz (wird in nächster Task konkretisiert).

## Aufgaben

Wird in folgender Task mit konkreten Aufgaben gefüllt.

## Weiterführend

Optionaler Abschnitt für spätere Ergänzungen.
```

Wichtig: Keine „TBD/TODO“-Markierungen verwenden, sondern klare Hinweise, dass Theorie/Aufgaben im nächsten Schritt konkretisiert werden.

---

## Task 6: Modul-04–06 mit Theorie und Aufgaben füllen

**Files:**
- Modify: `docs/azubi-k8s-lab/modul-04-gitlab-gitops-struktur.md`
- Modify: `docs/azubi-k8s-lab/modul-05-argocd-gitops-flow.md`
- Modify: `docs/azubi-k8s-lab/modul-06-monitoring-betrieb.md`

**Interfaces:**
- Consumes: Design-Dokument-Abschnitte zu Modulen 04–06.
- Produces: voll nutzbare Lab-Module.

- [ ] **Step 1: Theorie-Abschnitte ausformulieren**

Je Modul 04–06 kurze Theorie-Texte schreiben:
- Modul 04: GitLab-GitOps-Repo-Struktur, Branch/MR-Grundlagen (generisch)
- Modul 05: GitOps-Prinzipien, ArgoCD-Grundkonzepte (Application, Sync, Health)
- Modul 06: Monitoring-Grundbegriffe, Metriken vs. Logs, einfache Alerts

- [ ] **Step 2: Konkrete Aufgabenlisten pro Modul schreiben**

Pro Modul 3–6 Aufgaben mit Zielbeschreibung + Hinweisen, u. a.:
- Modul 04: GitLab-Repo anlegen, Struktur etablieren, README schreiben
- Modul 05: ArgoCD installieren, Application anlegen, Drift/Self-Healing testen
- Modul 06: kleinen Monitoring-Stack aufsetzen, Dashboard und 1–2 Incidents simulieren

---

## Task 7: Modul 07 – Abschlussprojekt konkretisieren

**Files:**
- Modify: `docs/azubi-k8s-lab/modul-07-abschlussprojekt.md`

**Interfaces:**
- Consumes: Design-Abschnitt zu Modul 07, Ergebnisse der vorherigen Module.
- Produces: klar beschriebenes Abschlussprojekt mit GitOps-Fokus.

- [ ] **Step 1: Projektbeschreibung definieren**

In 1–2 Absätzen klarmachen:
- kleine Anwendung (ein Service) reicht
- Helm-Chart + GitLab-Repo + ArgoCD-Application sollen verwendet werden
- Fokus liegt auf sauberem GitOps-Flow und Dokumentation

- [ ] **Step 2: Aufgaben in Phasen strukturieren**

Beispielphasen:
- Planung (Anwendung wählen, Architektur grob skizzieren)
- Umsetzung (Chart bauen/anpassen, ArgoCD konfigurieren)
- Tests (mindestens ein Update über GitOps durchführen)
- Dokumentation (Markdown-File mit Beschreibung und Screenshots/Kommandos)

---

## Task 8: Quer-Review und Feinschliff

**Files:**
- Modify: `docs/azubi-k8s-lab/README.md`
- Modify: alle `docs/azubi-k8s-lab/modul-*.md` nach Bedarf

**Interfaces:**
- Consumes: alle Modul-Dateien.
- Produces: konsistentes, sprachlich stimmiges Lab.

- [ ] **Step 1: Konsistenzcheck durchführen**

Prüfen:
- Modul-Reihenfolge und Namen stimmen überall überein
- Lernziele und Aufgaben passen zueinander
- Begriffe (z. B. "kind", "GitOps", "ArgoCD") werden konsistent geschrieben

- [ ] **Step 2: Placeholder-Sprache entfernen**

Sicherstellen, dass nirgendwo "wird später ergänzt" o. Ä. steht. Alles, was der Azubi sieht, soll vollständig wirken.

- [ ] **Step 3: Rechtschreibung und Lesbarkeit kurz prüfen**

Grobe Tippfehler korrigieren; nicht auf perfekte Stilistik optimieren, nur Verständlichkeit sichern.
