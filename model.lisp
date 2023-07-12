(clear-all)

(define-model lost-agent

(sgp :egs 5 :ul t)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal phase player target-x target-y border-left border-right border-top border-bottom goal-x goal-y obstacle)
(chunk-type who-am-i step player)
(chunk-type reach-target step player target-x target-y can-explore last-x last-y desired-x desired-y desired-color)

(chunk-type target pos)

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
        move-count      0
)

(p detect-goal
    =goal>
        isa             goal
        goal-x          nil
        goal-y          nil
    =imaginal>
        isa             reach-target
        can-explore     t
==>
    +visual-location>
        color           green
    =imaginal>
        can-explore     nil
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

;; MOVEMENT

(p move-right
    =goal>
        phase           reach-target
        player          =player
        border-right    =x-max
    =imaginal>
        step            move
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y
    !eval! (< =x (- =x-max 25))
    !bind! =xnew (+ =x 25)
==>
    =imaginal>
        step            before-press
        key             d
        desired-x       =xnew
        desired-y       =y
)

(p move-down
    =goal>
        phase           reach-target
        player          =player
        border-bottom   =y-max
    =imaginal>
        step            move
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y   
    !eval! (< =y (- =y-max 25))
    !bind! =ynew (+ =y 25)
==>
    =imaginal>
        step            before-press
        key             s
        desired-x       =x
        desired-y       =ynew
)

(p move-left
    =goal>
        phase           reach-target
        player          =player
        border-left     =x-min
    =imaginal>
        step            move
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y
    !eval! (> =x (+ =x-min 25))
    !bind! =xnew (- =x 25)
==>
    =imaginal>
        step            before-press
        key             a
        desired-x       =xnew
        desired-y       =y
)

(p move-up
    =goal>
        phase           reach-target
        player          =player
        border-top      =y-min
    =imaginal>
        step            move
    =visual-location>
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y
    !eval! (> =y (+ =y-min 25))
    !bind! =ynew (- =y 25)
==>
    =imaginal>
        step            before-press
        key             w
        desired-x       =x
        desired-y       =ynew
)

;; CHECK DESIRED POSITION

(p request-desired-loc
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            before-press
        desired-x      =desired-x
        desired-y      =desired-y
    =visual-location>
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y
==>
    +visual-location>
        kind            oval
        screen-x        =desired-x
        screen-y        =desired-y
    =imaginal>
        step            before-press
        last-x          =x
        last-y          =y
)

(p save-desired-color
    =goal>
        player          =player
    =imaginal>
        step            before-press
    =visual-location>
      - color           =player
        color           =color
 ==>
    =imaginal>
        step            press-key 
        desired-color   =color
    +visual-location>
        player          =player
        kind            oval
)

(p request-player
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            before-press
    ?visual-location>
        buffer          failure
==>
    =imaginal>
        step            press-key
    +visual-location>
        kind            oval
        color           =player
)

;; PRESS KEY

(p press-key
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            press-key
        key             =key
    =visual-location>
        color           =player
==>
    =imaginal>
        step            after-move
    +manual>
        cmd             press-key
        key             =key
)

;; GIVE REWARDS

(p reward-change-of-distance-to-target
    =goal>
        phase           reach-target
        player          =player
        target-x        =target-x
        target-y        =target-y
    =imaginal>
        step            after-move
        last-x          =x-old
        last-y          =y-old
    =visual-location>
        kind            oval
        color           =player
        screen-x        =x
        screen-y        =y
    ?manual>
        state           free
    
    !bind! =distance-old (sqrt (+ (expt (- =x-old =target-x) 2) (expt (- =y-old =target-y) 2)))
    !bind! =distance (sqrt (+ (expt (- =x =target-x) 2) (expt (- =y =target-y) 2)))
==>
    !eval! (trigger-reward (- =distance-old =distance))
    =imaginal>
        can-explore     t
        step            move
)

(p reward-position-did-not-change
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            after-move
        last-x          =x
        last-y          =y
    =visual-location> 
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y
    ?manual>
        state           free
==>
    =imaginal>
        step            eval-did-not-move
    can-explore         nil
)

(p obstacle-known
    =goal>
        phase           reach-target
      - obstacle        nil
    =imaginal>
        step            eval-did-not-move
==>
    =imaginal>
        step            move
)

(p request-blocking-tile
    =goal>
        phase           reach-target
        player          =player
        obstacle        nil
    =imaginal>
        step            eval-did-not-move
        desired-x       =x
        desired-y       =y
==>
    =imaginal>
    +visual-location>
      - color           =player
        kind            oval
        screen-x        =x
        screen-y        =y
)

(p get-obstacle-color
    =goal>
        phase           reach-target
        player          =player
        obstacle        nil
    =imaginal>
        step            eval-did-not-move
    =visual-location>
        color           =color
      - color           =player
        kind            oval
==>
    +visual-location>

    =goal>
        obstacle        =color
    =imaginal>
        step            move
)

(spp (
    detect-goal
    save-goal-pos-and-change-target
    press-key
    find-player
    attend-player
    track-player
    reward-change-of-distance-to-target
    reward-position-did-not-change)
:fixed-utility t)

(spp reward-change-of-distance-to-target :u 10)
(spp reward-position-did-not-change :u 20 :reward -15)
)