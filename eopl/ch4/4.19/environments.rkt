#lang eopl

(require "data-structures.rkt")
(require "store.rkt")
(provide init-env empty-env extend-env apply-env extend-env-rec)

;;;;;;;;;;;;;;;; initial environment ;;;;;;;;;;;;;;;;

;; init-env : () -> Env
;; (init-env) builds an environment in which:
;; i is bound to a location containing the expressed value 1,
;; v is bound to a location containing the expressed value 5, and
;; x is bound to a location containing the expressed value 10.
(define init-env
  (lambda ()
    (extend-env
     'i (newref (num-val 1))
     (extend-env
      'v (newref (num-val 5))
      (extend-env
       'x (newref (num-val 10))
       (empty-env))))))

;;;;;;;;;;;;;;;; environment constructors and observers ;;;;;;;;;;;;;;;;

(define apply-env
  (lambda (env search-var)
    (cases environment env
      (empty-env ()
                 (eopl:error 'apply-env "No binding for ~s" search-var))
      (extend-env (bvar bval saved-env)
                  (if (eqv? search-var bvar)
                      bval
                      (apply-env saved-env search-var)))
      (extend-env-rec* (p-names vec saved-env)
                       (let ((n (location search-var p-names)))
                         ;; n : (maybe int)
                         (if n
                             (newref (list-ref
                                      (vector-ref vec 0) n))
                             (apply-env saved-env search-var)))))))

;; location : Sym * Listof(Sym) -> Maybe(Int)
;; (location sym syms) returns the location of sym in syms or #f is
;; sym is not in syms.  We can specify this as follows:
;; if (memv sym syms)
;;   then (list-ref syms (location sym syms)) = sym
;;   else (location sym syms) = #f
(define location
  (lambda (sym syms)
    (cond
      ((null? syms) #f)
      ((eqv? sym (car syms)) 0)
      ((location sym (cdr syms))
       => (lambda (n)
            (+ n 1)))
      (else #f))))

;;; extend for 4.19
(define (extend-env-rec p-names b-vars bodies saved-env)
  (let ((vec (make-vector 1)))
    (let ((new-env (extend-env-rec* p-names vec saved-env)))
      ;; generate the proc-vals
      (vector-set! vec 0
                   (map (lambda (p-info) (proc-val (procedure
                                                    (car p-info)
                                                    (cadr p-info)
                                                    new-env)))
                        (map list b-vars bodies)))
      new-env
      )))