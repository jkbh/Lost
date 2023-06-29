(clear-all)

(define-model lost-agent

(sgp :egs 0.2)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal state intention)
(chunk-type control intention button)

(add-dm
    (move-left) (move-right)
    (move-up)  (move-down)
    (w) (a) (s) (d)
    (i-dont-know-where-to-go)
    (something-should-change)
    (i-want-to-do-something)
    (up-control isa control intention move-up button w)
    (down-control isa control intention move-down button s)
    (left-control isa control intention move-left button a)
    (right-control isa control intention move-right button d)
    (first-goal isa goal state i-dont-know-where-to-go)
)

(goal-focus first-goal)

(p want-to-move
    =goal>
        state i-want-to-do-something
        intention =intention
    ?retrieval>
        state free
==>
    =goal>
        state something-should-change
   +retrieval>
        intention =intention
)

(p move
    =goal>
        state something-should-change
    =retrieval>
        button =button
    ?manual>
        state free
==>
    =goal>
        state i-dont-know-where-to-go
    +manual>
        cmd press-key
        key =button
)

(p retrieval-failure
    =goal>
        state something-should-change
    ?retrieval>
        buffer failure
==>
    =goal>
        state i-dont-know-where-to-go
)

(p maybe-left
    =goal>
        state i-dont-know-where-to-go
    ?manual>
        state free
==>
    =goal>
        state i-want-to-do-something
        intention move-left
)

(p maybe-right
    =goal>
        state i-dont-know-where-to-go
    ?manual>
        state free
==>
    =goal>
        state i-want-to-do-something
        intention move-right
)

(p maybe-down
    =goal>
        state i-dont-know-where-to-go
    ?manual>
        state free
==>
    =goal>
        state i-want-to-do-something
        intention move-down
)

(p maybe-up
    =goal>
        state i-dont-know-where-to-go
    ?manual>
        state free
==>
    =goal>
        state i-want-to-do-something
        intention move-up
)

)