; Scheme 9 from Empty Space, Function Library
; By Nils M Holm, 2009
; See the LICENSE file of the S9fES package for terms of use
;
; The S9fES Scientific Calculator Package
; See the S9SC(1) man page for details.
;
; (box int1 int2 int3 int3 bool1 bool2)                   ==>  unspecific
; (caption (integer1 string1) ...)                        ==>  unspecific
; (clear)                                                 ==>  unspecific
; (ellipse int1 int2 int3 int3 bool1 bool2)               ==>  unspecific
; (line int1 int2 int3 int3 bool1)                        ==>  unspecific
; (plot procedure options ...)                            ==>  unspecific
; (plot set options ...)                                  ==>  unspecific
; (plot* integer1 integer2 procedure options ...)         ==>  unspecific
; (plot* integer1 integer2 set options ...)               ==>  unspecific
; (put-string int1 int2 string int3 bool)                 ==>  unspecific
; (sc:fini)                                               ==>  unspecific
; (sc:init)                                               ==>  unspecific
; (setup integer1 integer2 integer3 integer4 option ...)  ==>  unspecific
; (string-height string)                                  ==>  integer
; (string-width string)                                   ==>  integer
; (write-canvas string)                                   ==>  unspecific

(if (not (memq 'sc *extensions*))
    (wrong "The S9SC package requires the \"sc\" extension"))

(load-from-library "iota.scm")
(load-from-library "mergesort.scm")

(define setup   #f)
(define plot    #f)
(define plot*   #f)
(define caption #f)

(define (sc:sc)

  (define *XLIM* 13333)
  (define *YLIM* 10000)

  (define *X0* #f)
  (define *XN* #f)
  (define *Y0* #f)
  (define *YN* #f)
  (define *X-size* #f)
  (define *Y-size* #f)
  (define *X-scale* #f)
  (define *Y-scale* #f)
  (define *X-step* #f)
  (define *Y-step* #f)
  (define *X-zero* #f)
  (define *Y-zero* #f)

  (define (int x)
    (inexact->exact (round x)))

  (define (x-range x0 xN . s)
    (if (not (<= x0 0 xN))
        (wrong "SC: range must be in range x0..xN")
        (let* ((width (if (negative? x0)
                          (if (negative? xN)
                              (- (abs x0) (abs xN))
                              (+ (abs x0) xN))
                          (- xN x0)))
               (steps (if (null? s)
                          20
                          (/ width (car s))))
               (zero  (- width xN)))
          (set! *X0* x0)
          (set! *XN* xN)
          (set! *X-size* width)
          (set! *X-scale* (/ *XLIM* width))
          (set! *X-step* (/ width steps))
          (set! *X-zero* (int (* zero *X-scale*))))))

  (define (y-range y0 yN . s)
    (if (not (<= y0 0 yN))
        (wrong "SC: range must be in range y0..yN")
        (let* ((width (if (negative? y0)
                          (if (negative? yN)
                              (- (abs y0) (abs yN))
                              (+ (abs y0) yN))
                          (- yN y0)))
               (steps (if (null? s)
                          20
                          (/ width (car s))))
               (zero  (- width yN)))
          (set! *Y0* y0)
          (set! *YN* yN)
          (set! *Y-size* width)
          (set! *Y-scale* (/ *YLIM* width))
          (set! *Y-step* (/ width steps))
          (set! *Y-zero* (int (* zero *Y-scale*))))))

  (define (label-string x)
    (number->string (abs x)))

  (define (plot-x-axis ticks labels lstep grid)

    (define (dashed-vline x)
      (let loop ((y 0))
        (if (< y *YLIM*)
            (begin (sc:line x y x (+ y 10) #t)
                   (loop (+ y 200))))))

    (sc:line 0 *Y-zero* *XLIM* *Y-zero* #t)
    (cond (ticks
            (let loop ((x *X-step*))
              (cond ((<= x *XN*)
                      (let ((rx (int (+ *X-zero* (* x *X-scale*)))))
                        (sc:line rx (- *Y-zero* 100) rx (+ *Y-zero* 100) #t)
                        (loop (+ x *X-step*))))))
            (let loop ((x (- *X-step*)))
              (cond ((>= x *X0*)
                      (let ((rx (int (+ *X-zero* (* x *X-scale*)))))
                        (sc:line rx (- *Y-zero* 100) rx (+ *Y-zero* 100) #t)
                        (loop (- x *X-step*))))))))
    (cond (grid
            (let loop ((x *X-step*)
                       (gs (if (= 1 lstep) 1 (- lstep 1))))
              (cond ((<= x *XN*)
                      (let ((rx (int (+ *X-zero* (* x *X-scale*)))))
                        (if (= gs lstep)
                            (dashed-vline rx))
                        (loop (+ x *X-step*)
                              (if (< gs 2) lstep (- gs 1)))))))
            (let loop ((x (- *X-step*))
                       (gs (if (= 1 lstep) 1 (- lstep 1))))
              (cond ((>= x *X0*)
                      (let ((rx (int (+ *X-zero* (* x *X-scale*)))))
                        (if (= gs lstep)
                            (dashed-vline rx))
                        (loop (- x *X-step*)
                              (if (< gs 2) lstep (- gs 1)))))))))
    (cond
      (labels
        (let loop ((x *X-step*)
                   (xs (+ *X-zero* (* *X-step* *X-scale*)))
                   (ls (if (= 1 lstep) 1 (- lstep 1))))
          (cond ((<= x *XN*)
                  (let* ((s  (label-string x))
                         (rx (int (- xs (quotient (sc:string-width s 1) 2)))))
                    (if (= ls lstep)
                        (sc:put-string rx (+ *Y-zero* 150) 1 #t s))
                    (loop (+ x *X-step*)
                          (+ xs (* *X-scale* *X-step*))
                          (if (< ls 2) lstep (- ls 1)))))))
        (let loop ((x (- *X-step*))
                   (xs (- *X-zero* (* *X-step* *X-scale*)))
                   (ls (if (= 1 lstep) 1 (- lstep 1))))
          (cond ((>= x *X0*)
                  (let* ((s  (label-string x))
                         (rx (int (- xs (quotient (sc:string-width s 1) 2)))))
                    (if (= ls lstep)
                        (sc:put-string rx (+ *Y-zero* 150) 1 #t s))
                    (loop (- x *X-step*)
                          (- xs (* *X-scale* *X-step*))
                          (if (< ls 2) lstep (- ls 1))))))))))

  (define (plot-y-axis ticks labels lstep grid)

    (define (dashed-hline y)
      (let loop ((x 0))
        (if (< x *XLIM*)
            (begin (sc:line x y (+ x 10) y #t)
                   (loop (+ x 200))))))

    (sc:line *X-zero* 0 *X-zero* *YLIM* #t)
    (cond (ticks
            (let loop ((y *Y-step*))
              (cond ((<= y *YN*)
                      (let ((ry (int (+ *Y-zero* (* y *Y-scale*)))))
                        (sc:line (- *X-zero* 100) ry (+ *X-zero* 100) ry #t)
                        (loop (+ y *Y-step*))))))
            (let loop ((y (- *Y-step*)))
              (cond ((>= y *Y0*)
                      (let ((ry (int (+ *Y-zero* (* y *Y-scale*)))))
                        (sc:line (- *X-zero* 100) ry (+ *X-zero* 100) ry #t)
                        (loop (- y *Y-step*))))))))
    (cond (grid
            (let loop ((y *Y-step*)
                       (gs (if (= 1 lstep) 1 (- lstep 1))))
              (cond ((<= y *YN*)
                      (let ((ry (int (+ *Y-zero* (* y *Y-scale*)))))
                        (if (= gs lstep)
                            (dashed-hline ry))
                        (loop (+ y *Y-step*)
                              (if (< gs 2) lstep (- gs 1)))))))
            (let loop ((y (- *Y-step*))
                       (gs (if (= 1 lstep) 1 (- lstep 1))))
              (cond ((>= y *Y0*)
                      (let ((ry (int (+ *Y-zero* (* y *Y-scale*)))))
                        (if (= gs lstep)
                            (dashed-hline ry))
                        (loop (- y *Y-step*)
                              (if (< gs 2) lstep (- gs 1)))))))))
    (cond
      (labels
        (let loop ((y *Y-step*)
                   (ys (+ *Y-zero* (* *Y-step* *Y-scale*)))
                   (ls (if (= 1 lstep) 1 (- lstep 1))))
          (cond ((<= y *YN*)
                  (let ((ry (int (- ys 50)))
                        (s  (label-string y)))
                    (if (= ls lstep)
                        (sc:put-string (+ *X-zero* 150) ry 1 #t s))
                    (loop (+ y *Y-step*)
                          (+ ys (* *Y-scale* *Y-step*))
                          (if (< ls 2) lstep (- ls 1)))))))
        (let loop ((y (- *Y-step*))
                   (ys (- *Y-zero* (* *Y-step* *Y-scale*)))
                   (ls (if (= 1 lstep) 1 (- lstep 1))))
          (cond ((>= y *Y0*)
                  (let ((ry (int (- ys 50)))
                        (s  (label-string y)))
                    (if (= ls lstep)
                        (sc:put-string (+ *X-zero* 150) ry 1 #t s))
                    (loop (- y *Y-step*)
                          (- ys (* *Y-scale* *Y-step*))
                          (if (< ls 2) lstep (- ls 1))))))))))

  (define (get-value key args . dfl)
    (cond ((memv key args)
            => (lambda (x)
                 (if (pair? (cdr x))
                     (cadr x)
                     (if (null? dfl) #f (car dfl)))))
          ((null? dfl)
            #f)
          (else
            (car dfl))))

  (define (check-options opts types)
    (cond ((and (not (null? opts))
                (null? (cdr opts)))
            (wrong "missing options argument" (car opts)))
          ((not (null? opts))
            (cond ((assq (car opts) types)
                    => (lambda (type)
                         (if ((cadr type) (cadr opts))
                             (check-options (cddr opts) types)
                             (wrong "type mismatch" `(,(car opts)
                                                      ,(cadr opts))))))
                  (else (wrong "unknown option" (car opts)))))))

  (define (sc:setup x0 xN y0 yN . opts)
    (check-options opts `((noplot:   ,boolean?)
                          (step:     ,real?)
                          (ticks:    ,boolean?)
                          (labels:   ,boolean?)
                          (lstep:    ,integer?)
                          (grid:     ,boolean?)
                          (x-step:   ,real?)
                          (y-step:   ,real?)
                          (x-ticks:  ,boolean?)
                          (y-ticks:  ,boolean?)
                          (x-labels: ,boolean?)
                          (y-labels: ,boolean?)
                          (x-lstep:  ,integer?)
                          (y-lstep:  ,integer?)
                          (x-grid:   ,boolean?)
                          (y-grid:   ,boolean?)))
    (let* ((x-step   (get-value 'step: opts))
           (x-ticks  (get-value 'ticks: opts #t))
           (x-labels (get-value 'labels: opts #t))
           (x-lstep  (get-value 'lstep: opts 1))
           (x-grid   (get-value 'grid: opts #f))
           (y-step   x-step)
           (y-ticks  x-ticks)
           (y-labels x-labels)
           (y-lstep  x-lstep)
           (y-grid   x-grid))
      (let ((x-step   (get-value 'x-step: opts x-step))
            (y-step   (get-value 'y-step: opts y-step))
            (x-ticks  (get-value 'x-ticks: opts x-ticks))
            (y-ticks  (get-value 'y-ticks: opts y-ticks))
            (x-labels (get-value 'x-labels: opts x-labels))
            (y-labels (get-value 'y-labels: opts y-labels))
            (x-lstep  (get-value 'x-lstep: opts x-lstep))
            (y-lstep  (get-value 'y-lstep: opts y-lstep))
            (x-grid   (get-value 'x-grid: opts x-grid))
            (y-grid   (get-value 'y-grid: opts y-grid))
            (noplot   (get-value 'noplot: opts #f)))
        (if x-step
            (x-range x0 xN x-step)
            (x-range x0 xN))
        (if y-step
            (y-range y0 yN y-step)
            (y-range y0 yN))
        (if (not noplot)
            (begin (sc:clear)
                   (plot-x-axis x-ticks x-labels x-lstep x-grid)
                   (plot-y-axis y-ticks y-labels y-lstep y-grid))))))

  (define (line-plot-fn fn . opts)
    (let ((res  (get-value 'res: opts 100))
          (from (get-value 'from: opts *X0*))
          (to   (get-value 'to: opts *XN*)))
      (let ((step  (/ *X-size* res))
            (sstep (* *X-scale* (/ *X-size* res))))
        (let loop ((x  *X0*)
                   (xs (int (+ *X-zero* (* *X-scale* *X0*))))
                   (px #f)
                   (py #f))
          (let* ((y (fn x))
                 (y (if (number? y)
                        (int (* *Y-scale* y))
                        y)))
            (cond ((<= x *XN*)
                    (cond ((and (<= from x to)
                                (number? y))
                            (if px (sc:line px
                                            (+ *Y-zero* py)
                                            (int xs)
                                            (+ *Y-zero* y)
                                            #t))
                            (loop (+ x step) (+ xs sstep) (int xs) y))
                          (else
                            (loop (+ x step) (+ xs sstep) #f #f))))))))))

  (define (scatter-mark style)

    (define (scatter-0 x y)
      (sc:box (- x 50) (- y 50)
              (+ x 50) (+ y 50) #t #f))

    (define (scatter-1 x y)
      (sc:box (- x 50) (- y 50)
              (+ x 50) (+ y 50) #t #t))

    (define (scatter-2 x y)
      (sc:ellipse (- x 50) (- y 50)
                  (+ x 50) (+ y 50) #t #f))

    (define (scatter-3 x y)
      (sc:ellipse (- x 50) (- y 50)
                  (+ x 50) (+ y 50) #t #t))

    (define (scatter-4 x y)
      (sc:line (- x 50) (- y 50)
               (+ x 50) (+ y 50) #t)
      (sc:line (- x 50) (+ y 50)
               (+ x 50) (- y 50) #t))

    (case style
      ((0)  scatter-0)
      ((1)  scatter-1)
      ((2)  scatter-2)
      ((3)  scatter-3)
      ((4)  scatter-4)
      (else (wrong "scatter-mark: style: must be in range 0..4"
            style))))

  (define (scatter-plot-fn fn . opts)
    (let ((style (get-value 'style: opts 0))
          (res   (get-value 'res: opts 100))
          (from (get-value 'from: opts *X0*))
          (to   (get-value 'to: opts *XN*)))
      (let* ((step  (/ *X-size* res))
             (sstep (* *X-scale* (/ *X-size* res)))
             (box   (scatter-mark style)))
        (let loop ((x  *X0*)
                   (xs (int (+ *X-zero* (* *X-scale* *X0*)))))
          (let* ((y (fn x))
                 (y (if (number? y)
                        (int (* *Y-scale* y))
                        y)))
            (if (<= x *XN*)
                (begin (if (and (<= from x to)
                                (number? y))
                           (box (int xs) (+ y *Y-zero*)))
                       (loop (+ x step) (+ xs sstep)))))))))

  (define (pin-plot-fn fn . opts)
    (let ((res  (get-value 'res: opts 100))
          (from (get-value 'from: opts *X0*))
          (to   (get-value 'to: opts *XN*)))
      (let ((step  (/ *X-size* res))
            (sstep (* *X-scale* (/ *X-size* res))))
        (let loop ((x  *X0*)
                   (xs (int (+ *X-zero* (* *X-scale* *X0*)))))
          (let* ((y (fn x))
                 (y (if (number? y)
                        (int (* *Y-scale* y))
                        y)))
            (cond ((<= x *XN*)
                    (if (and (<= from x to)
                             (number? y))
                        (sc:line (int xs) *Y-zero* (int xs) (+ y *Y-zero*) #t))
                        (loop (+ x step) (+ xs sstep)))))))))

  (define (filled-box x y dx dy step)
    (let ((x  (min x dx))
          (dx (max x dx))
          (y  (min y dy))
          (dy (max y dy)))
      (sc:box x y dx dy #t #f)
      (if (positive? step)
          (let yloop ((j (+ y (quotient step 2))))
            (let xloop ((i (+ x (quotient step 2))))
              (if (< i (- dx 10))
                  (begin (sc:box i j (+ i 10) (+ j 10) #t #f)
                         (xloop (+ i step)))
                  (if (< j (- dy step 10))
                      (yloop (+ j step)))))))))

  (define (fill-style n)
    (cond ((assv n '((0 0) (1 200) (2 150) (3 100) (4 50)))
            => cadr)
          (else 0)))

  (define (bar-plot-fn fn . opts)
    (let ((res   (get-value 'res: opts 100))
          (style (fill-style (get-value 'style: opts 0)))
          (from (get-value 'from: opts *X0*))
          (to   (get-value 'to: opts *XN*)))
      (let ((step  (/ *X-size* res))
            (sstep (* *X-scale* (/ *X-size* res))))
        (let loop ((x  *X0*)
                   (xs (int (+ *X-zero* (* *X-scale* *X0*)))))
          (let* ((y (fn x))
                 (y (if (number? y)
                        (int (* *Y-scale* y))
                        y)))
            (if (<= x *XN*)
                (begin (if (and (<= from x (- to step))
                                (number? y))
                           (filled-box (int xs)
                                       *Y-zero*
                                       (int (+ xs sstep))
                                       (+ y *Y-zero*)
                                       style))
                       (loop (+ x step) (+ xs sstep)))))))))

  (define (dry-plot-fn fn . opts)
    (let ((res     (get-value 'res: opts 100))
          (from    (get-value 'from: opts *X0*))
          (to      (get-value 'to: opts *XN*))
          (min-val #f)
          (max-val #f))
      (let* ((step  (/ *X-size* res))
             (sstep (* *X-scale* (/ *X-size* res))))
        (let loop ((x  *X0*)
                   (xs (int (+ *X-zero* (* *X-scale* *X0*)))))
          (let* ((y (fn x)))
            (if (<= x *XN*)
                (begin (if (and (<= from x to)
                                (number? y))
                           (begin (if (or (not min-val)
                                          (< y min-val))
                                      (set! min-val y))
                                  (if (or (not max-val)
                                          (> y max-val))
                                      (set! max-val y))))
                       (loop (+ x step) (+ xs sstep)))
                (list min-val max-val)))))))

  (define (plot-fn fn . opts)
    (let* ((type (get-value 'type: opts 'line))
           (proc (case type
                   ((scatter) scatter-plot-fn)
                   ((pin)     pin-plot-fn)
                   ((bar)     bar-plot-fn)
                   ((dry)     dry-plot-fn)
                   (else      line-plot-fn))))
      (apply proc fn opts)))

  (define (intersperse a k lim)
    (let* ((r (/ lim k)))
      (let loop ((a  a)
                 (sa '())
                 (i  0)
                 (j  0))
        (cond ((> (floor j) (floor i))
                (loop a (cons #f sa) (+ 1 i) j))
              ((null? a)
                (reverse sa))
              (else
                (loop (cdr a) (cons (car a) sa) (+ 1 i) (+ j r)))))))

  (define (compress a k lim)
    (let* ((r (/ k lim)))
      (let loop ((a  a)
                 (sa '())
                 (i  0)
                 (j  0))
        (cond ((> (floor j) (floor i))
                (if (null? a)
                    (reverse (cdr sa))
                    (loop (cdr a) sa (+ 1 i) j)))
              ((null? a)
                (reverse sa))
              (else
                (loop (cdr a) (cons (car a) sa) (+ 1 i) (+ j r)))))))

  (define (spread-set a k lim)
    (cond ((= k lim) a)
          ((< k lim) (intersperse a k lim))
          (else      (compress a k lim))))

  (define (plot-set set . opts)
    (let* ((spread (get-value 'spread: opts #f))
           (res    (get-value 'res: opts 100)))
      (let* ((k    (length set))
             (set  (if (or (null? set) (pair? (car set)))
                       set
                       (map cons (iota 0 (- k 1)) set)))
             (set  (mergesort (lambda (a b) (< (car a) (car b)))
                              set))
             (vset (if spread
                       (list->vector (spread-set (map cdr set) k *X-size*))
                       (list->vector (map cdr set))))
             (k    (vector-length vset))
             (fn   (lambda (x)
                     (if (< x k)
                         (vector-ref vset (int x))
                         #f))))
        (apply plot-fn fn opts))))

  (define (plot-style? x) (<= 0 x 4))

  (define (plot-type? x) (memq x '(bar dry line pin scatter)))

  (define (sc:plot mapping . opts)
    (check-options opts `((from:   ,real?)
                          (res:    ,integer?)
                          (spread: ,boolean?)
                          (style:  ,plot-style?)
                          (to:     ,real?)
                          (type:   ,plot-type?)))
    (if (procedure? mapping)
        (apply plot-fn mapping opts)
        (apply plot-set mapping opts)))

  (define (sc:plot* x0 xN mapping . opts)
    (sc:setup x0 xN -1 1 'noplot: #t)
    (let* ((y0/yN (apply sc:plot mapping 'from: x0 'to: xN 'type: 'dry opts))
           (y0    (floor (min 0 (car y0/yN))))
           (yN    (floor (+ 1 (cadr y0/yN)))))
      (sc:setup x0 xN y0 yN)
      (apply sc:plot mapping opts)))

  (define (sc:caption . labels)
    (let* ((h      (sc:string-height "" 1))
           (height (* (length labels) h))
           (width  (+ (sc:string-width "  - " 1)
                      (apply max (map (lambda (x)
                                        (sc:string-width (cadr x) 1))
                                      labels)))))
      (let ((x  (- *XLIM* width 300))
            (y  (- *YLIM* 100))
            (dx (- *XLIM* 100))
            (dy (- *YLIM* height 300)))
        (sc:box x y dx dy #f #t)
        (sc:box x y dx dy #t #f)
        (for-each (lambda (lab pos)
                    (sc:put-string (+ x 200)
                                   (- y 250 (* pos h))
                                   1
                                   #t
                                   (string-append " - " (cadr lab)))
                    ((scatter-mark (car lab))
                     (+ x 150) (- y 200 (* pos h))))
                  labels
                  (iota 0 (- (length labels) 1))))))

  (sc:init)
  (set! setup   sc:setup)
  (set! plot    sc:plot)
  (set! plot*   sc:plot*)
  (set! caption sc:caption))

(define bar       'bar)
(define from:     'from:)
(define line      'line)
(define pin       'pin)
(define res:      'res:)
(define scatter   'scatter)
(define spread:   'spread:)
(define style:    'style:)
(define to:       'to:)
(define type:     'type:)
(define x-grid:   'x-grid:)
(define x-labels: 'x-labels:)
(define x-lstep:  'x-lstep:)
(define x-step:   'x-step:)
(define x-ticks:  'x-ticks:)
(define y-grid:   'y-grid:)
(define y-labels: 'y-labels:)
(define y-lstep:  'y-lstep:)
(define y-step:   'y-step:)
(define y-ticks:  'y-ticks:)

(define clear         sc:clear)
(define line          sc:line)
(define box           sc:box)
(define ellipse       sc:ellipse)
(define write-canvas  sc:write-canvas)
(define put-string    sc:put-string)
(define string-width  sc:string-width)
(define string-height sc:string-height)
