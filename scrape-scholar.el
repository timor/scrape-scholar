;; -*- lexical-binding: t; -*-

;;; scrape-scholar.el --- scrape information from google scholar

;;; Commentary: Use scrape.el to get information about google scholar
;;; search results

(require 'scrape)

(defvar scrape-scholar-host "https://scholar.google.com")
(defvar scrape-scholar-url (concat scrape-scholar-host "/scholar"))

(defun scrape-scholar-walk-xml (xml filter)
  "Walk through xml tree, call filter for every node."
  ;; writing this iterative because automatic recursion-iteration
  ;; conversion doesn't seem to work.
  (cl-flet ((children (node)
		   (unless (stringp node)
		     (cdr (cdr node)))))
    (let ((items (list xml)))
      (while items
	;; (print (format "number of items to check: %s" (length items)))
	(funcall filter (first items))
	(setq items (append (rest items) (children (first items))))))))

(defun scrape-scholar-node-attribute (node attr)
  "Return the attribute named attr of node"
  (cdr (find attr (second node) :key 'first)))

(defun scrape-scholar-node-class (node)
  "Return the class of a node, nil if it does not have one."
  (scrape-scholar-node-attribute node 'class))

(defun scrape-scholar-filter-class (xml elt class)
  "Return a list of nodes that match elt and class"
  (let ((results ()))
    (cl-labels ((test (node)
		      (when (and
			     (not (stringp node))
			     (eq (first node) elt)
			     (equal class (scrape-scholar-node-class node)))
			(push node results))))
      (scrape-scholar-walk-xml xml (lambda (node) (test node)))
      (reverse results))))

(defun scrape-scholar-extract-properties (result)
  "Extract information about the search result.  Note that
cited-by-link does not contain a correct url unless cited-by-number is
  greater than 0.  Return as property list."
  (when result
    (let* ((title-elts (cdr (cdr (third (fourth result)))))
	   (all (apply 'concat (mapcar
				(lambda (e)
				  (let* ((text (if (stringp e)
						   e
						 (third e))))
				    text))
				title-elts)))
	   (cleaned (replace-regexp-in-string
		     (rx (+ (any space "\n"))) " "
		     all))
	   (trimmed (replace-regexp-in-string
		     (rx (or (seq bos (+ space))
			     (seq (+ space) eos))) ""
			     cleaned))
	   (cited-by-link (concat scrape-scholar-host (cdr (car (second (fourth (tenth result)))))))
	   (cited-by-number (let ((str (third (fourth (tenth result)))))
			      (if (and str (string-match "Cited by \\([0-9]+\\)" str))
				  (string-to-number (match-string 1 str))
				0))))
      `(:title ,trimmed
	       :cited-by-link ,cited-by-link
	       :cited-by-number ,cited-by-number))))

(defun scrape-scholar-all-cited (item)
  "Return a list of objects representing all cited-by results of a
  scholar search."
  (let ((num (plist-get item :cited-by-number))
	(start 0)
	(results ()))
    (when (> num 0)
      (while (< start num)
	(let ((xml (scrape-url (concat (plist-get item :cited-by-link)
				       (format "&num=20&start=%s"
					       start)))))
	  (setq results (append results
				(mapcar
				 'scrape-scholar-extract-properties
				 (scrape-scholar-filter-class xml 'div "gs_ri"))))
	  (incf start 20)))
      results)))

(defun scrape-scholar-search (query)
  "Scrape information about query from google scholar.  Return
  list of property lists with all the information about the first result."
  ;; (interactive "sGoogle Scholar Search Terms:")
  (let* ((url (format
	       "%s?q=%s"
	       scrape-scholar-url
	       (replace-regexp-in-string (rx (+ space)) "+" query)))
	 (page (progn
		 (message "retrieving: %s" url)
		 (scrape-url url)))
	 (item (scrape-scholar-extract-properties
		(first (scrape-scholar-filter-class page 'div
						    "gs_ri"))))
	 (cited-bys (scrape-scholar-all-cited item)))
    (append item
	    `(:citations ,cited-bys))))


(provide 'scrape-scholar)

;;; scrape-scholar.el ends here
