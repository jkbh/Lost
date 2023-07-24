(clear-all)

(define-model lost-agent

(sgp :egs 0 :ul t)  ; Dieses Modell verwendet Utility. Der utility noise kann ausgeschaltet werden, indem dieser Parameter auf 0 gesetzt wird.
(sgp :esc t)    ; Dieses Modell verwendet subsymbolische Verarbeitung
(sgp :v t :show-focus t :trace-detail high)

(chunk-type goal phase player obstacle border-left border-right border-top border-bottom goal-x goal-y)
(chunk-type who-am-i step player last-x)
(chunk-type reach-target step target-x target-y can-explore desired-x desired-y desired-color left-blocked right-blocked down-blocked up-blocked)

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
        target-x        =target-x
        right-blocked   nil
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y

    !eval! (< =x =target-x)
    !eval! (< =x (- =x-max 25))
    !bind! =xnew (+ =x 25)
==>
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
    =imaginal>
        step            move
        target-y        =target-y
        down-blocked    nil
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y

    !eval! (< =y =target-y)
    !eval! (< =y (- =y-max 25))
    !bind! =ynew (+ =y 25)
==>
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
    =imaginal>
        step            move
        target-x        =target-x
        left-blocked    nil
    =visual-location>
        color           =player
        screen-x        =x
        screen-y        =y

    !eval! (> =x =target-x)
    !eval! (> =x (+ =x-min 25))
    !bind! =xnew (- =x 25)
==>
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
    =imaginal>
        step            move
        target-y        =target-y
        up-blocked      nil
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
        step            lookahead
        key             w
        desired-x       =x
        desired-y       =ynew
)

(p no-move
    =goal>
        phase           reach-target
    =imaginal>
        step            move
==>
    =imaginal>
)

(spp (move-left move-right move-up move-down) :fixed-utility t :u 100)
(spp no-move :fixed-utility t :u 0)
;; LOOKAHEAD

(p request-desired-location
    =goal>
    =imaginal>
        step            lookahead
        desired-x       =x
        desired-y       =y
==>
    =imaginal>
    +visual-location>
        kind            oval
        screen-x        =x
        screen-y        =y
)

(p empty-lookahead
    =goal>
    =imaginal>
        step            lookahead
    ?visual-location>
        state           free
        buffer          failure
==>
    =imaginal>
        step            press-key
        desired-color   nil
)

(p save-desired-color
    =goal>
        player          =player
    =imaginal>
        step            lookahead
        desired-x       =x
        desired-y       =y
    =visual-location>
        color           =color
      - color           =player
        screen-x        =x
        screen-y        =y
==>
    =imaginal>
        step            press-key
        desired-color   =color
)

(p set-direction-to-blocked
    =goal>
        player          =player
        obstacle        =obstacle
    =imaginal>
        step            lookahead
        desired-x       =x
        desired-y       =y
    =visual-location>
        color           =obstacle
        screen-x        =x
        screen-y        =y
==>
    =imaginal>
        step            block-dir
)

(spp save-desired-color :fixed-utility t :u 0)
(spp set-direction-to-blocked :fixed-utility t :u 100)

(p block-right
    =goal>
    =imaginal>
        step            block-dir
        key             d
==>
    =imaginal>
        right-blocked   t
        step            move
)

(p block-left
    =goal>
    =imaginal>
        step            block-dir
        key             a
==>
    =imaginal>
        left-blocked    t
        step            move
)

(p block-up
    =goal>
    =imaginal>
        step            block-dir
        key             w
==>
    =imaginal>
        up-blocked      t
        step            move
)

(p block-down
    =goal>
    =imaginal>
        step            block-dir
        key             s
==>
    =imaginal>
        down-blocked    t
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
==>
    =imaginal>
        step            after-move
        left-blocked    nil
        right-blocked   nil
        up-blocked      nil
        down-blocked    nil
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
        desired-x       =x
        desired-y       =y
        target-x        =target-x
        target-y        =target-y
    =visual-location>
        kind            oval
        color           =player
        screen-x        =x
        screen-y        =y
    ?manual>
        state           free
    
    ;; !bind! =distance-old (sqrt (+ (expt (- =x-old =target-x) 2) (expt (- =y-old =target-y) 2)))
    ;; !bind! =distance (sqrt (+ (expt (- =x =target-x) 2) (expt (- =y =target-y) 2)))
==>
    ;; !eval! (trigger-reward (- =distance-old =distance))
    =imaginal>
        can-explore     t
        step            move
        desired-color   nil
)

(p reward-position-did-not-change
    =goal>
        phase           reach-target
        player          =player
    =imaginal>
        step            after-move
    =visual-location> 
        color           =player
        kind            oval
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
        desired-color   nil
)

(p save-obstacle
    =goal>
        player          =player
        obstacle        nil
    =imaginal>
        step            eval-did-not-move
        desired-color   =color
==>
    =goal>
        obstacle        =color
    =imaginal>
        desired-color   nil    
        step            move
)

(spp reward-change-of-distance-to-target :fixed-utility t :u 100)
(spp reward-position-did-not-change :fixed-utility t :u 0)
)