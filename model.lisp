(clear-all)

(define-model lost-agent

(sgp :egs 5 :ul t)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal phase player obstacle border-left border-right border-top border-bottom goal-x goal-y)
(chunk-type who-am-i step player last-x)
(chunk-type reach-target 
    step 
    target-x target-y 
    can-explore 
    pos-1-x pos-1-y
    pos-2-x pos-2-y
    pos-3-x pos-3-y
    pos-4-x pos-4-y
    pos-5-x pos-5-y
)

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
        last-x          0
)

(p request-top-row-tile-and-move-down 
    =goal>
        phase           who-am-i
    =imaginal>
        isa             who-am-i
        step            start
        last-x          =last-x
        player          nil
    ?manual>
        state           free
==>
    +visual-location>
        screen-y        lowest
        screen-x        lowest        
      > screen-x        =last-x
        kind            oval
    +manual>
        cmd             press-key
        key             s
    =imaginal>
        step            move
)

(p request-same-position-and-save-color
    =goal>
        phase           who-am-i
    =imaginal>
        step            move
        player          nil
    ?manual>
        state           free
    =visual-location>
        kind            oval
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
        last-x          =x
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
        goal-x          nil
        goal-y          nil
    =imaginal>
        target-x        =right
        target-y        =bottom
    =visual-location>
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y

    !eval! (> (+ =x 25) =right)
    !eval! (> (+ =y 25) =bottom)
    !bind! =center (/ (+ =top =bottom) 2)
==>
    =imaginal>
        target-x        =left
        target-y        =center
)
(p set-target-to-goal
    =goal>        
        goal-x          =x
        goal-y          =y
    =imaginal>
        target-x        nil
        target-y        nil
==>
    =imaginal>
        target-x        =x
        target-y        =y
)


(p enter-reach-target
    =goal>
        isa             goal
        phase           idle
        player          =player
        border-right    =right
        border-bottom   =bottom
        goal-x          nil
        goal-y          nil
    ?imaginal>
        buffer          empty
==>
    =goal>
        phase           reach-target
    +imaginal>
        isa             reach-target
        step            find
        target-x        =right
        target-y        =bottom
        pos-1-x         0
        pos-1-y         0
        pos-2-x         0
        pos-2-y         0
        pos-3-x         0
        pos-3-y         0
        pos-4-x         0
        pos-4-y         0
        pos-5-x         0
        pos-5-y         0
        

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

(p save-goal-pos-and-change-target
    =goal>
        isa             goal
        goal-x          nil
        goal-y          nil
    =imaginal>
    =visual-location>
        color           green
        screen-x        =x
        screen-y        =y
==>
    =goal>
        goal-x          =x
        goal-y          =y
    =imaginal>
        target-x        nil
        target-y        nil
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
        step            press-key
        key             d
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
        step            press-key
        key             s
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
        step            press-key
        key             a
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
        step            press-key
        key             w
)

;; PRESS KEY

(p press-key
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            press-key
        key             =key
        pos-1-x         =p1x
        pos-1-y         =p1y
        pos-2-x         =p2x
        pos-2-y         =p2y
        pos-3-x         =p3x
        pos-3-y         =p3y
        pos-4-x         =p4x
        pos-4-y         =p4y
        pos-5-x         =p5x
        pos-5-y         =p5y
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y
==>
    =imaginal>
        step            after-move
        pos-1-x         =x
        pos-1-y         =y
        pos-2-x         =p1x
        pos-2-y         =p1y
        pos-3-x         =p2x
        pos-3-y         =p2y
        pos-4-x         =p3x
        pos-4-y         =p3y
        pos-5-x         =p4x
        pos-5-y         =p4y
    +manual>
        cmd             press-key
        key             =key
)

;; GIVE REWARDS

;; (p didnt-not-travel-in-last-five-moves
;;     =goal>
;;         phase           reach-target
;;         player          =player
;;     =imaginal>
;;         step            after-move
;;         pos-5-x         =p5x
;;         pos-5-y         =p5y
;;       - pos-5-x         0
;;       - pos-5-y         0
;;     =visual-location>
;;         kind            oval
;;         color           =player
;;         screen-x        =x
;;         screen-y        =y
;;     !bind! =distance (sqrt (+ (expt (- =x =p5x) 2) (expt (- =y =p5y) 2)))
;;     !eval! (< =distance 30)
;; ==>
;;     =imaginal>
;;         step            create-subtarget
;; )

;; (p create-subtarget-top
;;     =goal>
;;         border-top      =top
;;     =imaginal>
;;         step            create-subtarget
;;         target-x        =x

;;     !bind! =udown (first (first (spp move-down :u)))
;;     !bind! =uup (first (first (spp move-down :u)))
;;     !bind! =uright (first (first (spp move-down :u)))
;;     !bind! =uleft (first (first (spp move-down :u)))
;;     !eval! (= =udown (max =udown =uup =uright =uleft))
;; ==>
;;     +imaginal>
;;         step            move
;;         target-x        =x
;;         target-y        =top
;;         pos-1-x         0
;;         pos-1-y         0
;;         pos-2-x         0
;;         pos-2-y         0
;;         pos-3-x         0
;;         pos-3-y         0
;;         pos-4-x         0
;;         pos-4-y         0
;;         pos-5-x         0
;;         pos-5-y         0
;; )

;; (p create-subtarget-bottom
;;     =goal>
;;         border-bottom      =bottom
;;     =imaginal>
;;         step            create-subtarget
;;         target-x        =x

;;     !bind! =udown (first (first (spp move-down :u)))
;;     !bind! =uup (first (first (spp move-down :u)))
;;     !bind! =uright (first (first (spp move-down :u)))
;;     !bind! =uleft (first (first (spp move-down :u)))
;;     !eval! (= =uup (max =udown =uup =uright =uleft))
;; ==>
;;     +imaginal>
;;         step            move
;;         target-x        =x
;;         target-y        =bottom
;;         pos-1-x         0
;;         pos-1-y         0
;;         pos-2-x         0
;;         pos-2-y         0
;;         pos-3-x         0
;;         pos-3-y         0
;;         pos-4-x         0
;;         pos-4-y         0
;;         pos-5-x         0
;;         pos-5-y         0
;; )

;; (> (first (first (spp move-down :u))) (first (first (spp move-up :u))))

(p reward-change-of-distance-to-target
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            after-move
        pos-1-x         =x-old
        pos-2-y         =y-old
        target-x        =target-x
        target-y        =target-y
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
    !eval! (trigger-reward (- =distance-old =distance) 2)
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
        pos-1-x          =x
        pos-1-y          =y
    =visual-location> 
        color           =player
        kind            oval
        screen-x        =x
        screen-y        =y
    ?manual>
        state           free    
==>
    =imaginal>
        step            move
        can-explore     nil
)

;; (p obstacle-known
;;     =goal>
;;         phase           reach-target
;;       - obstacle        nil
;;     =imaginal>
;;         step            eval-did-not-move
;; ==>
;;     =imaginal>
;;         step            move
;; )

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

;; (p obstacle-color-unknown
;;     =goal>
;;         phase           reach-target
;;         player          =player
;;         obstacle        nil
;;     =imaginal>
;;         step            eval-did-not-move
;;     =visual-location>
;;         kind            oval
;;         color           =color
;;       - color           =player
;; ==>
;;     =goal>
;;         obstacle        =color
;;     =imaginal>
;;         step            move
;; )

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

(spp reward-change-of-distance-to-target :fixed-utility t :u -10)
(spp reward-position-did-not-change :fixed-utility t :u 20 :reward -15)
)