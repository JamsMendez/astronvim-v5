;; extends

; GoLand-style call coloring (used by the "goland" colorscheme). Priority 130 sits above
; gopls semantic tokens (125-127), so calls keep these colors with semanticTokens on.

; Method calls and exported package calls: logger.Info(), signal.NotifyContext()
(call_expression
  function: (selector_expression
    field: (field_identifier) @function.method.call)
  (#set! priority 130))

; Exported calls inside the same package: NewServer()
((call_expression
  function: (identifier) @function.call)
  (#lua-match? @function.call "^[A-Z]")
  (#set! priority 130))

; Local unexported calls stay plain: run(), stop(), cancel()
((call_expression
  function: (identifier) @goland.call.local)
  (#lua-match? @goland.call.local "^[a-z_]")
  (#not-any-of? @goland.call.local
    "append" "cap" "clear" "close" "complex" "copy" "delete" "imag" "len" "make" "max" "min"
    "new" "panic" "print" "println" "real" "recover")
  (#set! priority 130))
