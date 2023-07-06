(clear-all)

(define-model lost-agent

(sgp :egs 0.2)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

;;(chunk-type goal state player center-x center-y)
;;(chunk-type task target-pos)

;;(chunk-type reach-target player target)

(chunk-type goal phase player target-x target-y border-left border-right border-top border-bottom goal-x goal-y)

(chunk-type who-am-i step player)
(chunk-type reach-target step player target-x target-y can-untrack)
;; (chunk-type get-borders step center-x center-y)


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
    +manual>
        cmd             press-key
        key             w
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
(p enter-get-borders-and-request-left
    =goal>
        isa             goal
        phase           idle
        player          =player
        border-left     nil
        border-right    nil
        border-top      nil
        border-bottom   nil
==>
    =goal>
        phase           get-borders
    +visual-location>
        color           yellow
        kind            line
        screen-x        lowest
        :attended       nil
)

(p save-border-left
    =goal>
        phase           get-borders
        border-left     nil
    =visual-location>
        color           yellow
        kind            line
        screen-x        =left
==>
    =goal>
        border-left     =left
    +visual>
        screen-pos      =visual-location
        cmd             move-attention
    +visual-location>
        color           yellow
        kind            line
        screen-x        highest
        :attended       nil
)

(p save-border-top-right-bottom-and-leave-phase
    =goal>
        phase           get-borders
      - border-left     nil  
        border-top      nil        
        border-bottom   nil
        border-right    nil      
    =visual-location>
        color           yellow
        kind            line
        screen-x        =x
    =visual>
        color           yellow
        end1-y          =y1
        end2-y          =y2
==>
    =goal>  
        border-top      =y2
        border-bottom   =y1
        border-right    =x
        target-x        =x
        target-y        =y1
        phase           idle
)

;; LOCK ONTO PLAYER

(p change-target-from-bottom-left-to-bottom-right
    =goal>
        isa             goal
        phase           reach-target
        player          =player
        border-top      =top
        border-bottom   =bottom
        border-left     =left
        border-right    =right        
        target-x        =right
        target-y        =bottom
        goal-x          nil
        goal-y          nil
    =visual-location>
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y

    !eval! (> (+ =x 25) =right)
    !eval! (> (+ =y 25) =bottom)
    !bind! =center (/ (+ =top =bottom) 2)
==>
    =goal>
        target-x        =left
        target-y        =center
)

(p enter-reach-target
    =goal>
        isa             goal
        phase           idle
        player          =player
        target-x        =target-x
        target-y        =target-y
==>
    =goal>
        phase           reach-target
    +imaginal>
        isa             reach-target
        step            find
        can-untrack     nil
)

(p detect-goal
    =goal>
        isa             goal
        goal-x          nil
        goal-y          nil
    =imaginal>
        isa             reach-target
        can-untrack     t
==>
    +visual-location>
        color           green
    =imaginal>
        can-untrack     nil
)

(p save-goal-pos-and-change-target
    =goal>
        isa             goal
        goal-x          nil
        goal-y          nil
    =visual-location>
        color           green
        screen-x        =x
        screen-y        =y
==>
    =goal>
        goal-x          =x
        goal-y          =y
        target-x        =x
        target-y        =y
)

(p find-player
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        isa             reach-target
        step            find
==>
    =imaginal>
        step            attend
    +visual-location>
        color           =player
        kind            oval
)

(p attend-player
    =goal>
        phase       reach-target
        player      =player
    =imaginal>
        isa         reach-target
        step        attend
    =visual-location>
        color       =player 
        kind        oval     
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
        player      =player
    =imaginal>
        isa         reach-target
        step        track
    =visual>
        color       =player   
        oval        t  
==>
    +visual>
        cmd         start-tracking
    =imaginal>
        step        move
)

(p move-right
    =goal>
        phase           reach-target
        target-x        =target-x
        player          =player
    =imaginal>
        isa             reach-target
        step            move
    =visual-location>
        color           =player
        screen-x        =x
    ?manual>
        state           free

    !eval!      (< =x =target-x)
==>
    =imaginal>
        can-untrack     t
    +manual>
        cmd             press-key
        key             d
)

(p move-down
    =goal>
        phase           reach-target
        target-y        =target-y
        player          =player
    =imaginal>
        isa             reach-target
        step            move
    =visual-location>
        color           =player
        screen-y        =y
    ?manual>
        state           free

    !eval!      (< =y =target-y)
==>
    =imaginal>
        can-untrack     t
    +manual>
        cmd             press-key
        key             s
)

(p move-left
    =goal>
        phase       reach-target
        target-x    =target-x
        player      =player
    =imaginal>
        isa         reach-target
        step        move
    =visual-location>
        color       =player
        screen-x    =x
    ?manual>
        state       free

    !eval!      (> =x =target-x)
==>
    =imaginal>
        can-untrack     t
    +manual>
        cmd         press-key
        key         a
)

(p move-up
    =goal>
        phase       reach-target
        target-y    =target-y
        player      =player
    =imaginal>
        isa         reach-target
        step        move
    =visual-location>
        color       =player
        screen-y    =y
    ?manual>
        state       free

    !eval!      (> =y =target-y)
==>
    =imaginal>
        can-untrack     t
    +manual>
        cmd         press-key
        key         w
)
)