# Build-Anleitung

Dieses Repository enthält die Vorlesungsfolien (`AuFS.org` + eingebundene
`*.org`-Dateien) und die Übungsblätter (`exercises/exercise_*.org`) als
**Org-Mode-Quellen**. Daraus wird bei jedem Build zunächst LaTeX erzeugt
(`*.tex`) und daraus dann das PDF. Das `tex/`-Verzeichnis enthält zum
Vergleich die ursprüngliche, rein handgeschriebene LaTeX-Fassung (nur als
Referenz, wird nicht mehr gepflegt).

```
AuFS.org  ──(Org-Export)──>  AuFS.tex  ──(pdflatex/latexmk)──>  AuFS.pdf
exercises/exercise_NN_*.org ──> exercise_NN_*.tex ──> exercise_NN_*.pdf
```

Der GitHub-Actions-Workflow (`.github/workflows/main.yml`) macht bei jedem
Push/PR auf `main` genau das automatisch. Diese Anleitung beschreibt, wie
man denselben Build lokal nachvollzieht.

## Voraussetzungen

| Werkzeug | Zweck | Getestet mit |
|---|---|---|
| **Emacs** (inkl. eingebautem Org-Mode) | Export der `.org`-Dateien zu `.tex` | Emacs 30.2 / Org 9.7 |
| **TeX Live** (pdflatex + latexmk) | Kompilieren des `.tex` zu PDF | TeX Live 2025 |

Beides ist unabhängig voneinander installierbar; für Emacs reicht die
**eingebaute** Org-Mode-Version, es wird **keine** zusätzliche Emacs-Konfiguration
(`~/.emacs`, `init.el`, `use-package`-Setups o.ä.) benötigt oder vorausgesetzt.
Das ist bewusst so gebaut: der Export darf nicht von einer privaten
Emacs-Konfiguration abhängen, sonst funktioniert er auf einem anderen Rechner
oder in CI nicht mehr (siehe Abschnitt [Fallstricke](#org-mode-vs-latex-was-ist-anders-und-worauf-muss-man-achten)).

## Einrichtung unter Linux

### Debian / Ubuntu

Schnell und garantiert vollständig (ca. 4–7 GB, dauert entsprechend):

```bash
sudo apt update
sudo apt install emacs-nox texlive-full latexmk
```

Schlanker, mit genau den Paketen, die dieses Repository tatsächlich braucht
(Beamer, Metropolis-Theme, KOMA-Script, TikZ/circuitikz/qrcode, deutsche
Sprachpakete):

```bash
sudo apt update
sudo apt install emacs-nox latexmk \
  texlive-latex-base texlive-latex-recommended texlive-latex-extra \
  texlive-fonts-recommended texlive-pictures texlive-lang-german \
  texlive-plain-generic
```

### Arch Linux

```bash
sudo pacman -S emacs texlive-basic texlive-latexextra texlive-latexrecommended \
  texlive-pictures texlive-fontsrecommended texlive-langgerman
```

### Fedora

```bash
sudo dnf install emacs texlive-scheme-full
```

(Fedoras TeX-Live-Pakete sind feingranularer aufgeteilt als bei Debian; für
den Einstieg ist `texlive-scheme-full` am unkompliziertesten.)

## Einrichtung unter Windows

**Empfohlen: WSL (Windows-Subsystem für Linux).** Damit läuft alles exakt wie
unter Linux beschrieben:

1. WSL installieren: `wsl --install` (in PowerShell als Administrator), danach
   z. B. Ubuntu als Distribution wählen.
2. Im WSL-Terminal wie oben unter „Debian/Ubuntu" vorgehen.
3. Das Repository entweder direkt im Linux-Dateisystem von WSL klonen (deutlich
   schneller als unter `/mnt/c/...`) oder von dort aus bearbeiten.

**Alternative: native Windows-Installation** (kein WSL):

1. [MiKTeX](https://miktex.org/download) installieren (installiert fehlende
   Pakete bei Bedarf automatisch nach – für Metropolis-Theme, circuitikz,
   qrcode etc. beim ersten Bau also kurz Geduld haben bzw. den
   Paket-Installationsdialog bestätigen).
2. [GNU Emacs für Windows](https://ftp.gnu.org/gnu/emacs/windows/) installieren.
3. Befehle unten in **PowerShell** ausführen; einziger Unterschied: der
   `emacs`-Aufruf muss ggf. mit vollem Pfad erfolgen, falls Emacs nicht im
   `PATH` liegt.

MiKTeX bringt `latexmk` nicht automatisch mit – im MiKTeX-Console-Tool unter
"Packages" nach `latexmk` suchen und installieren, oder ersatzweise dreimal
`pdflatex` hintereinander aufrufen (siehe unten).

**Alternative: Docker (kein Emacs-Install unter Windows nötig).** Der Export
läuft technisch zwingend über Org-Modes eigenen Exporter und damit über
Emacs – das lässt sich nicht umgehen (siehe „Warum nicht Pandoc?" unten). Wer
aber kein Emacs *direkt unter Windows installieren* möchte, kann stattdessen
[Docker Desktop](https://www.docker.com/products/docker-desktop/) nutzen und
Emacs nur innerhalb eines Containers laufen lassen – dieselben Befehle wie
unter Linux, nur containerisiert:

```powershell
docker run --rm -v "${PWD}:/repo" -w /repo debian:bookworm bash -c "
  apt-get update && apt-get install -y emacs-nox texlive-full latexmk &&
  emacs --batch AuFS.org -l org -l ox-beamer \
    --eval '(org-export-to-file (quote beamer) \"AuFS.tex\")' &&
  latexmk -pdf -interaction=nonstopmode AuFS.tex
"
```

Das lädt bei jedem Lauf `texlive-full` neu herunter (mehrere GB, entsprechend
langsam) – für wiederholtes Bauen lohnt es sich, daraus ein eigenes,
lokal getaggtes Image zu bauen (`docker commit` oder ein kleines `Dockerfile`),
statt jedes Mal neu zu installieren. Das ist genau der Ansatz, den auch der
GitHub-Actions-Workflow verwendet (nur dass dort das TeX-Live-Image von
`xu-cheng/latex-action` bereits vorgebaut ist statt bei jedem Lauf frisch
installiert zu werden).

### Warum nicht Pandoc (oder ein anderer Nicht-Emacs-Konverter)?

Kurze Antwort: **weil es für dieses Repository ausprobiert wurde und nicht
funktioniert hat.** Pandoc kann `.org`-Dateien lesen und erzeugt auf den
ersten Blick sogar plausibel aussehendes LaTeX/Beamer – für einfache
Übungsblätter ganz ohne Sonderwünsche reicht das im Zweifel sogar aus. Für
dieses Repository aber nicht, aus zwei Gründen, die sich beim Test
(`pandoc -f org -t beamer AuFS.org`) direkt gezeigt haben:

- Pandocs Org-Reader kennt die Org-eigenen Export-Schlüsselwörter
  `#+LATEX_HEADER:`, `#+LATEX_CLASS:` und `#+LATEX_CLASS_OPTIONS:` nicht.
  Die komplette Präambel dieses Dokuments – Metropolis-Theme, TikZ/circuitikz,
  Farbdefinitionen, QR-Code-Paket, `babel` – **fällt komplett weg**. Das
  Ergebnis kompiliert bestenfalls mit Standard-Beamer-Theme und ohne die
  benötigten Pakete, meist aber gar nicht.
- `#+BEGIN_EXPORT latex … #+END_EXPORT`-Blöcke vor der ersten Überschrift
  (z. B. das `\shorthandoff{"}` aus Punkt 5 unten) werden von Pandoc in ein
  eigenes, leeres `\begin{frame}…\end{frame}` gepackt statt – wie von Org
  vorgesehen – als Dokument-Setup vor die erste Folie gestellt zu werden.

Ein Umstieg auf Pandoc würde also bedeuten, die komplette Präambel manuell in
ein Pandoc-Template zu übertragen und jede Folie mit rohem `#+BEGIN_EXPORT`
einzeln nachzuprüfen – der Aufwand entspricht damit ungefähr dem, das
Dokument gleich in reinem LaTeX zu pflegen, und unterläuft den eigentlichen
Sinn von Org-Mode hier.

Die `exercises/*.org` sind zwar reines `scrartcl` ohne Beamer, hängen aber
genauso an der Präambel (`#+LATEX_HEADER:` für `babel`/`shorthandoff`,
`#+LATEX_CLASS: scrartcl` selbst) – ein Pandoc-Export bräuchte auch hier ein
komplett von Hand nachgebautes Template. Für `AuFS.org` (Beamer, Themes,
`#+BEGIN_EXPORT`) ist Pandoc erst recht keine Option.

## Lokal bauen

Aus dem Repository-Wurzelverzeichnis:

```bash
# 1. Folien exportieren (Org -> LaTeX)
emacs --batch AuFS.org -l org -l ox-beamer \
  --eval '(org-export-to-file (quote beamer) "AuFS.tex")'

# 2. Folien kompilieren
latexmk -pdf -interaction=nonstopmode AuFS.tex
```

Für die Übungsblätter zusätzlich `exercises/org-export-setup.el` laden (siehe
[Fallstricke](#org-mode-vs-latex-was-ist-anders-und-worauf-muss-man-achten),
Punkt „Eigene Dokumentklassen"):

```bash
cd exercises
for f in exercise_*.org; do
  base="${f%.org}"
  emacs --batch -l ./org-export-setup.el "$f" -l org \
    --eval "(org-export-to-file (quote latex) \"${base}.tex\")"
  latexmk -pdf -interaction=nonstopmode "${base}.tex"
done
```

Ohne `latexmk` (z. B. frisches MiKTeX ohne das Paket) tut es notfalls auch:

```bash
pdflatex AuFS.tex && pdflatex AuFS.tex && pdflatex AuFS.tex
```
(zweimal reicht meistens, dreimal ist sicherer, wenn Referenzen/Inhaltsverzeichnis
sich noch verschieben – siehe unten unter „Referenzen brauchen 2–3 Durchläufe").

## Org-Mode vs. LaTeX: was ist anders und worauf muss man achten?

Wer bisher nur reines LaTeX geschrieben hat, stolpert typischerweise über
folgende Punkte. Alle hier beschriebenen Probleme sind in diesem Repository
tatsächlich aufgetreten und wurden behoben – diese Liste ist also keine
Theorie, sondern eine Fehlersammlung aus der Praxis.

### 1. Rohes LaTeX/TikZ in Org braucht saubere Grenzen

Ein `\begin{tikzpicture}…\end{tikzpicture}` wird von Org nur dann **verbatim**
(unverändert) durchgereicht, wenn es eine eigenständige Zeile ist. Steht nach
`\end{...}` **auf derselben Zeile** noch weiterer Text – und sei es nur ein
`\\` für einen Zeilenumbruch –, erkennt Org das Environment nicht mehr als
reines LaTeX und wendet seine normale Textverarbeitung darauf an. Das
escaped z. B. geschweifte Klammern (`{` → `\{`) und zerstört damit jede
TikZ-Grafik unsichtbar (kein Fehler beim Export, aber kaputte Ausgabe).

```org
❌ \end{tikzpicture}\\
✅ \end{tikzpicture}

   \\
```

**Faustregel:** Wenn ein TikZ-/LaTeX-Block mehr als eine Zeile Kontext braucht
oder in eine Tabelle/Spalten eingebettet ist, lieber direkt in
`#+BEGIN_EXPORT latex … #+END_EXPORT` wrappen. Das ist immer robust,
unabhängig von Leerzeilen davor/danach oder Inhalt in derselben Zeile.

### 2. Mehrspalten-Layout (`\begin{columns}`) hat keine native Org-Entsprechung

Beamer-Folien mit zwei Spalten (Text + Bild/Diagramm nebeneinander) lassen
sich in Org nicht sauber über Überschriften-Eigenschaften abbilden, ohne dass
es fragil wird. Der zuverlässige Weg ist auch hier ein reiner
`#+BEGIN_EXPORT latex`-Block mit dem kompletten `\begin{columns}…\end{columns}`
darin – exakt wie im Original-LaTeX.

### 3. `#+INCLUDE` und Beamer-Frame-Level

`#+OPTIONS: H:N` legt fest, ab welcher (absoluten) Org-Überschriftenebene
Inhalte zu Beamer-**Frames** werden (`org-beamer-frame-level`, Standard `1`).
`#+INCLUDE: "datei.org" :minlevel M` verschiebt alle Überschriften der
eingebundenen Datei so, dass ihre **flachste** Überschrift auf Ebene `M`
landet – und zwar bezogen auf die flachste Überschrift **in der ganzen
Datei**, nicht nur auf die, die man gerade vor Augen hat. Enthält eine Datei
irgendwo eine flachere Zwischenüberschrift (z. B. für eine Untergliederung),
verschiebt das die Referenzebene für die **gesamte** Datei.

Folge: Passt `M` nicht exakt zum tatsächlichen `H:N`, werden Folieninhalte
nicht als `\begin{frame}` erkannt, sondern nur als Abschnitts-/Subsection-Text
– die Folien bleiben dann optisch komplett leer. Nach jeder Strukturänderung
(neue Datei eingebunden, Überschriftenebene geändert) unbedingt den
Export-Output kontrollieren (siehe „Kontrolle nach Änderungen" unten): Ein
`grep -c "begin{frame}" AuFS.tex` sollte eine plausible, nicht winzige Zahl
liefern.

### 4. Eigene Dokumentklassen (KOMA-Script etc.) sind Org unbekannt

Org kennt von Haus aus nur `article`, `report`, `book` und `beamer`
(`org-latex-classes`). `#+LATEX_CLASS: scrartcl` (wie in `exercises/*.org`)
scheitert deshalb mit `Unknown LaTeX class 'scrartcl'`, **außer** die Klasse
wurde zuvor per Emacs-Lisp registriert. Dafür gibt es hier
`exercises/org-export-setup.el`, die per `emacs --batch -l ./org-export-setup.el …`
geladen werden **muss** – ohne diesen Schritt schlägt der Export fehl. Diese
Datei registriert außerdem einen Workaround für einen bekannten Konflikt
zwischen dem Paket `capt-of` (das Org standardmäßig lädt) und KOMA-Script-Klassen
(`Command \captionof already defined`).

**Warnung:** Diese Art Klassen-Registrierung landet in vielen Anleitungen im
Netz als Empfehlung, sie in die persönliche `~/.emacs`/`init.el` zu schreiben.
**Das darf hier nicht passieren** – jede Abhängigkeit von einer privaten
Konfiguration macht den Export auf jedem anderen Rechner und in CI
unreproduzierbar. Neue Klassen/Pakete gehören entweder in eine
projekteigene `.el`-Datei (wie hier) oder direkt als `#+LATEX_HEADER:`-Zeile
in die betroffene `.org`-Datei.

### 5. `babel[ngerman]` und das Anführungszeichen `"`

Mit `\usepackage[ngerman]{babel}` wird `"` zu einem **aktiven Zeichen**
(babel-„Shorthand", u. a. für `"a`/`"s` etc. als Umlaut-/ß-Kurzschreibweisen).
Ein ganz normales gerades Anführungszeichen im Fließtext wie `"Studenten"`
wird dadurch **stillschweigend verstümmelt** (wurde in diesem Repository zu
„SStudenten", kein Fehler, keine Warnung – nur falscher Text im PDF!).

Fix: `\shorthandoff{"}` **im Dokumentkörper** (nicht in der Präambel – dort
wirkungslos, da Babel die Shorthands erst bei `\begin{document}` aktiviert).
Ist in `AuFS.org` und allen `exercises/*.org` bereits als
`#+BEGIN_EXPORT latex`-Block bzw. `#+LATEX_HEADER:`-Zeile vorhanden. Wer neue
Dateien/Abschnitte mit deutschen Anführungszeichen ergänzt: entweder auf
echte typografische Zeichen `„…"` zurückgreifen (funktioniert immer,
unabhängig von Babel) oder sicherstellen, dass `\shorthandoff{"}` weiterhin
geladen wird.

### 6. Bare Bild-Links werden zu Download-Versuchen

`[[https://…irgendwas.jpg]]` (ein Link **ohne** Beschreibungstext, dessen Ziel
auf eine Bild-Dateiendung endet) wird von Org als **einzubettendes Bild**
interpretiert – Org versucht dann, die URL herunterzuladen und als Grafik
einzubinden. Das führte hier zu Fehlern wie „Division by 0" (weil die
„heruntergeladene Datei" in Wahrheit eine HTML-Seite war), und in CI würde
so ein Link außerdem an der Sicherheitsabfrage `org-safe-remote-resources`
scheitern (die nur lokal, personenbezogen, freigeschaltet ist).

Fix: Bei reinen Quellenangaben/Zitat-Links **immer** einen Beschreibungstext
angeben, dann bleibt es ein normaler Link statt eines Bild-Embeds:

```org
❌ [[https://commons.wikimedia.org/wiki/File:Foo.jpg]]
✅ [[https://commons.wikimedia.org/wiki/File:Foo.jpg][Quelle: Wikimedia Commons]]
```

### 7. Bildgröße: `width=` allein reicht oft nicht

`#+ATTR_LATEX: :width 0.9\linewidth` auf einem Hochformat-Foto in einer breiten
16:9-Beamer-Folie kann trotzdem über den unteren Folienrand hinauslaufen, weil
nur die Breite begrenzt wird – die resultierende Höhe kann die verfügbare
Folienhöhe übersteigen. Im Original-Layout stehen solche Porträts meist ohnehin
in einer schmalen Spalte neben dem Text (siehe Punkt 2); wo das nicht geht,
zusätzlich `:height` begrenzen, z. B. `:height 0.45\textheight`.

### 8. Cross-Referenzen: `CUSTOM_ID` statt `\label`/`\pageref`

Um innerhalb der Folien auf eine andere Folie zu verweisen, bekommt die
Ziel-Überschrift eine `:CUSTOM_ID:`-Property, und referenziert wird per
Org-Link `[[#custom-id]]`. Ein zusätzliches, von Hand eingefügtes
`\pageref{custom-id}` funktioniert **nicht** – Org erzeugt beim Export ein
eigenes, anderes internes Label (`sec:orgXXXXXXX`), das nie mit dem
`CUSTOM_ID`-Namen übereinstimmt. Ein `\pageref{meine-id}` bliebe dauerhaft
`??` im PDF bzw. wirft „undefined reference". Nur der Org-Link selbst ist
nötig; er wird automatisch zum passenden `\ref{}` aufgelöst.

### 9. Referenzen brauchen 2–3 Durchläufe

Wie in reinem LaTeX auch: Quer- und Vorwärtsverweise (`\ref`, `\pageref`,
Inhaltsverzeichnis) sind erst nach mehreren Kompilierdurchläufen korrekt,
weil sie aus der `.aux`-Datei des *vorherigen* Laufs gelesen werden.
`latexmk` erledigt das automatisch (es wiederholt, bis sich nichts mehr
ändert); bei manuellem `pdflatex`-Aufruf mindestens zweimal, bei größeren
Dokumenten (wie `AuFS.tex` mit über 130 Seiten) im Zweifel dreimal aufrufen.
Eine einzelne „Reference … undefined"-Warnung *im ersten* Durchlauf ist
normal und kein Bug – erst wenn sie nach dem **letzten** Durchlauf noch
auftaucht, ist etwas wirklich kaputt.

### 10. Stray-Unicode-Zeichen können den Build hart abbrechen lassen

Ein einzelnes, unsichtbares Kopier-Artefakt (z. B. ein "combining mark" wie
U+0304 oder ein Zero-Width-Space U+200B mitten in einer Tabellenzelle) reicht,
um `pdflatex` mit `LaTeX Error: Unicode character … not set up for use with
LaTeX` komplett abbrechen zu lassen – während manche Alternative Engines
(z. B. `tectonic`) das stillschweigend tolerieren und so den Fehler verdecken.
**Deshalb immer mit dem tatsächlichen Ziel-Toolchain (pdflatex/latexmk aus
TeX Live) testen, nicht nur mit einem alternativen Renderer.** Bei
mysteriösen Fehlern an einer Stelle, die im Editor unauffällig aussieht,
lohnt ein Blick mit `cat -A datei.org | grep <Zeile>` oder ein kleines
Python-Snippet, das den Text nach Zeichen jenseits von `U+2000` mit
Unicode-Kategorie `Mn`/`Mc`/`Cf` durchsucht.

## Kontrolle nach Änderungen

Kurzer Check, der die meisten der obigen Probleme sofort auffallen lässt,
bevor man überhaupt kompiliert:

```bash
# Wie viele Frames erkennt der Export wirklich? (sollte nicht plötzlich einbrechen)
grep -c "begin{frame}" AuFS.tex

# Tauchen escapte geschweifte Klammern auf, wo eigentlich Mathe stehen sollte?
grep -n '\\{\\(' AuFS.tex

# Bleiben nach dem letzten Kompilierlauf noch offene Referenzen?
grep -i "undefined" AuFS.log | tail
```

Und am Ende immer eine visuelle Kontrolle des PDFs (mind. die Folien mit
Bildern, Tabellen und TikZ-Diagrammen), da nicht jeder Fehler eine
Compiler-Warnung erzeugt – wie die Beispiele oben zeigen, kann eine Folie
optisch komplett falsch aussehen, ohne dass LaTeX sich beschwert.
