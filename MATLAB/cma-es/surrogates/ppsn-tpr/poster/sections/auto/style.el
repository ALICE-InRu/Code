(TeX-add-style-hook "style"
 (function
  (lambda ()
    (TeX-add-symbols
     "regularsize")
    (TeX-run-style-hooks
     "times"
     "colordvi"
     "amsmath"
     "epsfig"
     "float"
     "color"
     "multicol"))))

