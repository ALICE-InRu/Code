(TeX-add-style-hook "poster"
 (function
  (lambda ()
    (TeX-add-symbols
     '("inner" 2)
     '("strng" 1)
     '("mat" 1)
     '("norm" 1)
     "reals"
     "argmax"
     "argmin")
    (TeX-run-style-hooks
     "latex2e"
     "a0poster10"
     "a0poster"
     "a0"
     "portrait"
     "sections/style"
     "sections/header"
     "sections/intro"
     "sections/method1"
     "sections/method2"
     "sections/method3"
     "sections/results"
     "sections/conc"
     "sections/footer"))))

