;; Registriert die scrartcl-Dokumentklasse für den Org->LaTeX-Export der
;; Übungsblätter. Ohne dies bricht der Export mit "Unknown LaTeX class
;; `scrartcl'" ab, da Org von Haus aus nur article/report/book/beamer kennt.
;; Wird sowohl lokal als auch in der CI per `emacs --batch -l org-export-setup.el`
;; geladen, damit der Export nicht von einer privaten ~/.emacs abhängt.
(require 'ox-latex)
(add-to-list 'org-latex-classes
             '("scrartcl"
               "\\documentclass[11pt]{scrartcl}"
               ("\\section{%s}" . "\\section*{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
               ("\\paragraph{%s}" . "\\paragraph*{%s}")
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

;; KOMA-Script-Klassen (scrartcl/scrbook/...) definieren \captionof bereits
;; selbst; das von Org standardmäßig geladene capt-of-Paket kollidiert damit
;; ("Command \captionof already defined"). Wird hier nicht gebraucht (keine
;; Bilder/Floats in den Übungsblättern) und daher aus der Default-Liste entfernt.
(setq org-latex-default-packages-alist
      (seq-remove (lambda (entry) (equal (nth 1 entry) "capt-of"))
                  org-latex-default-packages-alist))
