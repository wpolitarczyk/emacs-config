;;; init.el --- Główny punkt startowy Emacsa -*- lexical-binding: t -*-

;; Drop into debugger immediately on C-g or SIGINT
(setq debug-on-quit t)

;; Zezwól na zwężanie buforów (włączona domyślnie wyłączona funkcja)
(put 'narrow-to-region 'disabled nil)

;; Ścieżki do plików konfiguracji
(defvar my-config-org (expand-file-name "config.org" user-emacs-directory))
(defvar my-config-el (expand-file-name "config.el" user-emacs-directory))

;; Optymalizacja czasu uruchamiania:
;; Załaduj pakiet 'org' i wygeneruj kod TYLKO wtedy, gdy plik .org jest nowszy
;; niż wygenerowany wcześniej plik .el, lub gdy plik .el jeszcze nie istnieje.
(when (or (not (file-exists-p my-config-el))
          (file-newer-than-file-p my-config-org my-config-el))
  (require 'org)
  (org-babel-load-file my-config-org))

;; Wczytaj wygenerowany plik (bardzo szybka operacja, bez angażowania org-mode)
(load-file my-config-el)
