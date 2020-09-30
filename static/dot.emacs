;;
;; Custom elisp directory
;;
(let ((dir (format "%s/.elisp.d" (getenv "HOME"))))
  (if (file-exists-p dir) (add-to-list 'load-path dir t)))

(require 'xcscope "xcscope" t)
(require 'tuareg)
(require 'font-lock)
(setq viper-mode t)
(require 'viper)

;; A boolean that is true if the current user is logged in from a UNH
;; AI research machine.
(setq logged-in-from-ai-machine
      (or (equal (getenv "HOME") (format "/home/aifs2/%s" (getenv "USER")))
	  (equal (getenv "HOME") (format "/home/aifs1/%s" (getenv "USER")))))

;;
;; Environment
;;
;; Add ~/bin to PATH.
(setenv "PATH"
	(format "%s:%s/bin" (getenv "PATH") (getenv "HOME")))
(setenv "LD_LIBRARY_PATH"
	(format "/usr/local/lib:/usr/local/lib64:%s/lib" (getenv "HOME")))
(setenv "LDFLAGS" "-L/usr/local/lib")
(if logged-in-from-ai-machine
    ;; If logged on from a AI machine, add some paths
    (setenv "PATH" (format "%s:%s:%s:%s"
			   "/home/aifs2/ruml/bin"
			   "/home/aifs2/group/bin"
			   "/home/aifs2/group/bin/x86_64-linux"
			   (getenv "PATH"))))

;;
;; Make the *scratch* buffer use tuareg-mode for OCaml instead of
;; lisp-interaction-mode.
;;
(setq initial-scratch-message
      "(* This buffer is for notes you don't want to save, and for OCaml
   evaluation.  If you want to create a file, visit that file with C-x
   C-f, then enter the text in that file's own buffer. *)
")
(setq initial-major-mode 'tuareg-mode)

;;
;; Customizations
;;
(server-start)
(iswitchb-mode)				       ; Better read-buffer
(global-set-key "\C-xb" 'electric-buffer-list) ; Electric buffer list
(global-set-key "\C-x\C-b" 'switch-to-buffer)  ; Switch to buffer
(global-set-key "\M-`" 'font-lock-fontify-buffer) ; Fix color issues
(global-auto-revert-mode t)	  ; Automatically update changed buffs
(setq cscope-allow-arrow-overlays nil)	; Do not show an => overlay
(set-default-file-modes #o775)		; Set the umask to 0002
(setq woman-use-own-frame nil)	   ; Don't open WoMan in another frame
(setq flyspell-issue-welcome-flag nil)	; fixes a bug in flyspell
(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(browse-url-browser-function (quote browse-url-generic))
 '(browse-url-generic-program "google-chrome")
 '(column-number-mode t)
 '(compile-command "~/src/ai/ocm2/ocm2.byte -j 6")
 '(default-major-mode (quote text-mode))
 '(display-time-day-and-date t)
 '(display-time-mode t)
 '(fringe-mode 0 nil (fringe))
 '(grep-command "grep -Irn ")
 '(inhibit-startup-screen 1)
 '(line-number-mode t)
 '(make-backup-files nil)
 '(menu-bar-mode nil)
 '(require-final-newline t)
 '(tool-bar-mode nil)
 '(transient-mark-mode nil)
 '(visible-bell t))

;;
;; GUI configuration (for non-terminal mode)
;;
(if (not (eq window-system nil))
    ((lambda ()
       (add-to-list 'default-frame-alist '(vertical-scroll-bars . nil))
       (if logged-in-from-ai-machine
	   (add-to-list 'default-frame-alist '(font . "9x15"))
	 (add-to-list 'default-frame-alist '(font . "7x14")))
       (add-to-list 'default-frame-alist '(height . 72))
       (add-to-list 'default-frame-alist '(width . 80)))))


;;
;; Mercurial
;;
(if (boundp 'viper-mode)
    ;; Don't ask if a file (backed by a mercurial repository) should
    ;; be checked out every time it is saved.
    (defadvice viper-maybe-checkout (around viper-hg-checkin-fix activate)
      "Advise viper-maybe-checkout to ignore Hg files."
      (let ((file (expand-file-name (buffer-file-name buf))))
	(when (and (featurep 'vc-hooks)
		   (not (memq (vc-backend file) '(nil Hg))))
	  ad-do-it))))

;;
;; Subversion
;;
(if (boundp 'viper-mode)
    (defadvice viper-maybe-checkout (around viper-svn-checkin-fix activate)
      "Advise viper-maybe-checkout to ignore svn files."
      (let ((file (expand-file-name (buffer-file-name buf))))
	(when (and (featurep 'vc-hooks)
		   (not (memq (vc-backend file) '(nil SVN))))
	  ad-do-it))))

;;
;; Dired
;;
(setq dired-recursive-deletes t)	; It will ask at each dir
(if (boundp 'viper-mode)
    ;; Change the keymap in dired-mode to use some more VI friendly
    ;; bindings
    (progn (setq viper-dired-mode-map (make-sparse-keymap))
	   (define-key viper-dired-mode-map "j" 'dired-next-line)
	   (define-key viper-dired-mode-map "J" 'dired-goto-file)
	   (define-key viper-dired-mode-map "k" 'dired-previous-line)
	   (define-key viper-dired-mode-map "K" 'dired-do-kill-lines)
	   (viper-modify-major-mode
	    'dired-mode
	    'emacs-state viper-dired-mode-map)))


;;
;; LaTeX
;;
(let ((rubber (executable-find "rubber")))
  (if (and rubber (file-executable-p rubber))
      (setq latex-run-command (format "%s --ps --pdf *" rubber))))


;;
;; eshell initialization
;;
(add-hook 'eshell-mode-hook
          '(lambda ()
	     (setenv "EDITOR" "/usr/bin/emacsclient")
	     (setenv "OCAMLRUNPARAM" "b")
	     (setenv "PAGER" "")))
(setq eshell-save-history-on-exit t)


;;
;; C
;;
(add-hook 'c-mode-common-hook
	  (lambda ()
	    (local-set-key (kbd "<tab>") 'tab-to-tab-stop)
	    (setq-default c-electric-flag nil)
	    (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)
	    (setq show-trailing-whitespace t)
	    (c-set-style "linux")
	    (show-paren-mode 1)))


;;
;; text mode
;;
(add-hook 'text-mode-hook
	  (lambda ()
	    (auto-fill-mode 1)
	    (show-paren-mode 1)
	    (flyspell-mode 1)
	    (local-set-key (kbd "<tab>") 'tab-to-tab-stop)
	    (setq show-trailing-whitespace t)))


;;
;; OCaml
;;

(setq auto-mode-alist (cons '("\\.ml\\w?" . tuareg-mode) auto-mode-alist))
(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(autoload 'camldebug "camldebug" "Run the Caml debugger" t)

(add-hook 'tuareg-mode-hook
	  (lambda ()
	    (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)
	    ;; auto-fill-mode is broken in viper-mode with tuareg
	    (if (not (boundp 'viper-mode)) (auto-fill-mode 1))
	    (show-paren-mode 1)
	    (setq show-trailing-whitespace t)))

(if logged-in-from-ai-machine
    ;; If logged in from a RAI machine, use the RAI ocaml top.
    (setq tuareg-interactive-program
	  "/home/aifs2/group/bin/x86_64-linux/ocamltopcairo"))

;;
;; TLA+
;;
(if (require 'tla-mode nil t)
    (setq auto-mode-alist (append '(("\\.tla$" . tla-mode)) auto-mode-alist)))

;;
;; PDDL
;;
(setq auto-mode-alist (append '(("\\.pddl$" . lisp-mode)) auto-mode-alist))

;;
;; Go programming language
;;
(if (require 'go-mode-load nil t)
    (progn
      (add-hook
       'go-mode-hook
       (lambda ()
	 (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)
	 (local-set-key (kbd "<tab>") 'tab-to-tab-stop)
	 (setq show-trailing-whitespace t)))
      (setenv "GOROOT" (format "%s/go" (getenv "HOME")))
      (setenv "GOPATH" (format "%s/src/go" (getenv "HOME")))
      (setenv "PATH" (format "%s:%s/go/bin" (getenv "PATH") (getenv "HOME")))))

;;
;; Promela
;;
(if (require 'promela-mode nil t)
    (progn
      (setq auto-mode-alist
	    (append
	     (list (cons "\\.promela$"  'promela-mode)
		   (cons "\\.spin$"     'promela-mode)
		   (cons "\\.pml$"      'promela-mode)
		   )
	     auto-mode-alist))
      (setq promela-auto-match-delimiter nil)))

;;
;; Customized colors
;;
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(font-lock-builtin-face ((((class color) (min-colors 88) (background light)) (:foreground "Black"))))
 '(font-lock-comment-face ((((class color) (min-colors 88) (background light)) (:foreground "DarkGray"))))
 '(font-lock-doc-face ((t (:inherit font-lock-comment-face))))
 '(font-lock-function-name-face ((((class color) (min-colors 88) (background light)) (:inherit font-lock-variable-name-face))))
 '(font-lock-keyword-face ((((class color) (min-colors 88) (background light)) (:foreground "dark slate gray" :weight bold))))
 '(font-lock-string-face ((((class color) (min-colors 88) (background light)) (:foreground "darkred"))))
 '(font-lock-type-face ((((class color) (min-colors 88) (background light)) (:inherit font-lock-keyword-face))))
 '(font-lock-variable-name-face ((((class color) (min-colors 88) (background light)) (:foreground "dodgerblue3"))))
 '(promela-fl-send-poll-face ((t (:background "white"))) t)
 '(tuareg-font-lock-governing-face ((t (:inherit font-lock-keyword-face :foreground "dark slate gray" :weight bold))))
 '(tuareg-font-lock-operator-face ((((background light)) nil))))
