(TeX-add-style-hook "poly2global"
 (function
  (lambda ()
    (TeX-run-style-hooks
     "amsmath"
     "graphicx"
     "psfrag"
     "latex2e"
     "art12"
     "article"
     "12pt"))))

