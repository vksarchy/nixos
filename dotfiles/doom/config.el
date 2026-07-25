;; Profile startup
;; (add-hook 'emacs-startup-hook
;;           (lambda ()
;;             (message "*** Emacs loaded in %s with %d garbage collections."
;;                      (format "%.2f seconds"
;;                              (float-time
;;                               (time-subtract after-init-time before-init-time)))
;;                      gcs-done)))

;; ;; For detailed profiling, temporarily add:
;; (setq use-package-verbose t)

;; Seeing cost of startup modules - Debug mode
;; (setq doom-debug-p t)
(remove-hook 'doom-load-theme-hook #'doom-themes-org-config)

(after! org
  (doom-themes-org-config))

;; GC is managed by Doom's gcmh — huge manual thresholds cause long
;; multi-hundred-ms pauses when collection finally happens.

;; Reduce startup noise
(setq inhibit-compacting-font-caches t
      inhibit-startup-screen t
      initial-scratch-message nil
      frame-inhibit-implied-resize t)  ; Critical for X11

;; Make EVERY package defer by default
(setq use-package-always-defer t
      use-package-expand-minimally t)  ; Faster macro expansion

(setq doom-incremental-idle-timer 10.0)  ; Increase from default 1.0
(setq doom-incremental-first-idle-timer 5.0)  ; Increase from default 0.5

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
(setq doom-font (font-spec :family "SauceCodePro Nerd Font" :size 20)
      doom-variable-pitch-font (font-spec :family "Alegreya" :size 18)
      doom-big-font (font-spec :family "SauceCodePro Nerd Font" :size 24))
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(add-to-list 'custom-theme-load-path "~/.config/doom/themes/")
;; (load-theme 'compline -t)
(setq doom-theme 'doom-one)

;; Maintain terminal transparency in Doom Emacs
(after! doom-themes
  (unless (display-graphic-p)
    (set-face-background 'default "undefined")))

;; remove top frame bar in emacs
(add-to-list 'default-frame-alist '(undecorated . t))

(setq doom-modeline-icon t)
(setq doom-modeline-major-mode-icon t)
(setq doom-modeline-lsp-icon t)
(setq doom-modeline-major-mode-color-icon t)

;; Transparency
(set-frame-parameter (selected-frame) 'alpha '(95 . 96))
(add-to-list 'default-frame-alist '(alpha . (94 . 96)))

;; Blink cursor
(blink-cursor-mode 1)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Line wrapping — only where it matters; global-visual-line-mode adds
;; per-redisplay cost to every buffer (magit, dired, vterm, code).
(add-hook 'text-mode-hook #'visual-line-mode)

;; Send files to trash instead of fully deleting
(setq delete-by-moving-to-trash t)
;; Save automatically
(setq auto-save-default t)

;; Performance optimizations
(setq read-process-output-max (* 4 1024 1024))
(setq native-comp-async-jobs-number 8)

;; lsp-ui sideline re-renders on every cursor move; doc popups on hover
;; cause stutter. Peek (M-x lsp-ui-peek-*) still available.
(after! lsp-ui
  (setq lsp-ui-sideline-enable nil
        lsp-ui-doc-enable nil))
(after! lsp-mode
  (setq lsp-idle-delay 0.5
        lsp-log-io nil))

;; Version control optimization
(setq vc-handled-backends '(Git))

;; Fix x11 issues
(setq x-no-window-manager t)
(setq frame-inhibit-implied-resize t)
(setq focus-follows-mouse nil)

(after! evil
  ;; Movement: h n e i (left down up right)
  (evil-define-key* '(normal motion visual) 'global
    "n" #'evil-next-line
    "e" #'evil-previous-line)
  (evil-define-key 'normal 'global (kbd "i") #'evil-forward-char)
  (evil-define-key 'visual 'global (kbd "i") #'evil-forward-char)
  ;; Restore i as inner text object in operator-pending
  (evil-define-key* 'operator 'global
    "i" evil-inner-text-objects-map)
  ;; End-of-word: k = e, K = E
  (evil-define-key* '(normal motion visual operator) 'global
    "k"  #'evil-forward-word-end
    "K"  #'evil-forward-WORD-end
    "gk" #'evil-backward-word-end
    "gK" #'evil-backward-WORD-end)
  ;; Search navigation: l = n, L = N
  (evil-define-key* '(normal motion visual operator) 'global
    "l" #'evil-ex-search-next
    "L" #'evil-ex-search-previous)
  ;; Join lines: j = J
  (evil-define-key* 'normal 'global
    "j" #'evil-join)
  ;; ; = :
  (evil-define-key* 'normal 'global
    ";" #'evil-ex)
  ;; Fast scroll: N = 5j, E = 5k
  (evil-define-key* '(normal visual) 'global
    "N" (lambda () (interactive) (evil-next-line 5))
    "E" (lambda () (interactive) (evil-previous-line 5)))
  ;; Visual line motion
  (evil-define-key* '(normal visual) 'global
    "gn" #'evil-next-visual-line
    "ge" #'evil-previous-visual-line))

(after! evil-org
  (evil-define-key* '(normal motion visual) evil-org-mode-map
    "i" #'evil-forward-char))

;; Insert mode via SPC i i
(map! :leader
      (:prefix "i"
       :desc "Enter insert mode" "i" #'evil-insert))

(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-footer)

;; Your splash image
;; (setq fancy-splash-image "~/Pictures/Wallpapers/isha.png")

;; Custom footer with Shiva symbol
(defun +my/dashboard-footer ()
  (insert "\n\n")
  (let ((start (point)))
    (insert (+doom-dashboard--center
             +doom-dashboard--width
             (propertize "ॐ திருச்சிற்றம்பலம் " 'face '(:height 1.3 :inherit doom-dashboard-footer-icon))))
    (make-text-button start (point)
                      'follow-link t
                      'help-echo "Visit Kappini Realty"
                      'face 'doom-dashboard-footer-icon
                      'mouse-face 'highlight))
  (insert "\n"))


;; Hook everything in order
(add-hook! '+doom-dashboard-functions :append
  #'+my/dashboard-footer
  (insert "\n" (+doom-dashboard--center +doom-dashboard--width "Welcome Home, Bravo 1.")))

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
                                        ;(require 'org-mime)

;; set specific browser to open links
;;(setq browse-url-browser-function 'browse-url-firefox)
;; set browser to firefox
(setq browse-url-browser-function 'browse-url-generic)
(setq browse-url-generic-program "brave")  ; replace with actual executable name

;; Speed of which-key popup
(setq which-key-idle-delay 0.2)

;; Completion mechanisms (commented out as they interfere with vertico)
;; (setq completing-read-function #'completing-read-default)
;; (setq read-file-name-function #'read-file-name-default)
;; Makes path completion more like find-file everywhere
(setq read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t
      completion-ignore-case t)
;; Use the familiar C-x C-f interface for directory completion
(map! :map minibuffer-mode-map
      :when (modulep! :completion vertico)
      "C-x C-f" #'find-file)

;; Save minibuffer history - enables command history in M-x
(use-package! savehist
  :config
  (setq savehist-file (concat doom-cache-dir "savehist")
        savehist-save-minibuffer-history t
        history-length 1000
        history-delete-duplicates t
        savehist-additional-variables '(search-ring
                                        regexp-search-ring
                                        extended-command-history))
  (savehist-mode 1))

(after! vertico
  ;; Add file preview
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)
  (define-key vertico-map (kbd "DEL") #'vertico-directory-delete-char)
  (define-key vertico-map (kbd "M-DEL") #'vertico-directory-delete-word)
  ;; Make vertico use a more minimal display
  (setq vertico-count 17
        vertico-cycle t
        vertico-resize t)
  ;; Enable alternative filter methods
  (setq vertico-sort-function #'vertico-sort-history-alpha)
  ;; Quick actions keybindings
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "M-RET") #'vertico-exit-input)

  ;; History navigation
  (define-key vertico-map (kbd "M-p") #'vertico-previous-history)
  (define-key vertico-map (kbd "M-n") #'vertico-next-history)
  (define-key vertico-map (kbd "C-r") #'consult-history)

  ;; Configure orderless for better filtering
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion orderless))))

  ;; Customize orderless behavior
  (setq orderless-component-separator #'orderless-escapable-split-on-space
        orderless-matching-styles '(orderless-literal
                                    orderless-prefixes
                                    orderless-initialism
                                    orderless-flex
                                    orderless-regexp)))

;; Quick command repetition
(use-package! vertico-repeat
  :after vertico
  :config
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)
  (map! :leader
        (:prefix "r"
         :desc "Repeat completion" "v" #'vertico-repeat)))

;; TODO Not currently working
;; Enhanced sorting and filtering with prescient
;; (use-package! vertico-prescient
;;   :after vertico
;;   :config
;;   (vertico-prescient-mode 1)
;;   (prescient-persist-mode 1)
;;   (setq prescient-sort-length-enable nil
;;         prescient-filter-method '(literal regexp initialism fuzzy)))

;; Enhanced marginalia annotations
(after! marginalia
  (setq marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  ;; Show more details in marginalia
  (setq marginalia-max-relative-age 0
        marginalia-align 'right))

;; Corrected Embark configuration
(map! :leader
      (:prefix ("k" . "embark")  ;; Using 'k' prefix instead of 'e' which conflicts with elfeed
       :desc "Embark act" "a" #'embark-act
       :desc "Embark dwim" "d" #'embark-dwim
       :desc "Embark collect" "c" #'embark-collect))

;; Configure consult for better previews
(after! consult
  (setq consult-preview-key "M-."
        consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /   --smart-case --no-heading --with-filename --line-number --search-zip"
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay 0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)

  ;; More useful previews for different commands
  (consult-customize
   consult-theme consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   :preview-key '(:debounce 0.4 any)))

;; Enhanced directory navigation
(use-package! consult-dir
  :bind
  (("C-x C-d" . consult-dir)
   :map vertico-map
   ("C-x C-d" . consult-dir)
   ("C-x C-j" . consult-dir-jump-file)))

;; Add additional useful shortcuts
(map! :leader
      (:prefix "s"
       :desc "Command history" "h" #'consult-history
       :desc "Recent directories" "d" #'consult-dir))

(after! company
  (setq company-minimum-prefix-length 2
        company-idle-delay 0.2
        company-show-quick-access t
        company-tooltip-limit 20
        company-tooltip-align-annotations t)

  ;; Make company-files a higher priority backend
  (setq company-backends (cons 'company-files (delete 'company-files company-backends)))

  ;; Better file path completion settings
  (setq company-files-exclusions nil)
  (setq company-files-chop-trailing-slash t)

  ;; Enable completion at point for file paths
  (defun my/enable-path-completion ()
    "Enable file path completion using company."
    (setq-local company-backends
                (cons 'company-files company-backends)))

  ;; Enable for all major modes
  (add-hook 'after-change-major-mode-hook #'my/enable-path-completion)

  ;; Custom file path trigger
  (defun my/looks-like-path-p (input)
    "Check if INPUT looks like a file path."
    (or (string-match-p "^/" input)         ;; Absolute path
        (string-match-p "^~/" input)        ;; Home directory
        (string-match-p "^\\.\\{1,2\\}/" input))) ;; Relative path

  (defun my/company-path-trigger (command &optional arg &rest ignored)
    "Company backend that triggers file completion for path-like input."
    (interactive (list 'interactive))
    (cl-case command
      (interactive (company-begin-backend 'company-files))
      (prefix (when (my/looks-like-path-p (or (company-grab-line "\\([^ ]*\\)" 1) ""))
                (company-files 'prefix)))
      (t (apply 'company-files command arg ignored))))

  ;; Add the custom path trigger to backends
  (add-to-list 'company-backends 'my/company-path-trigger))

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org")

;; (use-package org
;;   :defer t 
;;   :custom (org-modules '(org-habit)))

(after! org
  (setq org-modules '(org-habit))

  (map! :map org-mode-map
        :n "<M-left>" #'org-do-promote
        :n "<M-right>" #'org-do-demote)
  )

;; Auto-clock in when state changes to STRT
(defun my/org-clock-in-if-starting ()
  "Clock in when the task state changes to STRT"
  (when (and (string= org-state "STRT")
             (not (org-clock-is-active)))
    (org-clock-in)))

;; Auto-clock out when leaving STRT state
(defun my/org-clock-out-if-not-starting ()
  "Clock out when leaving STRT state"
  (when (and (org-clock-is-active)
             (not (string= org-state "STRT")))
    (org-clock-out)))

;; Add these functions to org-after-todo-state-change-hook
(add-hook 'org-after-todo-state-change-hook 'my/org-clock-in-if-starting)
(add-hook 'org-after-todo-state-change-hook 'my/org-clock-out-if-not-starting)

;; (after! org
;;   (use-package! org-fancy-priorities
;;     :hook
;;     (org-mode . org-fancy-priorities-mode)
;;     :config
;;     (setq org-fancy-priorities-list '("HIGH" "MID" "LOW" "FUTURE"))))

;; Prevent clock from stopping when marking subtasks as done
(setq org-clock-out-when-done nil)

;; Org-auto-tangle
(use-package org-auto-tangle
  :defer t
  :hook (org-mode . org-auto-tangle-mode)
  :config
  (setq org-auto-tangle-default t))

;; Org agenda scanning recursively 
(after! org
  (setq org-agenda-files
        (seq-filter
         (lambda (f) (not (string-match-p
                           "\\(template\\|roam/literature\\|roam/permanent\\|roam/fleeting\\|roam/essay\\|brevity\\|master_key\\)"
                           f)))
         (directory-files-recursively "~/org" "\\.org$"))))

;; Time grid configuration - 5 AM to 9 PM
(setq org-agenda-time-grid
      '((daily today require-timed)
        (500 600 700 800 900 1000 1100 1200 
         1300 1400 1500 1600 1700 1800 1900 2000 2100)
        "      " "────────────────"))

(setq org-agenda-current-time-string
      "◀── NOW ────────────────────────────────────────")

;; Configure habit graph display
(setq org-habit-show-habits-only-for-today t)
(setq org-habit-graph-column 50)
(setq org-agenda-remove-tags t)
(setq org-agenda-block-separator ?─)

(setq org-agenda-custom-commands
      '(("d" "Dashboard"
         ((tags "PRIORITY=\"A\""
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "\n⚡ HIGHEST PRIORITY\n")
                 (org-agenda-prefix-format "  %-12:c %t")))  ; ← fixed
          (agenda ""
                  ((org-agenda-start-day "+0d")
                   (org-agenda-span 1)
                   (org-agenda-remove-tags t)
                   (org-agenda-todo-keyword-format "")
                   (org-agenda-scheduled-leaders '("" ""))
                   (org-agenda-overriding-header "\n📅 TODAY\n")
                   (org-agenda-prefix-format "  %?-12t %s")))  ; ← fine here
          (tags-todo "-STYLE=\"habit\""
                     ((org-agenda-overriding-header "\n✓ ALL TASKS\n")
                      (org-agenda-sorting-strategy '(priority-down))
                      (org-agenda-remove-tags t)
                      (org-agenda-prefix-format "  %-12:c %t")))))))  ; ← fixed

(defun my/org-agenda-dashboard ()
  "Open the custom org-agenda dashboard."
  (interactive)
  (org-agenda nil "d"))

(after! org
  (setq org-log-done 'time)
  (setq kappini-base-dir  "~/Projects/Kappini_Realty/")
  (setq inlingua-base-dir "~/Projects/inlingua/")
  (setq org-capture-templates
        `(("c" "Commander Protocol" entry
           (file+headline "~/org/commander.org" "Protocol Executions")
           ,(concat "* COMMAND %? %<%Y-%m-%d %H:%M>\n"
                    ":PROPERTIES:\n:CREATED: %U\n:END:\n\n"
                    "** 1. PFC Pause\nDrift caught: [ ] earworm [ ] autopilot [ ] resistance\n"
                    "State before: %^{State before|drifting|autopilot|scattered|reactive|calm}\n\n"
                    "** 2. OWNERSHIP\nDeclared: This is on me. I own this.\n\n"
                    "** 3. Mission + 3 Steps + Fuckup/Fix\nMission: %^{Exact outcome}\n1. \n2. \n3. \n"
                    "Pre-empted fuckup + fix: \n\n"
                    "** 4. Execute\nStarted: %T\nFinished clean: [ ] yes [ ] no\n\n"
                    "** 5. AAR — Good.\nSupposed to happen: \nActually happened: \n"
                    "Difference (owned by me): \nSustain / Improve / Fix: \nFinal: Good.\n")
           :empty-lines 1 :clock-in t :clock-resume t)
          ("n" "Note to Inbox" entry
           (file+headline "~/org/notes.org" "Inbox")
           "* [%<%Y-%m-%d %a>] %^{Title}\n:PROPERTIES:\n:CREATED: %U\n:CAPTURED: %a\n:END:\n%?"
           :prepend t)
          ("j" "Journal" entry
           (file+olp+datetree ,(concat org-directory "/journal.org"))
           "* %<%H:%M> %^{Title}\n%U\n%?\n")
          ("i" "Idea" entry
           (file+headline "~/org/notes.org" "Ideas")
           "* %? :idea:\n%U\n")
          ("t" "Todo" entry
           (file+headline "~/org/todo.org" "TASK")
           "* TODO %^{Task}\n:PROPERTIES:\n:CREATED: %U\n:END:\n\nContext: %?\n")
          ("d" "Deadline" entry
           (file+headline "~/org/calendar.org" "Deadlines")
           "* TODO %^{Task}\nDEADLINE: %^{Deadline}t\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
           :empty-lines 1)
          ("k" "Contact" entry
           (file "~/org/roam/contacts.org")
           "* %^{Name} %^g\n:PROPERTIES:\n:ID: %(org-id-new)\n:CREATED: %U\n:CAPTURED: %a\n:EMAIL: %^{Email}\n:PHONE: %^{Phone}\n:BIRTHDAY: %^{Birthday}t\n:LOCATION: %^{Address}\n:LAST_CONTACTED: %U\n:END:\n%?"
           :empty-lines 1))))  ; ← closes `(...) and (after! org

(use-package! org-roam
  :defer t
  :commands (org-roam-node-find
             org-roam-node-insert
             org-roam-dailies-goto-today
             org-roam-buffer-toggle
             org-roam-db-sync
             org-roam-capture)
  :init
  (setq org-roam-directory "~/org/roam"
        org-roam-database-connector 'sqlite-builtin
        org-roam-db-location (expand-file-name "org-roam.db" org-roam-directory)
        org-roam-v2-ack t)
  :config
  (unless (file-exists-p org-roam-directory)
    (make-directory org-roam-directory t))
  (org-roam-db-autosync-mode 1)
  (setq org-roam-completion-everywhere t)

  ;; Templates: title + free text only (%^{...} prompts removed).
  (setq org-roam-capture-templates
        '(;; --- personal ---
          ("n" "Note" plain
           "* Core Idea\n\n%?\n\n* Connections\n- \n\n* Source\n"
           :if-new (file+head "notes/%<%Y%m%d%H%M%S>.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :note:\n\n")
           :unnarrowed t)
          
          ("p" "Person" plain
           "* Who\n\n%?\n\n* Key Ideas\n- \n\n* Works\n- \n"
           :if-new (file+head "people/${title}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :person:\n\n")
           :unnarrowed t)
          
          ("w" "Writing" plain
           "%?"
           :if-new (file+head "writing/${title}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :writing:draft:\n\n")
           :unnarrowed t)
          
          ;; --- hate (timestamp-only filename: title stays private on disk) ---
          ("a" "Hate entry" plain
           "*Target*: ${title}\n\n*Precise Description*:\n%?\n\n*Root Cause Analysis*:\n\n\n*Fuel Extraction*:\n\n\n*Action Plan*:\n- \n\n*Notes*:\n"
           :if-new (file+head "hate/%<%Y%m%d%H%M%S>.org"
                              "#+title: Hate: ${title}\n#+date: %U\n#+filetags: :hate:\n#+intensity:\n\n")
           :unnarrowed t)
          
          ;; --- HRR (calls/viewings go under the lead file, not new nodes) ---
          ("h" "HRR Lead" plain
           "* Contact\n:PROPERTIES:\n:PHONE:\n:SOURCE:\n:PRIORITY: Warm\n:STATUS: New\n:NEXT:\n:END:\n\n* Requirements\n- Budget: ₹\n- Looking for:\n- Config:\n- Locality:\n\n* Interaction Log\n** %U\n%?\n\n* Viewings\n"
           :if-new (file+head "hrr/clients/${title}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :hrr:client:\n\n")
           :unnarrowed t
           :empty-lines 1)
          
          ("r" "HRR Property" plain
           "* Specs\n:PROPERTIES:\n:LOCALITY:\n:CONFIG:\n:SQFT:\n:PRICE: ₹\n:STATUS: Active\n:OWNER:\n:OWNER_PHONE:\n:END:\n\n* Highlights\n- %?\n\n* Notes\n"
           :if-new (file+head "hrr/properties/${title}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :hrr:property:\n\n")
           :unnarrowed t)
          
          ("o" "HRR Deal" plain
           "* Offer\n:PROPERTIES:\n:CLIENT:\n:PROPERTY:\n:OFFERED: ₹\n:STATUS: Draft\n:DATE: %U\n:END:\n\n* Negotiation\n- Counter: ₹\n- Terms:\n\n* Documents Pending\n- [ ] \n\n* Next Steps\n- %?\n"
           :if-new (file+head "hrr/deals/${title}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :hrr:deal:\n\n")
           :unnarrowed t)))
  ) ; end use-package! org-roam

(use-package! org-roam-ui
  :commands (org-roam-ui-mode org-roam-ui-open)
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start nil))

;; One menu only. SPC n a is agenda — do not bind over it.
(map! :leader
      (:prefix ("H" . "roam capture")
       :desc "Lead (HRR)"     "l" (cmd! (org-roam-capture nil "h"))
       :desc "Property (HRR)" "p" (cmd! (org-roam-capture nil "r"))
       :desc "Deal (HRR)"     "d" (cmd! (org-roam-capture nil "o"))
       :desc "Hate entry"     "a" (cmd! (org-roam-capture nil "a"))
       :desc "Find node"      "f" #'org-roam-node-find
       :desc "Insert link"    "i" #'org-roam-node-insert))

;; Keybinds for org mode
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c C-i") #'my/org-insert-image)
  (define-key org-mode-map (kbd "C-c e") #'org-set-effort)
  (define-key org-mode-map (kbd "C-c i") #'org-clock-in)
  (define-key org-mode-map (kbd "C-c o") #'org-clock-out))

;; Insert image into org from selection
(defun my/org-insert-image ()
  "Select and insert an image into org file."
  (interactive)
  (let ((selected-file (read-file-name "Select image: " "~/Pictures/" nil t)))
    (when selected-file
      (insert (format "[[file:%s]]\n" selected-file))
      (org-display-inline-images))))

;; (after! org
;;   (org-babel-do-load-languages
;;    'org-babel-load-languages
;;    '((go . t)))

;;   (setq org-src-fontify-natively t
;;         org-src-preserve-indentation t
;;         org-src-tab-acts-natively t
;;         ;; Don't save source edits in temp files
;;         org-src-window-setup 'current-window))

;; ;; Specifically for go-mode literate programming
;; (defun org-babel-edit-prep:go (babel-info)
;;   (when-let ((tangled-file (->> babel-info caddr (alist-get :tangle))))
;;     (let ((full-path (expand-file-name tangled-file)))
;;       ;; Don't actually create/modify the tangled file
;;       (setq-local buffer-file-name full-path)
;;       (lsp-deferred))))

;; Evil-escape sequence
(setq-default evil-escape-key-sequence "tn")
(setq-default evil-escape-delay 0.2)

; Don't move cursor back when exiting insert mode
(setq evil-move-cursor-back nil)
;; granular undo with evil mode
(setq evil-want-fine-undo t)
;; Enable paste from system clipboard with C-v in insert mode
(evil-define-key 'insert global-map (kbd "C-v") 'clipboard-yank)

;; Vterm adjustemts
(setq vterm-environment '("TERM=xterm-256color"))
;; On NixOS, the system libvterm has transitive deps (glib, ncurses)
;; that cause build failures. Use vendored libvterm instead.
(setq vterm-module-cmake-args "-DUSE_SYSTEM_LIBVTERM=Off")
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(custom-set-faces!
  '(vterm :family "Geistmono Nerd Font"))

;; open vterm in dired location
(after! vterm
  (setq vterm-buffer-name-string "vterm %s")

  ;; Modify the default vterm opening behavior
  (defadvice! +vterm-use-current-directory-a (fn &rest args)
    "Make vterm open in the directory of the current buffer."
    :around #'vterm
    (let ((default-directory (or (and (buffer-file-name)
                                      (file-name-directory (buffer-file-name)))
                                 (and (eq major-mode 'dired-mode)
                                      (dired-current-directory))
                                 default-directory)))
      (apply fn args)))

  ;; Also modify Doom's specific vterm functions
  (defadvice! +vterm-use-current-directory-b (fn &rest args)
    "Make Doom's vterm commands open in the directory of the current buffer."
    :around #'+vterm/here
    (let ((default-directory (or (and (buffer-file-name)
                                      (file-name-directory (buffer-file-name)))
                                 (and (eq major-mode 'dired-mode)
                                      (dired-current-directory))
                                 default-directory)))
      (apply fn args))))

(defun open-vterm-in-current-context ()
  "Open vterm in the context of the current buffer/window."
  (interactive)
  (when-let ((buf (current-buffer)))
    (with-current-buffer buf
      (call-interactively #'+vterm/here))))

(defun my-open-vterm-at-point ()
  "Open vterm in the directory of the currently selected window's buffer.
This function is designed to be called via `emacsclient -e`."
  (interactive)
  (let* ((selected-window (selected-window))
         ;; Ensure selected-window is not nil before trying to get its buffer
         (buffer-in-window (and selected-window (window-buffer selected-window)))
         dir)

    (when buffer-in-window
      (setq dir
            ;; Temporarily switch to the target buffer to evaluate its context
            (with-current-buffer buffer-in-window
              (cond ((buffer-file-name buffer-in-window)
                     (file-name-directory (buffer-file-name buffer-in-window)))
                    ((and (eq major-mode 'dired-mode)
                          (dired-current-directory))
                     (dired-current-directory))
                    (t default-directory)))))

    ;; Fallback to the server's default-directory if no specific directory was found
    (unless dir (setq dir default-directory))

    (message "Opening vterm in directory: %s" dir) ; For debugging, check *Messages* buffer

    ;; Now, crucially, set 'default-directory' for the vterm call itself
    (let ((default-directory dir))
      ;; Call the plain 'vterm' function, which should respect 'default-directory'.
      ;; We are *not* passing 'dir' as an argument to 'vterm' here,
      ;; as it's often designed to pick up the current 'default-directory'.
      (vterm))))

;; Define immediately, not wrapped in after!
(defun my/new-frame-with-vterm ()
  "Create a new frame and immediately open vterm in it."
  (interactive)
  (require 'vterm)
  (let ((new-frame (make-frame '((explicit-vterm . t)))))
    (select-frame new-frame)
    (delete-other-windows)
    ;; Force vterm to take full window
    (let ((vterm-buffer (vterm (format "*vterm-%s*" (frame-parameter new-frame 'name)))))
      (switch-to-buffer vterm-buffer)
      (delete-other-windows))))  ; Nuke any splits vterm created

;; Tag initial frame
(defun my/tag-initial-frame ()
  "Tag the first frame as main."
  (set-frame-parameter nil 'main-frame t))

(add-hook 'emacs-startup-hook #'my/tag-initial-frame)

;; Vterm auto-spawn hook - skip frames we've already handled
(after! vterm
  (defun my/vterm-in-new-frame (frame)
    "Open vterm only in additional frames, not the main frame or explicit frames."
    (unless (or (frame-parameter frame 'main-frame)
                (frame-parameter frame 'explicit-vterm))
      (with-selected-frame frame
        (delete-other-windows)
        (let ((vterm-buffer (vterm (format "*vterm-%s*" (frame-parameter frame 'name)))))
          (switch-to-buffer vterm-buffer)
          (delete-other-windows)))))
  
  (add-hook 'after-make-frame-functions #'my/vterm-in-new-frame))

(use-package! treesit
  :config
  (setq treesit-language-source-alist
        '((python "https://github.com/tree-sitter/tree-sitter-python" "master" "src")))
  (defun my/install-python-treesit-grammar ()
    "Install tree-sitter grammar for Python if missing."
    (interactive)
    (unless (treesit-language-available-p 'python)
      (message "Installing Python tree-sitter grammar...")
      (treesit-install-language-grammar 'python)
      (message "Done!")))
  (setq major-mode-remap-alist
        '((python-mode . python-ts-mode))))

(after! org
  (add-to-list 'org-src-lang-modes '("python" . python-ts)))

;; Treemacs
;; (require 'treemacs-all-the-icons)
;; (setq doom-themes-treemacs-theme "all-the-icons")

(after! magit
  (defun my/quick-commit-push ()
    "Quick commit and push to origin."
    (interactive)
    (let ((msg (read-string "Commit message: ")))
      (magit-call-git "add" "-A")
      (magit-call-git "commit" "-m" msg)
      (magit-call-git "push" "--set-upstream" "origin" (magit-get-current-branch))
      (message "Committed and pushed: %s" msg))))

;; Spelling
(setq ispell-program-name "aspell")
(setq ispell-extra-args '("--sug-mode=ultra" "--lang=en_US"))
(setq spell-fu-directory "~/+STORE/dictionary") ;; Please create this directory manually.
(setq ispell-personal-dictionary "~/+STORE/dictionary/.pws")

;; Dictionary
(setq +lookup-dictionary-provider 'define-word)

;;Snippets — Doom's :editor snippets module already enables yasnippet
;;lazily; forcing yas-global-mode here loaded every snippet at startup.
(add-hook 'yas-minor-mode-hook (lambda () (yas-activate-extra-mode 'fundamental-mode)))

;; Setup writeroom width and appearance
(after! writeroom-mode
  ;; Set width for centered text
  (setq writeroom-width 40)

  ;; Ensure the text is truly centered horizontally
  (setq writeroom-fringes-outside-margins nil)
  (setq writeroom-center-text t)

  ;; Add vertical spacing for better readability
  (setq writeroom-extra-line-spacing 4)  ;; Adds space between lines

  ;; Improve vertical centering with visual-fill-column integration
  (add-hook! 'writeroom-mode-hook
    (defun my-writeroom-settings ()
      "Configure various settings when entering/exiting writeroom-mode."
      (if writeroom-mode
          (progn
            ;; When entering writeroom mode
            (display-line-numbers-mode -1)       ;; Turn off line numbers
            (setq cursor-type 'bar)              ;; Change cursor to a thin bar for writing
            (hl-line-mode -1)                    ;; Disable current line highlighting
            (setq left-margin-width 0)           ;; Let writeroom handle margins
            (setq right-margin-width 0)
            (text-scale-set 1)                   ;; Slightly increase text size

            ;; Improve vertical centering
            (when (bound-and-true-p visual-fill-column-mode)
              (visual-fill-column-mode -1))      ;; Temporarily disable if active
            (setq visual-fill-column-width 40)   ;; Match writeroom width
            (setq visual-fill-column-center-text t)
            (setq visual-fill-column-extra-text-width '(0 . 0))

            ;; Set top/bottom margins to improve vertical centering
            ;; These larger margins push content toward vertical center
            (setq-local writeroom-top-margin-size
                        (max 10 (/ (- (window-height) 40) 3)))
            (setq-local writeroom-bottom-margin-size
                        (max 10 (/ (- (window-height) 40) 3)))

            ;; Enable visual-fill-column for better text placement
            (visual-fill-column-mode 1))

        ;; When exiting writeroom mode
        (progn
          (display-line-numbers-mode +1)       ;; Restore line numbers
          (setq cursor-type 'box)              ;; Restore default cursor
          (hl-line-mode +1)                    ;; Restore line highlighting
          (text-scale-set 0)                   ;; Restore normal text size
          (when (bound-and-true-p visual-fill-column-mode)
            (visual-fill-column-mode -1))))))  ;; Disable visual fill column mode

  ;; Hide modeline for a cleaner look
  (setq writeroom-mode-line nil)

  ;; Add additional global effects for writeroom
  (setq writeroom-global-effects
        '(writeroom-set-fullscreen        ;; Enables fullscreen
          writeroom-set-alpha             ;; Adjusts frame transparency
          writeroom-set-menu-bar-lines
          writeroom-set-tool-bar-lines
          writeroom-set-vertical-scroll-bars
          writeroom-set-bottom-divider-width))

  ;; Set frame transparency
  (setq writeroom-alpha 0.95))

;; zoom in/out like we do everywhere else.
(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)

;; Custom keymaps
(map! :leader
      ;; Magit mode mappings
      (:prefix ("g" . "magit")  ; Use 'g' as the main prefix
       :desc "Stage all files"          "a" #'magit-stage-modified
       :desc "goto function definition" "d" #'evil-goto-definition
       :desc "Push"                     "P" #'magit-push
       :desc "Pull"                     "p" #'magit-pull
       :desc "Merge"                    "m" #'magit-merge
       :desc "Quick commit and push"    "z" #'my/quick-commit-push
       )
      ;; Org mode mappings
      (:prefix("y" . "org-mode-specifics")
       :desc "MU4E org mode"                    "m" #'mu4e-org-mode
       :desc "Mail add attachment"              "a" #'mail-add-attachment
       :desc "Export as markdown"               "e" #'org-md-export-as-markdown
       :desc "Preview markdown file"            "p" #'markdown-preview
       :desc "Export as html"                   "h" #'org-html-export-as-html
       :desc "Org Roam UI"                      "u" #'org-roam-ui-mode
       :desc "Search dictionary at word"        "d" #'dictionary-lookup-definition
       :desc "Powerthesaurus lookup word"       "t" #'powerthesaurus-lookup-word-at-point
       :desc "Read Aloud This"                  "r" #'read-aloud-this
       :desc "Export as LaTeX then PDF"         "l" #'org-latex-export-to-pdf
       :desc "spell check"                      "z" #'ispell-word
       :desc "Find definition"                  "f" #'lsp-find-definition
       )
      ;; Mappings for Elfeed and ERC
      (:prefix("e" . "Elfeed/ERC/AI")
       :desc "Open elfeed"              "e" #'elfeed
       :desc "Open ERC"                 "r" #'my/erc-connect
       :desc "Open EWW Browser"         "w" #'eww
       :desc "Update elfeed"            "u" #'elfeed-update
       :desc "MPV watch video"          "v" #'elfeed-tube-mpv
       :desc "Open Elpher"              "l" #'elpher
       :desc "Open Pass"                "p" #'pass
       :desc "Gptel chat"               "g" #'gptel
       :desc "Send region to gptel"     "s" #'gptel-send
       )

      ;; Various other commands
      (:prefix("o" . "open")
       :desc "Calendar"                  "c" #'=calendar
       :desc "Bookmarks"                 "l" #'list-bookmarks
       )
      (:prefix("b" . "+buffer")
       :desc "Save Bookmarks"                 "P" #'bookmark-save
       ))

;; Saving
(map! "C-s" #'save-buffer)

;; Moving between splits
(map! :map general-override-mode-map
      "C-<right>" #'evil-window-right
      "C-<left>"  #'evil-window-left
      "C-<up>"    #'evil-window-up
      "C-<down>"  #'evil-window-down
      ;; Window resizing with Shift
      "S-<right>" (lambda () (interactive)
                    (if (window-in-direction 'left)
                        (evil-window-decrease-width 5)
                      (evil-window-increase-width 5)))
      "S-<left>"  (lambda () (interactive)
                    (if (window-in-direction 'right)
                        (evil-window-decrease-width 5)
                      (evil-window-increase-width 5)))
      "S-<up>"    (lambda () (interactive)
                    (if (window-in-direction 'below)
                        (evil-window-decrease-height 2)
                      (evil-window-increase-height 2)))
      "S-<down>"  (lambda () (interactive)
                    (if (window-in-direction 'above)
                        (evil-window-decrease-height 2)
                      (evil-window-increase-height 2))))

(map! :n "<C-tab>"   #'centaur-tabs-forward    ; normal mode only
      :n "<C-iso-lefttab>" #'centaur-tabs-backward)  ; normal mode only

;; setting avy for quick jump forward/backward
(define-key evil-normal-state-map "f" 'avy-goto-char-2)
(define-key evil-normal-state-map "F" 'avy-goto-char-2)

(after! org
;; Enable arrow keys in org-read-date calendar popup
(define-key org-read-date-minibuffer-local-map (kbd "<left>") (lambda () (interactive) (org-eval-in-calendar '(calendar-backward-day 1))))
(define-key org-read-date-minibuffer-local-map (kbd "<right>") (lambda () (interactive) (org-eval-in-calendar '(calendar-forward-day 1))))
(define-key org-read-date-minibuffer-local-map (kbd "<up>") (lambda () (interactive) (org-eval-in-calendar '(calendar-backward-week 1))))
(define-key org-read-date-minibuffer-local-map (kbd "<down>") (lambda () (interactive) (org-eval-in-calendar '(calendar-forward-week 1)))))

;; Additional Consult bindings
(map! :leader
      (:prefix-map ("s" . "search")
       :desc "Search project" "p" #'consult-ripgrep
       :desc "Search buffer" "s" #'consult-line
       :desc "Search project files" "f" #'consult-find))

(after! projectile
  (setq projectile-enable-caching t)
  (setq projectile-indexing-method 'hybrid))

(after! persp-mode
  (setq persp-auto-save-opt 1)  ; Still save on exit
  (setq persp-auto-resume-time 0)  ; Don't auto-restore
  (setq persp-set-last-persp-for-new-frames nil)
  (setq persp-reset-windows-on-nil-window-conf nil))

;; Manually restore when ready
;; M-x persp-load-state-from-file

;; EMMS full configuration with Nord theme, centered layout, and swaync notifications
(use-package! emms
:defer t
  :commands (emms 
             emms-browser 
             emms-playlist-mode-go
             emms-pause
             emms-stop
             emms-next
             emms-previous
             emms-shuffle)
  :init
  ;; Set these early so they're available when EMMS loads
  (setq emms-source-file-default-directory "~/MusicOrganized"
        emms-playlist-buffer-name "*Music*"
        emms-info-asynchronously t
        emms-browser-default-browse-type 'artist)
  
  :config
  ;; Initialize EMMS - only runs when you actually use it
  (emms-all)
  (emms-default-players)
  (emms-mode-line-mode 1)
  (emms-playing-time-mode 1)

  ;; Basic settings
  (setq emms-browser-covers #'emms-browser-cache-thumbnail-async
        emms-browser-thumbnail-small-size 64
        emms-browser-thumbnail-medium-size 128
        emms-source-file-directory-tree-function 'emms-source-file-directory-tree-find)

  ;; MPD integration - critical for your workflow
  (require 'emms-player-mpd)
  (setq emms-player-mpd-server-name "localhost"
        emms-player-mpd-server-port "6600"
        emms-player-mpd-music-directory (expand-file-name "~/MusicOrganized"))

  ;; Connect to MPD and add it to player list
  (add-to-list 'emms-player-list 'emms-player-mpd)
  (add-to-list 'emms-info-functions 'emms-info-mpd)
  
  ;; Connect to MPD with slight delay to avoid blocking
  (run-with-timer 0.1 nil #'emms-player-mpd-connect)

  ;; Ensure players are properly set up
  (setq emms-player-list '(emms-player-mpd
                           emms-player-mplayer
                           emms-player-vlc
                           emms-player-mpg321
                           emms-player-ogg123))

  ;; Info functions
  (add-to-list 'emms-info-functions 'emms-info-ogginfo)
  (add-to-list 'emms-info-functions 'emms-info-tinytag)

  ;; Nord theme colors
  (custom-set-faces
   ;; Nord
   ;; '(emms-browser-artist-face ((t (:foreground "#ECEFF4" :height 1.1))))
   ;; '(emms-browser-album-face ((t (:foreground "#88C0D0" :height 1.0))))
   ;; '(emms-browser-track-face ((t (:foreground "#A3BE8C" :height 1.0))))
   ;; '(emms-playlist-track-face ((t (:foreground "#D8DEE9" :height 1.0))))
   ;; '(emms-playlist-selected-face ((t (:foreground "#BF616A" :weight bold)))))
  
   ;; Nowhere
'(emms-browser-artist-face ((t (:foreground "#e0dcd4" :height 1.1))))   ; Parchment - most prominent
'(emms-browser-album-face ((t (:foreground "#b4bec8" :height 1.0))))    ; Steel-blue - secondary accent
'(emms-browser-track-face ((t (:foreground "#b4beb4" :height 1.0))))    ; Sage-green - individual tracks
'(emms-playlist-track-face ((t (:foreground "#c0bdb8" :height 1.0))))   ; Muted foreground - neutral
'(emms-playlist-selected-face ((t (:foreground "#ccc4b0" :weight bold))))) ; Wheat-gold - warm selection

  ;; Browser keybindings
  (define-key emms-browser-mode-map (kbd "RET") 'emms-browser-add-tracks-and-play)
  (define-key emms-browser-mode-map (kbd "SPC") 'emms-pause)

  ;; Add notification hook
  (add-hook 'emms-player-started-hook 'emms-notify-song-change-with-artwork))

;; Helper functions - defined outside use-package so they're always available
(defun my/update-emms-from-mpd ()
  "Update EMMS cache from MPD and refresh browser."
  (interactive)
  (require 'emms)  ; Ensure EMMS is loaded
  (message "Updating EMMS cache from MPD...")
  (emms-player-mpd-connect)
  (emms-cache-set-from-mpd-all)
  (message "EMMS cache updated. Refreshing browser...")
  (when (get-buffer "*EMMS Browser*")
    (with-current-buffer "*EMMS Browser*"
      (emms-browser-refresh))))

(defun emms-center-buffer-in-frame ()
  "Add margins to center the EMMS buffer in the frame."
  (let* ((window-width (window-width))
         (desired-width 80)
         (margin (max 0 (/ (- window-width desired-width) 2))))
    (setq-local left-margin-width margin)
    (setq-local right-margin-width margin)
    (setq-local line-spacing 0.2)
    (set-window-buffer (selected-window) (current-buffer))))

(defun emms-cover-art-path ()
  "Return the path of the cover art for the current track."
  (when (bound-and-true-p emms-playlist-buffer)
    (let* ((track (emms-playlist-current-selected-track))
           (path (emms-track-get track 'name))
           (dir (file-name-directory path))
           (standard-files '("cover.jpg" "cover.png" "folder.jpg" "folder.png"
                           "album.jpg" "album.png" "front.jpg" "front.png"))
           (standard-cover (cl-find-if
                           (lambda (file)
                             (file-exists-p (expand-file-name file dir)))
                           standard-files)))
      (if standard-cover
          (expand-file-name standard-cover dir)
        (let ((cover-files (directory-files dir nil ".*\\(jpg\\|png\\|jpeg\\)$")))
          (when cover-files
            (expand-file-name (car cover-files) dir)))))))

(defun emms-notify-song-change-with-artwork ()
  "Send song change notification with album artwork to swaync via libnotify."
  (when (bound-and-true-p emms-playlist-buffer)
    (let* ((track (emms-playlist-current-selected-track))
           (artist (or (emms-track-get track 'info-artist) "Unknown Artist"))
           (title (or (emms-track-get track 'info-title) "Unknown Title"))
           (album (or (emms-track-get track 'info-album) "Unknown Album"))
           (cover-image (emms-cover-art-path)))
      
      (apply #'start-process
             "emms-notify" nil "notify-send"
             "-a" "EMMS"
             "-c" "music"
             (append
              (when cover-image
                (list "-i" cover-image))
              (list
               (format "Now Playing: %s" title)
               (format "Artist: %s\nAlbum: %s" artist album)))))))

(defun emms-signal-waybar-mpd-update ()
  "Signal waybar to update its MPD widget."
  (start-process "emms-signal-waybar" nil "pkill" "-RTMIN+8" "waybar"))

;; Hooks for EMMS modes - use with-eval-after-load to avoid premature loading
(with-eval-after-load 'emms-browser
  (add-hook 'emms-browser-mode-hook
            (lambda ()
              (face-remap-add-relative 'default '(:background "#1a1d21"))
              (emms-center-buffer-in-frame))))

(with-eval-after-load 'emms-playlist-mode
  (add-hook 'emms-playlist-mode-hook
            (lambda ()
              (face-remap-add-relative 'default '(:background "#1a1d21"))
              (emms-center-buffer-in-frame))))

;; Window resize hook - only add when EMMS is actually loaded
(with-eval-after-load 'emms
  (add-hook 'window-size-change-functions
            (lambda (_)
              (when (or (eq major-mode 'emms-browser-mode)
                        (eq major-mode 'emms-playlist-mode))
                (emms-center-buffer-in-frame)))))

;; Keybindings
(map! :leader
      (:prefix ("m" . "music/EMMS")
       :desc "Update from MPD" "u" #'my/update-emms-from-mpd
       :desc "Play at directory tree" "d" #'emms-play-directory-tree
       :desc "Go to emms playlist" "p" #'emms-playlist-mode-go
       :desc "Shuffle" "h" #'emms-shuffle
       :desc "Emms pause track" "x" #'emms-pause
       :desc "Emms stop track" "s" #'emms-stop
       :desc "Emms play previous track" "b" #'emms-previous
       :desc "Emms play next track" "n" #'emms-next
       :desc "EMMS Browser" "o" #'emms-browser))

;; Optional: Waybar signal hook (uncomment if using waybar)
;; (with-eval-after-load 'emms
;;   (add-hook 'emms-player-started-hook 'emms-signal-waybar-mpd-update))

;; Nov.el customizations and setup
(setq nov-unzip-program (executable-find "bsdtar")
      nov-unzip-args '("-xC" directory "-f" filename))
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

;; In config.el
(use-package! calibredb
:defer t
  :commands calibredb
  :config
  (setq calibredb-root-dir "~/Library"
        calibredb-db-dir (expand-file-name "metadata.db" calibredb-root-dir)
        calibredb-library-alist '(("~/Library"))
        calibredb-format-all-the-icons t)

  ;; Set up key bindings for calibredb-search-mode
  (map! :map calibredb-search-mode-map
        :n "RET" #'calibredb-find-file
        :n "?" #'calibredb-dispatch
        :n "a" #'calibredb-add
        :n "d" #'calibredb-remove
        :n "j" #'calibredb-next-entry
        :n "k" #'calibredb-previous-entry
        :n "l" #'calibredb-open-file-with-default-tool
        :n "s" #'calibredb-set-metadata-dispatch
        :n "S" #'calibredb-switch-library
        :n "q" #'calibredb-search-quit))

;; Open dirvish
(map! :leader
      :desc "Open dirvish" "o d" #'dirvish)

;; Open file manager in place dirvish/dired
(defun open-thunar-here ()
  "Open thunar in the current directory shown in dired/dirvish."
  (interactive)
  (let ((dir (cond
              ;; If we're in dired mode
              ((derived-mode-p 'dired-mode)
               default-directory)
              ;; If we're in dirvish mode (dirvish is derived from dired)
              ((and (featurep 'dirvish)
                    (derived-mode-p 'dired-mode)
                    (bound-and-true-p dirvish-directory))
               (or (bound-and-true-p dirvish-directory) default-directory))
              ;; Fallback for any other mode
              (t default-directory))))
    (message "Opening thunar in: %s" dir)  ; Helpful for debugging
    (start-process "thunar" nil "thunar" dir)))
;; Bind it to Ctrl+Alt+f in both dired and dirvish modes
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "C-M-f") 'open-thunar-here))
;; For dirvish, we need to add our binding to its special keymap if it exists
(with-eval-after-load 'dirvish
  (if (boundp 'dirvish-mode-map)
      (define-key dirvish-mode-map (kbd "C-M-f") 'open-thunar-here)
    ;; Alternative approach if dirvish uses a different keymap system
    (add-hook 'dirvish-mode-hook
              (lambda ()
                (local-set-key (kbd "C-M-f") 'open-thunar-here)))))

(defun thanos/wtype-text (text)
  "Process TEXT for wtype, handling newlines properly."
  (let* ((has-final-newline (string-match-p "\n$" text))
         (lines (split-string text "\n"))
         (last-idx (1- (length lines))))
    (string-join
     (cl-loop for line in lines
              for i from 0
              collect (cond
                       ;; Last line without final newline
                       ((and (= i last-idx) (not has-final-newline))
                        (format "wtype \"%s\""
                                (replace-regexp-in-string "\"" "\\\\\"" line)))
                       ;; Any other line
                       (t
                        (format "wtype \"%s\" && wtype -k Return"
                                (replace-regexp-in-string "\"" "\\\\\"" line)))))
     " && ")))

(define-minor-mode thanos/type-mode
  "Minor mode for inserting text via wtype."
  :keymap `((,(kbd "C-c C-c") . ,(lambda () (interactive)
                                   (call-process-shell-command
                                    (thanos/wtype-text (buffer-string))
                                    nil 0)
                                   (delete-frame)))
            (,(kbd "C-c C-k") . ,(lambda () (interactive)
                                   (kill-buffer (current-buffer))))))

(defun thanos/type ()
  "Launch a temporary frame with a clean buffer for typing."
  (interactive)
  (let ((frame (make-frame '((name . "emacs-float")
                             (fullscreen . 0)
                             (undecorated . t)
                             (width . 70)
                             (height . 20))))
        (buf (get-buffer-create "emacs-float")))
    (select-frame frame)
    (switch-to-buffer buf)
    (with-current-buffer buf
      (erase-buffer)
      (org-mode)
      (flyspell-mode)
      (thanos/type-mode)
      (setq-local header-line-format
                  (format " %s to insert text or %s to cancel."
                          (propertize "C-c C-c" 'face 'help-key-binding)
			  (propertize "C-c C-k" 'face 'help-key-binding)))
      ;; Make the frame more temporary-like
      (set-frame-parameter frame 'delete-before-kill-buffer t)
      (set-window-dedicated-p (selected-window) t))))

(define-minor-mode my/audio-recorder-mode
  "Minor mode for recording audio in Emacs."
  :lighter " Audio"
  :global t
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c a r") 'my/record-audio)
            (define-key map (kbd "C-c a s") 'my/stop-audio-recording)
            map))

;; Remove EWW from popup rules to make it open in a full buffer
(after! eww
  (set-popup-rule! "^\\*eww\\*" :ignore t))

;; Universal Launcher
(load! "lisp/universal-launcher")

(load! "lisp/pomodoro")
(load! "lisp/done-refile")
(load! "lisp/meeting-assistant")
(load! "lisp/jitsi-meeting")
(load! "lisp/post-to-blog")
(load! "lisp/create-daily")
(load! "lisp/nm")
(load! "lisp/popup-dirvish-browser")
(load! "lisp/audio-record")
(load! "lisp/org-caldav")
(load! "lisp/download-media")
;; POSSE posting system
(load! "lisp/posse/posse-twitter")
(load! "lisp/gimp-tweet")
(load! "lisp/0x0")

;; (load! "lisp/popup-scratch")
;; (load! "lisp/termux-sms")
;; (load! "lisp/weather")

;;;; Send a daily email to myself with the days agenda:
;;(defun my/send-daily-agenda ()
;;  "Send daily agenda email using mu4e"
;;  (interactive)
;;  (let* ((date-string (format-time-string "%Y-%m-%d"))
;;         (subject (format "Daily Agenda: %s" (format-time-string "%A, %B %d")))
;;         (tmp-file (make-temp-file "agenda")))
;;
;;    ;; Generate agenda and save to temp file
;;    (save-window-excursion
;;      (org-agenda nil "d")
;;      (with-current-buffer org-agenda-buffer-name
;;        (org-agenda-write tmp-file)))
;;
;;    ;; Read the agenda content
;;    (let ((agenda-content
;;           (with-temp-buffer
;;             (insert-file-contents tmp-file)
;;             (buffer-string))))
;;
;;      ;; Create and send email
;;      (with-current-buffer (mu4e-compose-new)
;;        (mu4e-compose-mode)
;;        ;; Set up headers
;;        (message-goto-to)
;;        (insert "josh@joshblais.com")
;;        (message-goto-subject)
;;        (insert subject)
;;        (message-goto-body)
;;        ;; Insert the agenda content
;;        (insert agenda-content)
;;        ;; Send
;;        (message-send-and-exit)))
;;
;;    ;; Cleanup
;;    (delete-file tmp-file)))
;;
;;;; Remove any existing timer
;;(cancel-function-timers 'my/send-daily-agenda)
;;
;;;; Schedule for 5:30 AM
;;(run-at-time "05:30" 86400 #'my/send-daily-agenda)

;; Deft mode
;; (setq deft-extensions '("txt" "tex" "org"))
;; (setq deft-directory "~/Vaults/org/roam")
;; (setq deft-recursive t)
;; (setq deft-use-filename-as-title t)

;; Drag and drop:
;; Function for mouse events
;;(defun my/drag-file-mouse (event)
;;  "Drag current file using dragon (mouse version)"
;;  (interactive "e")
;;  (let ((file (dired-get-filename nil t)))
;;    (when file
;;      (message "Click and drag the dragon window to your target location")
;;      (start-process "dragon" nil "/usr/local/bin/dragon"
;;                     "-x"          ; Send mode
;;                     "--keep"      ; Keep the window open
;;                     file))))
;;
;;;; Function for keyboard shortcut with multiple files support
;;(defun my/drag-file-keyboard ()
;;  "Drag marked files (or current file) using dragon"
;;  (interactive)
;;  (let ((files (or (dired-get-marked-files)
;;                   (list (dired-get-filename nil t)))))
;;    (when files
;;      (message "Click and drag the dragon window to your target location")
;;      (apply 'start-process "dragon" nil "/usr/local/bin/dragon"
;;             (append (list "-x" "--keep") files)))))
;;
;;;; Bind both versions
;;(after! dired
;;  (define-key dired-mode-map [drag-mouse-1] 'my/drag-file-mouse)
;;  (define-key dired-mode-map (kbd "C-c C-d") 'my/drag-file-keyboard))
