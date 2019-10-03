(define (parse-test test)
  `(lambda ()
     (test-success ,(lookup 'description test)
		   equal?
		   hello-world
		   '()
		   ,(lookup 'expected test))))

(define (spec->tests spec)
  `(,@*test-definitions*
     (define (test . args)
       (apply
         run-test-suite
         (list ,@(map parse-test (lookup 'cases spec)))
         args))))

(put-problem!
 'hello-world
 `((test
    .
    ,(spec->tests (get-test-specification 'hello-world)))
   (skeleton . "hello-world.scm")
   (solution . "example.scm")
   (hints.md . ,(md-hints
		 `((sentence "Your solution may be a procedure that
returns the desired string or a variable whose value is that
string."))))))
