; DO NOT EDIT THIS FILE! EDIT "edoc/syntax-rules.scm.edoc" INSTEAD.

; Scheme 9 from Empty Space, Function Library
; By Nils M Holm, 2007-2010
; Placed in the Public Domain
;
; (syntax-rules (<keyword> ...) <rule> ...)  ==>  procedure
;
; See the R4RS Appendix for details.
;
; Caveat: Patterns *must* begin with the symbol "_".
;
; Caveat2: Only standard-Scheme binding constructs (LAMBDA, LET
;          LET*, LETREC) will be protected from variable capturing.

(load-from-library "flatten.scm")

; Match FORM against PATTERN; KEYWORDS contains
; the keywords of SYNTAX-RULES.
; When the given form matches the pattern, bind
; each variable of PATTERN to the corresponding
; part of the FORM and return an environment
; containing the new bindings.
; In case of a mismatch, return #F.

(define (syntax-match form pattern keywords)
  (letrec
    ((match
       (lambda (form pattern keywords env)
         (cond
           ((pair? pattern)
             (cond
               ((and (pair? (cdr pattern))
                     (eq? '... (cadr pattern)))
                 (let ((e* (map (lambda (x)
                                  (match x (car pattern) keywords '()))
                                form)))
                   (if (memq #f e*)
                       #f
                       (cons (cons '... e*) env))))
               ((pair? form)
                 (let ((e (match (car form) (car pattern) keywords env)))
                   (and e (match (cdr form) (cdr pattern) keywords e))))
               (else
                 #f)))
           ((memq pattern keywords)
             (if (eq? pattern form) env #f))
           ((symbol? pattern)
             (cons (cons pattern form) env))
           (else
             (if (equal? pattern form) env #f))))))
    (let ((e (match form pattern keywords '())))
      (if e (reverse! e) e))))

; Give a unique name to each variable that is bound in FORM.
; BOUND is a list of initially bound variables. This function
; also renames variables of (named) LET, LET*, and LETREC, and
; DO, e.g.:
;
; (ALPHA-CONV '(LET ((X Y)) X) '()) => (LET ((G123 Y)) G123)

(define (alpha-conv form bound)
  (letrec
    ((subst
       (lambda (x env)
         (cond ((assq x env) => cdr)
               (else x))))
     (map-improper
       (lambda (f a r)
         (cond ((null? a)
                 (reverse! r))
               ((not (pair? a))
                 (append (reverse! r) (f a)))
               (else
                 (map-improper f (cdr a) (cons (f (car a)) r))))))
     (remove-bound
       (lambda (env bound)
         (cond ((null? env)
                 '())
               ((memq (caar env) bound)
                 (remove-bound (cdr env) bound))
               (else
                 (cons (car env)
                       (remove-bound (cdr env) bound))))))
     (conv
       (lambda (form env)
         (cond ((symbol? form)
                 (subst form env))
               ((not (pair? form))
                 form)
               ((and (eq? 'quote (car form))
                     (pair? (cdr form))
                     (null? (cddr form)))
                 form)
               ((and (eq? 'lambda (car form))
                     (pair? (cdr form))
                     (pair? (cddr form)))
                 (let ((e (map-improper (lambda (x)
                                          (cons x (gensym)))
                                        (flatten (cadr form))
                                        '())))
                   `(lambda ,@(conv (cdr form)
                                    (append (remove-bound e bound)
                                            env)))))
               ((and (eq? (car form) 'let)
                     (pair? (cdr form))
                     (symbol? (cadr form))
                     (pair? (cddr form)))
                 (let* ((e (list (cons (cadr form) (gensym))))
                        (x (conv `(let ,@(cddr form))
                                  (append e env))))
                   `(let ,(cdar e) ,@(cdr x))))
               ((and (or (eq? (car form) 'let)
                         (eq? (car form) 'letrec)
                         (eq? (car form) 'let*)
                         (eq? (car form) 'do))
                     (pair? (cdr form))
                     (pair? (cadr form))
                     (pair? (caadr form))
                     (pair? (cddr form)))
                 (let ((e (map-improper (lambda (x)
                                          (cons x (gensym)))
                                        (map (lambda (x)
                                               (if (pair? x) (car x) #f))
                                             (cadr form))
                                        '())))
                   `(,(car form) ,@(conv (cdr form)
                                         (append (remove-bound e bound)
                                                 env)))))
               (else
                 (map-improper (lambda (x) (conv x env))
                               form
                               '()))))))
    (conv form '())))

; Substitute variables of TMPL by values of ENV.

(define syntax-expand
  (let ((alpha-conv alpha-conv))
    (lambda (bound tmpl env)
      (letrec
        ((expand
           (lambda (tmpl env)
             (cond
               ((not (pair? tmpl))
                 (cond ((assq tmpl env) => cdr)
                       (else tmpl)))
               ((and (pair? tmpl)
                     (pair? (cdr tmpl))
                     (eq? (cadr tmpl) '...))
                 (let ((eenv (assq '... env)))
                   (if (not eenv)
                       (error
                         (string-append "syntax-rules: template without"
                                        " matching ... in pattern")
                         tmpl)
                       (begin (set-car! eenv '(#f))
                              (append
                                (map (lambda (x)
                                       (expand (car tmpl) x))
                                     (cdr eenv))
                                (expand (cddr tmpl) env))))))
               (else
                 (cons (expand (car tmpl) env)
                       (expand (cdr tmpl) env)))))))
        (expand (alpha-conv tmpl bound) env)))))

; Check the syntax of SYNTAX-RULES and rewrite it
; to a LAMBDA expression.

(define-syntax (syntax-rules keywords . rules)
  (letrec
    ((list-of?
       (lambda (p a)
         (or (null? a)
             (and (p (car a))
                  (list-of? p (cdr a))))))
     (keywords-ok?
       (lambda (x)
         (list-of? symbol? x)))
     (rules-ok?
       (lambda (x)
         (list-of? (lambda (x)
                     (and (pair? x)
                          (pair? (car x))
                          (pair? (cdr x))
                          (null? (cddr x))))
                   x)))
     (pattern caar)
     (template cadar)
     (rewrite-rules
       (lambda (app keywords rules-in rules-out)
         (if (null? rules-in)
             (reverse! rules-out)
             (rewrite-rules
               app
               keywords
               (cdr rules-in)
               (cons `((syntax-match ,app
                                     ',(pattern rules-in)
                                     ',keywords)
                        => (lambda (env)
                             (syntax-expand ',(flatten (pattern rules-in))
                                            ',(template rules-in)
                                            env)))
                     rules-out))))))
    (cond
      ((null? rules)
        (error "syntax-rules: too few arguments" rules))
      ((not (keywords-ok? keywords))
        (error "syntax-rules: malformed keyword list" keywords))
      ((not (rules-ok? rules))
        (error "syntax-rules: invalid clause in rules" rules))
      (else
        (let* ((app (gensym))
               (default `((else (error "syntax error" ,app)))))
          `(lambda ,app
             (let ((,app (cons '_ ,app)))
               (cond ,@(rewrite-rules app keywords rules '())
                     ,@default))))))))

