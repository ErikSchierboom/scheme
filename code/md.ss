
;;; Markdown

(define string->goodMD
  (make-char-quotator '((#\_ . "\\_")
			(#\- . "\\-")
			(#\` . "\\`")
			(#\~ . "\\~")
			(#\# . "\\#")
			(#\* . "\\*")
			(#\+ . "\\+")
			(#\. . "\\.")
			(#\! . "\\!")
			(#\{ . "\\{")
			(#\} . "\\}")
			(#\[ . "\\[")
			(#\] . "\\]")
			(#\( . "\\(")
			(#\) . "\\)"))))

;; transform sxml tree into tree of strings. the tree of strings can
;; be traversed outputting each node with `send-reply`.

(define sxml-bindings
  `((section . ,(lambda (_ title . x)
		  `((h1 ,title) (nl) ,@x)))
    (subsection . ,(lambda (_ subtitle . x)
		     `((h2 ,subtitle) (nl) ,@x)))
    (paragraph . ,(lambda (_ . x)
		    `(,@x (nl) (nl))))
    (sentence . ,(lambda (_ . x)
		   `(,@x (nl))))
    (link . ,(case-lambda
	       ((_ description href)
		`(*raw* "[" ,description "]" "(" ,href ")"))
	       ((_ description href title)
		`(*raw* "[" ,description "]" "(" ,href "\"" ,title "\"" ")"))))
    (*default* . ,(lambda x x))
    (*text* . ,(lambda (_ . x) x))))

(define (sxml->md tree)
  (cond
   ((nodeset? tree) (map sxml->md tree))
   ((pair? tree)
    (let* ((tag (name tree))
	   (name (symbol->string tag))
	   (content (content-raw tree)))
      (case tag
	((*raw*) content)
	((bold) `("__" ,@(sxml->md content) "__"))
	((emphasis) `("_" ,@(sxml->md content) "_"))
	((strike-through) `("~~" ,@(sxml->md content) "~~"))
	((code) `("```" ,(car content) "\n" ,(cdr content) "\n" "```"))
	((inline-code) `("`" ,content "`"))
	((h1) `("# " ,@(sxml->md content) "\n"))
	((h2) `("## " ,@(sxml->md content) "\n"))
	((h3) `("### " ,@(sxml->md content) "\n"))
	((h4) `("#### " ,@(sxml->md content) "\n"))
	((h5) `("##### " ,@(sxml->md content) "\n"))
	((h6) `("###### " ,@(sxml->md content) "\n"))
	((item) `("* " ,@(sxml->md content) "\n"))
	((enum) `("\n" ,@(sxml->md content) "\n"))
	((nl) "\n")
	(else (error 'sxml->md "unexpected tag" tag)))))
   ((string? tree) (list (string->goodMD tree)))
   ((symbol? tree) (list (string->goodMD (symbol->string tree))))
   (else (error 'sxml->md "unexpected node" tree))))

;; a simple way to test the output. eventual goal is to generate the
;; markdown in docs/*
(define (put-doc md)
  (let ((source (format "code/docs/~a.ss" md))
	(target (format "docs/~a.md" (string-upcase (symbol->string md)))))
    (load source)
    (when (file-exists? target)
      (delete-file target))
    (with-output-to-file target
      (lambda ()
	(put-md content)))))

(define (put-md md)
  (send-reply
   (sxml->md
    (pre-post-order md sxml-bindings))))

(define (md-hints md)
  `(section "Notes" ,@md))

