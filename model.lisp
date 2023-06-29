(clear-all)

(define-model lost-agent

(sgp :egs 0.2)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

;;(chunk-type goal state player center-x center-y)
;;(chunk-type task target-pos)

;;(chunk-type reach-target player target)

(chunk-type goal phase player target-x target-y)

(chunk-type who-am-i step player)
(chunk-type reach-target step player target-x target-y)
(chunk-type get-center step center-x center-y)


(add-dm
    (first-goal isa goal phase idle)
)

(goal-focus first-goal)

(p enter-whoami
    =goal>
        isa             goal   
        phase           idle   
        player          nil
==>
    =goal>
        phase           who-am-i
    +imaginal>
        isa             who-am-i
        step            start
)

(p request-top-row-tile-and-move-down
    =goal>
        phase           who-am-i
    =imaginal>
        isa             who-am-i
        step            start
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
    =imaginal>
        step            move
)

(p request-same-position-and-save-color
    =goal>
        isa             goal
        phase           who-am-i
    =imaginal>
        isa             who-am-i
        step            move
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
    =imaginal>
        player          =color
        step            check
)

(p finish-whoami
    =goal>
        isa             goal
        phase           who-am-i
    =imaginal>
        isa             who-am-i
        step            check
        player          =player
    ?visual-location>
        buffer          failure
==>
    =goal>
        phase           idle
        player          =player   
)

(p forget-color
    =goal>
        isa             goal
        phase           who-am-i
    =imaginal>
        isa             who-am-i
        step            check
    ?visual-location>
        buffer          full
==>
    =imaginal>
        player          nil
        step            start
)
;; ############## FINDING CENTER ##################
(p enter-get-center
    =goal>
        isa             goal
        phase           idle
        player          =player
        target-x        nil
        target-y        nil
==>
    =goal>
        phase           get-center
    +imaginal>
        isa             get-center
        step            left
)

(p request-border-left
    =goal>
        phase           get-center
    =imaginal>
        isa             get-center
        step            left
        center-x        nil
        center-y        nil
==>
    +visual-location>
        color           yellow
        kind            line
        screen-x        lowest
        :attended       nil
    =imaginal>
        step            top
)

(p save-center-y-and-request-border-top
    =goal>
        phase           get-center
    =imaginal>
        isa             get-center
        step            top
        center-x        nil
        center-y        nil
    =visual-location>
        color           yellow
        screen-y        =y
==>
    +visual-location>
        color           yellow
        kind            line
        screen-y        lowest
        :attended       nil
    =imaginal>  
        center-y        =y
        step            finish
)

(p save-center-x
    =goal>
        phase           get-center
    =imaginal>
        isa             get-center
        step            finish
        center-y        =y
    =visual-location>
        color           yellow
        screen-x        =x
==>
    =goal>
        phase           idle
        target-x        =x
        target-y        =y
)

;; LOCK ONTO PLAYER

(p enter-reach-target
    =goal>
        isa         goal
        phase       idle
        player      =player
        target-x    =target-x
        target-y    =target-y
==>
    =goal>
        phase       reach-target
    +imaginal>
        isa         reach-target
        player      =player
        target-x    =target-x
        target-y    =target-y
)

(p find-player
    =goal>
        phase       reach-target
    =imaginal>
        isa         reach-target
        player      =player
        step        nil
    ?visual-location>
        buffer      empty
    ?visual>
        buffer      empty
==>
    =imaginal>
        step        attend
    +visual-location>
        color       =player
)

(p attend-player
    =goal>
        phase       reach-target
    =imaginal>
        isa         reach-target
        player      =player
        step        attend
    =visual-location>
        color       =player 
    ?visual>
        buffer      empty       
==>
    =imaginal>
        step        track
    +visual>
        screen-pos  =visual-location  
        cmd         move-attention
)

(p track-player
    =goal>
        phase       reach-target
    =imaginal>
        isa         reach-target
        player      =player
        step        track
    =visual>
        color       =player      
==>
    +visual>
        cmd         start-tracking
    =imaginal>
        step        move
)

(p move-right
    =goal>
        phase       reach-target
    =imaginal>
        isa         reach-target
        step        move
        target-x    =target-x
        player      =player
    =visual-location>
        color       =player
        screen-x    =x
        screen-y    =y
    ?manual>
        state       free

    !eval!      (< =x =target-x)
==>
    =imaginal>
    +manual>
        cmd         press-key
        key         d
)

(p move-down
    =goal>
        phase       reach-target
    =imaginal>
        isa         reach-target
        step        move
        target-y    =target-y
        player      =player
    =visual-location>
        color       =player
        screen-x    =x
        screen-y    =y
    ?manual>
        state       free

    !eval!      (< =y =target-y)
==>
    =imaginal>
    +manual>
        cmd         press-key
        key         s
)
)