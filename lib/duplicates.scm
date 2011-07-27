; Scheme 9 from Empty Space, Function Library
; By Nils M Holm, 2010
; See the LICENSE file of the S9fES package for terms of use
;
; (duplicates list)        ==>  list
; (dupp procedure^2 list)  ==>  list
; (dupq list)              ==>  list
; (dupv list)              ==>  list
;
; Return a list of duplicates contained in LIST.
;
; DUPP uses the predicate PROCEDURE^2 to check if two members of
; LIST are duplicates.
;
; (Duplicates x)  is equal to  (dupp equal? x)
; (Dupv x)        is equal to  (dupp eqv? x)
; (Dupq x)        is equal to  (dupp eq? x)
;
; When a duplicate occurs multiple times in a given list, it will
; be contained only once in the results of these procedures.
;
; Example:   (dupp = '(1 2 3 1 2))        ==>  (1 2)
;            (duplicates '((1) (2) (1)))  ==>  ((1))
;            (dupv '(#\a #\b #\a #\c))    ==>  (#\a)
;            (dupq '(a b c d a c e f c))  ==>  (a c)

(load-from-library "memp.scm")

(define (dupp p x)
  (letrec
    ((dupp2
       (lambda (x r)
         (cond ((null? x)
                 (reverse! r))
               ((and (memp p (car x) (cdr x))
                     (not (memp p (car x) r)))
                 (dupp2 (cdr x) (cons (car x) r)))
               (else
                 (dupp2 (cdr x) r))))))
    (dupp2 x '())))

(define (duplicates x) (dupp equal? x))
(define (dupv x)       (dupp eqv? x))
(define (dupq x)       (dupp eq? x))