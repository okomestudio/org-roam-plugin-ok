;;; orp-ok-ox-hugo.el --- Plugin for ox-hugo  -*- lexical-binding: t -*-
;;
;; Copyright (C) 2024 Taro Sato
;;
;; Author: Taro Sato <okomestudio@gmail.com>
;; URL: https://github.com/okomestudio/org-roam-plugin-ok
;; Version: 0.1
;; Keywords: org-mode, roam, plug-in
;; Package-Requires: ((emacs "29.1") (org "9.4") (dash "2.13") (adaptive-wrap "0.8") (s "1.13.1"))
;;
;;; Commentary:
;;
;; This module provides a plugin for `ox-hugo'.
;;
;;; Code:

(require 'orp-ok-utils)

(defcustom org-export-hugo-article-tag "blog"
  "FILETAGS name used for Hugo articles.")

(with-eval-after-load 'ox-hugo
  (defun orp-ok-ox-hugo-exportable-p ()
    "Return t if the current buffer is ready for Hugo export."
    (interactive)
    (catch 'false
      (dolist (keyword '("HUGO_TAGS"
                         "HUGO_SECTION"
                         "HUGO_DRAFT"
                         "HUGO_CUSTOM_FRONT_MATTER"
                         "HUGO_BUNDLE"
                         "HUGO_BASE_DIR"
                         "HUGO_AUTO_SET_LASTMOD"
                         "EXPORT_HUGO_BUNDLE"
                         "EXPORT_FILE_NAME"
                         "DATE"
                         "AUTHOR"))
        (if (not (org-roam-get-keyword keyword))
            throw 'false nil))
      t))

  (defun orp-ok-ox-hugo-make-exportable ()
    "Add keywords to prepare the current buffer for Hugo export."
    (interactive)
    (save-excursion
      (beginning-of-buffer)
      (let* ((node (org-roam-node-at-point))
             (title (org-roam-node-title node))
             (slug (orp-string-to-org-slug title))
             (time (current-time))
             (date (format-time-string "%Y-%m-%d" time))
             (section (format-time-string "%Y/%m" time))
             (tags (org-roam-node-tags node)))
        (dolist (it `(("HUGO_TAGS" . ,(string-join tags " "))
                      ("HUGO_SECTION" . ,section)
                      ("HUGO_DRAFT" . "true")
                      ("HUGO_CUSTOM_FRONT_MATTER" . ":archived false")
                      ("HUGO_BUNDLE" . ,slug)
                      ("HUGO_BASE_DIR" . ,org-hugo-base-dir)
                      ("HUGO_AUTO_SET_LASTMOD" . "t")
                      ("EXPORT_HUGO_BUNDLE" . ,slug)
                      ("EXPORT_FILE_NAME" . "index")
                      ("DATE" . ,date)
                      ("AUTHOR" . ,user-login-name)))
          (org-roam-set-keyword (car it) (cdr it))))
      (org-roam-tag-add `(,org-export-hugo-blog-tag))))

  (advice-add #'org-hugo--before-export-function
              :before
              (lambda (subtreep)
                (interactive)
                (when (not (orp-ok-ox-hugo-exportable-p))
                  (orp-ok-ox-hugo-make-exportable))))

  (defun org-hugo-link--strip-id-link (fun link desc info)
    "Remove Org links of type 'id'."
    (let ((type (org-element-property :type link)))
      (if (string= type "id")
          desc
        (funcall fun link desc info))))

  (advice-add #'org-hugo-link :around #'org-hugo-link--strip-id-link)

  (defun orp-ox-hugo-backend-menu-item (menu-item)
    "Add a MENU-ITEM to Hogo's backend."
    (dolist (backend org-export-registered-backends)
      (when (eq 'hugo (org-export-backend-name backend))
        (let ((menu-items (caddr (org-export-backend-menu backend))))
          (setq menu-items (append menu-items '(menu-item)))
          (setf (caddr (org-export-backend-menu backend)) menu-items))))))

(provide 'orp-ok-ox-hugo)
;;; orp-ok-ox-hugo.el ends here
