; Scheme 9 from Empty Space, Function Library
; By Nils M Holm, 2009
; See the LICENSE file of the S9fES package for terms of use
;
; (count pair) ==> integer
;
; Count the atomic members of a pair.
;
; Arguments: x - list to count
;
; Example:   (count '(a (b (c)) d . e)) ==> 5

(define (count x)
  (cond ((null? x) 0)
        ((pair? x)
          (+ (count (car x))
             (count (cdr x))))
        (else 1)))