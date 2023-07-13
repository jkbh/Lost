(clear-all)

(define-model lost-agent

(sgp :egs 5 :ul t)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal phase player obstacle bonus malus target-x target-y border-left border-right border-top border-bottom goal-x goal-y)
(chunk-type who-am-i step player)
(chunk-type reach-target step player target-x target-y can-explore last-x last-y desired-x desired-y explore-color)

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
;; ############## FINDING BORDERS ##################

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

(p change-target-from-bottom-eight-to-center-left
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
(p set-target-to-goal
    =goal>
        target-x        nil
        target-y        nil
        goal-x          =x
        goal-y          =y
==>
    =goal>
        target-x        =x
        target-y        =y
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
)

(p request-goal
    =goal>
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

(p save-goal-pos
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
        target-x        nil
        target-y        nil
)

(p request-unknown-tile-color
    =goal>
        isa             goal
        player          =player
        obstacle        =obstacle
        bonus           nil
    =imaginal>
        isa             reach-target
        can-explore     t
        explore-color   nil
==>
    +visual-location>
        kind            oval
      - color           =player
      - color           =obstacle
      - color           green
    =imaginal>
        can-explore     nil
)

(p target-unknown-tile
    =goal>
        isa             goal
        player          =player
        obstacle        =obstacle
        bonus           nil
    =imaginal>
        isa             reach-target
    =visual-location>
        kind            oval
      - color           =player
      - color           =obstacle
      - color           green
        color           =color
        screen-x        =x
        screen-y        =y
==>    
    ;; +visual-location>
    ;;     color           =player
    ;;     kind            oval
    =goal>
        target-x        =x
        target-y        =y
    =imaginal>
        can-explore     nil
        explore-color   =color
)

(p reached-explore-target
    =goal>
        player          =player
        target-x        =x
        target-y        =y
    =imaginal>
        step            after-move
        explore-color   =color
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y
==>
    =imaginal>
        step            attend-text
    +visual>
        cmd             clear
    +visual-location>
        kind            text
        color           red
        screen-x        lowest
)

(p attend-red-font
     =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            attend-text
        explore-color   =explore-color
    =visual-location>
        kind            text
        color           red
==>
    =imaginal>
    +visual>
        cmd             move-attention
        screen-pos      =visual-location
)

(p save-bonus
    =goal>
    =imaginal>
        step            attend-text
        explore-color   =explore-color
    =visual>
        kind            text
        color           red
        value           "+"
==>
    =goal>
        bonus           =explore-color
        target-x        nil
        target-y        nil
    =imaginal>
        step            find
        explore-color   nil
)

(p save-malus
    =goal>
    =imaginal>
        step            attend-text
        explore-color   =explore-color
    =visual>
        kind            text
        color           red
        value           "-"
==>
    =goal>
        malus           =explore-color
        target-x        nil
        target-y        nil
    =imaginal>
        step            find
        explore-color   nil
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
        target-x        =target-x
    =imaginal>
        step            move
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y

    !eval! (< =x =target-x)
    !eval! (< =x (- =x-max 25))
    !bind! =xnew (+ =x 25)
==>
    =imaginal>
        step            press-key
        key             d
        desired-x       =xnew
        desired-y       =y
)

(p move-down
    =goal>
        phase           reach-target
        player          =player
        border-bottom   =y-max
        target-y        =target-y
    =imaginal>
        step            move
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y   

    !eval! (< =y =target-y)
    !eval! (< =y (- =y-max 25))
    !bind! =ynew (+ =y 25)
==>
    =imaginal>
        step            press-key
        key             s
        desired-x       =x
        desired-y       =ynew
)

(p move-left
    =goal>
        phase           reach-target
        player          =player
        border-left     =x-min
        target-x        =target-x
    =imaginal>
        step            move
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y

    !eval! (> =x =target-x)
    !eval! (> =x (+ =x-min 25))
    !bind! =xnew (- =x 25)
==>
    =imaginal>
        step            press-key
        key             a
        desired-x       =xnew
        desired-y       =y
)

(p move-up
    =goal>
        phase           reach-target
        player          =player
        border-top      =y-min
        target-y        =target-y
    =imaginal>
        step            move
    =visual-location>
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y

    !eval! (> =y =target-y)
    !eval! (> =y (+ =y-min 25))
    !bind! =ynew (- =y 25)
==>
    =imaginal>
        step            press-key
        key             w
        desired-x       =x
        desired-y       =ynew
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
        screen-x        =x
        screen-y        =y
==>
    =imaginal>
        step            after-move
        last-x          =x
        last-y          =y
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
    ;; !eval! (trigger-reward (- =distance-old =distance))
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
        can-explore     nil
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

(p request-obstacle
    =goal>
        player          =player
        obstacle        nil
    =imaginal>
        step            eval-did-not-move
        desired-x       =x
        desired-y       =y
==>
    =imaginal>
    +visual-location>
        kind            oval
        screen-x        =x
        screen-y        =y     
)

(p obstacle-color-unknown
    =goal>
        phase           reach-target
        player          =player
        obstacle        nil
    =imaginal>
        step            eval-did-not-move
    =visual-location>
        kind            oval
        color           =color
      - color           =player
==>
    =goal>
        obstacle        =color
    =imaginal>
        step            move
)

(p obstacle-request-failure
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            eval-did-not-move
    ?visual-location>
        buffer          failure
==>
    =imaginal>
        step            move
)

(spp reward-change-of-distance-to-target :fixed-utility t :u -10)
(spp reward-position-did-not-change :fixed-utility t :u 20)
)