(TeX-add-style-hook "ordinal"
 (function
  (lambda ()
    (LaTeX-add-bibliographies
     "biblio")
    (LaTeX-add-labels
     "sec:introduction"
     "sec:OR"
     "eq:margin"
     "sec:MS"
     "fig:Rosenbrock"
     "tbl:Rosenbrock"
     "sec:MI"
     "fig:sphere"
     "fig:sphere2"
     "fig:rosen"
     "sec:Discussion"
     "fig:Monte")
    (TeX-add-symbols
     '("inner" 2)
     '("strng" 1)
     '("mat" 1)
     '("norm" 1)
     "reals"
     "argmax"
     "argmin"
     "bs")
    (TeX-run-style-hooks
     "graphicx"
     "psfrag"
     "dvips"
     "amsmath"
     "amssymb"
     "times"
     "latexsym"
     "babel"
     "english"
     "latex2e"
     "llncs10"
     "llncs"
     "10pt"))))

