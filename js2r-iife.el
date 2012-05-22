(defvar js--iife-regexp "^(function (")

(defun js-wrap-buffer-in-iife ()
  "Wrap the entire buffer in an immediately invoked function expression"
  (interactive)
  (save-excursion
    (when (ignore-errors (search-backward-regexp js--iife-regexp))
      (error "Buffer already contains an immediately invoked function expression."))
    (goto-char (point-min))
    (insert "(function () {\n")
    (when js2r-use-strict (insert "\"use strict\";\n"))
    (insert "\n")
    (goto-char (point-max))
    (insert "\n")
    (delete-blank-lines)
    (insert "\n}());")
    (indent-region (point-min) (point-max))))

(defun js2r--selected-name-positions ()
  "Returns the (beginning . end) of the name at cursor, or active region."
  (let ((current-node (js2-node-at-point))
        beg end)
    (unless (js2-name-node-p current-node)
      (setq current-node (js2-node-at-point (- (point) 1))))
    (if (not (and current-node (js2-name-node-p current-node)))
        (error "Point is not on an identifier."))
    (if (use-region-p)
        (cons (region-beginning) (region-end))
      (progn
        (setq end (+ (js2-node-abs-pos current-node)
                     (js2-node-len current-node)))
        (skip-syntax-backward ".w_")
        (cons (point) end)))))

(defun js-inject-global-in-iife ()
  "Create shortcut for marked global by injecting it in the wrapping IIFE"
  (interactive)
  (js2r--guard)
  (save-excursion
    (let* ((name-pos (js2r--selected-name-positions))
           (name-beg (car name-pos))
           (name-end (cdr name-pos))
           (name (buffer-substring-no-properties name-beg name-end))
           (short (buster--global-shortcut name))
           beg end)
      (unless (search-backward-regexp js--iife-regexp)
        (error "No immediately invoked function expression found."))
      (deactivate-mark)
      (forward-char 11)
      (insert short)
      (unless (looking-at ")")
        (insert ", "))
      (search-forward "{")
      (setq beg (point))
      (backward-char)
      (forward-list)
      (forward-char)
      (setq end (point))
      (insert name)
      (unless (looking-at ")")
        (insert ", "))
      (replace-string name short t beg end))))

(provide 'js2r-iife)
