(clear-all)

(define-model lost-agent

(sgp :egs 0.2)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal-old state intention)
(chunk-type control intention button)
(chunk-type goal state player goal-pos)

(add-dm
    (first-goal isa goal state towards-goal)
)

(goal-focus first-goal)

(p enter-whoami
    =goal>
        isa             goal
        state           towards-goal
        player          nil
==>
    =goal>
        state           whoami-start
)

(p request-top-row-tile-and-move-down
    =goal>
        isa             goal
        state           whoami-start
        player          nil
    ?manual>
        state           free
==>
    +visual-location>
        screen-y        lowest
        kind            oval
        :attended       nil
    +manual>
        cmd             press-key
        key             s
    =goal>
        state           whoami-move
)

(p request-same-position-and-save-color
    =goal>
        isa             goal
        state           whoami-move
        player          nil
    ?manual>
        state           free
    =visual-location>
        screen-x        =x
        screen-y        =y
        color           =color
==>    
    +visual-location>
        screen-x        =x
        screen-y        =y
    =goal>
        player          =color
        state           whoami-check
)

(p finish-whoami
    =goal>
        isa             goal
        state           whoami-check
    ?visual-location>
        buffer          failure
==>
    =goal>
        state           towards-goal
)

(p forget-color
    =goal>
        isa             goal
        state           whoami-check
    ?visual-location>
        buffer          full
==>
    =goal>
        player          nil
        state           whoami-start
)
)