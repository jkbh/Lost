(clear-all)

(define-model lost-agent

(sgp :egs 5 :ul t)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal phase player obstacle bonus malus target-x target-y border-left border-right border-top border-bottom goal-x goal-y)
(chunk-type who-am-i step player)
(chunk-type reach-target step player target-x target-y can-explore last-x last-y desired-x desired-y desired-color explore-color)

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

;; GOAL DETECTION

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

;; TRACKING PLAYER

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
    +visual-location>
        kind            oval
        screen-x        =xnew
        screen-y        =y    
    =imaginal>
        step            lookahead
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
    +visual-location>
        kind            oval
        screen-x        =x
        screen-y        =ynew  
    =imaginal>
        step            lookahead
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
    +visual-location>
        kind            oval
        screen-x        =xnew
        screen-y        =y  
    =imaginal>
        step            lookahead
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
    +visual-location>
        kind            oval
        screen-x        =x
        screen-y        =ynew
    =imaginal>
        step            lookahead
        key             w
        desired-x       =x
        desired-y       =ynew
)

;; LOOKAHEAD

(p desired-empty
    =goal>
    =imaginal>
        step            lookahead
    ?visual-location>
        buffer          failure
==>
    =imaginal>
        step            press-key
)

(p desired-unknown
    =goal>
    =imaginal>
        step            lookahead
    =visual-location>
        kind            oval
        color           =desired-color
==>
    =imaginal>
        desired-color   =desired-color
        step            press-key
)

(p desired-blocked
    =goal>
        obstacle        =obstacle
    =imaginal>
        step            lookahead
    =visual-location>
        kind            oval
        color           =obstacle
==>
    =imaginal>
        desired-color   nil
        step            move
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

;; EVAL DID MOVE

(p give-distance-reward
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
        ;; can-explore     t
        step            eval-did-move
)

(p skip-eval-did-move
    =goal>
    =imaginal>
        step            eval-did-move
==>
    =imaginal>
        step            move
)
(spp skip-eval-did-move :fixed-utility t)

(p clear-visual-buffer-for-score
    =goal>
        bonus           nil
    =imaginal>
        step            eval-did-move
        desired-color   =color
==>
    =imaginal>
        step            find-score
    +visual>
        cmd             clear
)
(spp clear-visual-buffer-for-score :fixed-utility t :u 1)

(p request-red-text
    =goal>
        bonus           nil
    =imaginal>
        step            find-score
==>
    =imaginal>
        step            attend-score
    +visual>
        cmd             clear
    +visual-location>
        kind            text
        color           red
        screen-x        lowest
)

(p attend-score
    =goal>
    =imaginal>
        step            attend-score
    =visual-location>
        kind            text
        color           red
==>
    =imaginal>
        step            react-to-text
    +visual>
        cmd             move-attention
        screen-pos      =visual-location
)

(p save-bonus
    =goal>
    =imaginal>
        step            react-to-text
        desired-color   =color
    =visual>
        value           "+"
==>
    =imaginal>
        bonus           =color
        step            find
)

(p save-malus
    =goal>
    =imaginal>
        step            react-to-text
        desired-color   =color
    =visual>
        value           "-"
==>
    =imaginal>
        malus           =color
        step            find
)

;; EVAL DIDNT MOVE

(p give-move-against-wall-reward
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

(p skip-did-not-move-evaluation
    =goal>
        phase           reach-target
      - obstacle        nil
    =imaginal>
        step            eval-did-not-move
==>
    =imaginal>
        step            move
)

;; (p request-obstacle
;;     =goal>
;;         player          =player
;;         obstacle        nil
;;     =imaginal>
;;         step            eval-did-not-move
;;         desired-x       =x
;;         desired-y       =y
;; ==>
;;     =imaginal>
;;     +visual-location>
;;         kind            oval
;;         screen-x        =x
;;         screen-y        =y     
;; )

(p save-blocking-color
    =goal>
        phase           reach-target
        player          =player
        obstacle        nil
    =imaginal>
        step            eval-did-not-move
        desired-color   =color
==>
    =goal>
        obstacle        =color
    =imaginal>
        step            move
)

;; (p obstacle-request-failure
;;     =goal>
;;         phase           reach-target
;;         player          =player
;;     =imaginal>
;;         step            eval-did-not-move
;;     ?visual-location>
;;         buffer          failure
;; ==>
;;     =imaginal>
;;         step            move
;; )

(spp give-distance-reward :fixed-utility t :u -10)
(spp give-move-against-wall-reward :fixed-utility t :u 20)
)