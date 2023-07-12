#############################################
# The "Lost Agent" environment              #
# By Linda Heimisch and Sebastian Wiese     #
#############################################

import os
import random
import actr
import sched
import time
import json

# level stuff
# S spaceship position, x empty space, O obstacle, R reward points, C collision reduce points, T target
# symbols are case sensitive

# level 1
level1 = {'parameters': [], 'layout': '''
xxxSxxxxxx
xxxxxxxxxx
xxOxxxxxxx
xxxxxxxxxx
xxxxTxxxxx
'''}


# level 2
level2 = {'parameters': ['random category colors'], 'layout': '''
xxxxSxxxx
xxxxxxxxx
xxxRxxOxx
xxxxxxCxx
xCOxxTxxx
xxxRxxxxx
xxxxxOxxx
'''}


# level 3
level3 = {'parameters': [], 'layout': '''
xxxSxxxxxxxxxxx
xxxxxxxxxxxxxxx
xxxxxxOOOxxxxxx
xxxOxxOxxxxxOxx
xxxxxxxxxxxxxxx
xxxxxxOxxxxxxxO
xOOOxxxxxxOOxxx
xxxxxxxxOOxxxxT
xxxxxOxxxxxxxxx
'''}


# level 4
level4 = {'parameters': [], 'layout': '''
xxxSxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxOOOOxxxxxRxxxxCCxxxxxxOOOx
xxxOOOxxxxRRxOOOOOOOxxxRRxxxx
xxCxxxxxxOOOOxxxCxxxxxxxxxxCx
xRxxxRxxxxxxxxxxRxxxxxOOxOOxx
xCxxxxxxxxxRxxCxxOOOxxxTxxxxx
'''}

level_simple = {'parameters': ['random category colors'], 'layout': '''
xxSxxxxxx
xxxxxxxxx
xxxxxxxxx
xxxxxxxxx
xxxxxxxxx
xxxxxxxxx
xxxxxTxxx
'''}


level_simple_obstacle = {'parameters': ['random category colors'], 'layout': '''
xxxxSxxxx
xxxxxxxxx
xxxxxxxxx
xxxxOOxxx
xxxxxxxxx
xxxxxxxxx
xxxxxTxxx
'''}

level_bottleneck = {'parameters': ['random category colors'], 'layout': '''
xxxxSxxxx
xxxxxxxxx
xxxxxxxxx
OOOxOOOOO
xxxxxxxxx
xxxxxxxxx
xxxxxTxxx
'''}

level_large = {'parameters': ['random category colors'], 'layout': '''
xOxxSxxxxxxxxxxxxxOxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxOxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxOxxxxxxxxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxxxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxOxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxOxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxOxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxOxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxOxxxxxxxxxx
xxxxxxOxxxxxxxxxxxOxxxxxxOxxxxxxxxxx
xxxxxxOxxxxxxxxxxxxxxxxxxOxxxxxxxxxx
TxxxxxOxxxxxxxxxxxxxxxxxxOxxxxxxxxxx
'''}


# change this to point to the location of your cognitive model lisp file, e.g. C:\actr\lost_game\model.lisp
modelPath = None
printLog = True

# change this to a previously defined level
levelToPlay = level4



if modelPath is not None:
    actr.load_act_r_model(modelPath)
else:
    modelPath = os.getcwd() + os.sep + 'model.lisp'
    actr.load_act_r_model(modelPath)


class Position:
    def __init__(self, x, y):
        self.x = x
        self.y = y


class Agent:
    def __init__(self, position, width, height, color):
        self.position = position
        self.color = color
        self.width = width
        self.height = height
        self.renderObject = None


class Object:
    def __init__(self, position, width, height, color, canEnter, onEnterCallback, onCollisionCallback):
        self.position = position
        self.color = color
        self.width = width
        self.height = height
        self.canEnter = canEnter
        self.onEnterCallback = onEnterCallback
        self.onCollisionCallback = onCollisionCallback
        self.renderObject = None
        self.removeFlag = False

    def onEnter(self, agent):
        if self.onEnterCallback is not None:
            return self.onEnterCallback(self, agent)

    def onCollision(self, agent):
        if self.onCollisionCallback is not None:
            return self.onCollisionCallback(self, agent)


class ExperimentSession:
    def __init__(self):
        self.agent = None
        self.objects = []
        self.viewRange = 4  # may be changed to alter viewing range            
        self.allowInput = True
        self.levelWidth = 0
        self.levelHeight = 0
        self.visibleObjects = []
        self.nowInvisibleObjects = []
        self.tileSize = 15
        self.agentColor = 'red'
        self.obstacleColor = 'blue'
        self.harmfulColor = 'black'
        self.helpfulColor = 'yellow'
        self.targetColor = 'green'
        self.needsRedraw = False
        self.log = []
        self.state = 'playing'
        self.xOffset = 25
        self.yOffset = 25
        self.score = 0
        self.experimentTime = 0
        self.numberOfMoves = 0

    def getVisibleTiles(self):
        top = max(0, self.agent.position.y - self.viewRange)
        bottom = min(self.levelHeight, self.agent.position.y + self.viewRange + 1)
        left = max(0, self.agent.position.x - self.viewRange)
        right = min(self.levelWidth, self.agent.position.x + self.viewRange + 1)
        tiles = []
        for y in range(top, bottom):
            for x in range(left, right):
                tiles.append([x, y])
        return tiles

    def update(self):
        tiles = self.getVisibleTiles()
        self.nowInvisibleObjects = []
        for o in self.visibleObjects:
            o.removeFlag = True
            self.nowInvisibleObjects.append(o)
        self.visibleObjects = []
        for o in self.objects:
            x = o.position.x
            y = o.position.y
            for t in tiles:
                if x == t[0] and y == t[1]:
                    o.removeFlag = False
                    self.visibleObjects.append(o)
                    break
        self.needsRedraw = True


# game variables
expSession = ExperimentSession()
keyMap = {'up': 'w', 'down': 's', 'left': 'a', 'right': 'd'}
expWindow = None
windowIsVisible = True
humanExperimentRunning = False
timerObject = None
scoreObject = None
humanStartTime = 0
scheduler = sched.scheduler(time.time, time.sleep)
endTime = 0
random.seed(179460)


def getTime():
    global humanExperimentRunning, humanStartTime
    if humanExperimentRunning:
        return actr.get_time(False) - humanStartTime
    else:
        return actr.get_time(True)


def scheduleEvent(delay, eventName, eventFunction, params=None):
    if params is None:
        params = []
    global humanExperimentRunning
    if humanExperimentRunning:
        scheduler.enter(delay=delay/1000, action=eventFunction, priority=1, argument=params)
    else:
        actr.schedule_event_relative(delay, eventName, time_in_ms=True, params=params)


def moveAgent(agent, session, targetX, targetY):
    for o in session.visibleObjects:
        if o.position.x == targetX and o.position.y == targetY:
            # object at target position found
            if o.canEnter:
                # object can be entered
                session.log.append({'type': 'movement', 'from': [agent.position.x, agent.position.y],
                                    'to': [targetX, targetY], 'time': getTime()})
                agent.position.x = targetX
                agent.position.y = targetY
                o.onEnter(agent)
                session.update()
                return True
            else:
                # movement target blocked
                o.onCollision(agent)
                return False
    # no object at target position
    session.log.append({'type': 'movement', 'from': [agent.position.x, agent.position.y], 'to': [targetX, targetY], 'time': getTime()})
    agent.position.x = targetX
    agent.position.y = targetY
    session.numberOfMoves = session.numberOfMoves + 1
    session.update()
    return True


def moveUp(agent, session):
    session.log.append({'type': 'attempt move up', 'time': getTime()})
    if agent.position.y > 0:
        # move up is possible
        targetX = agent.position.x
        targetY = agent.position.y - 1
        return moveAgent(agent, session, targetX, targetY)


def moveDown(agent, session):
    session.log.append({'type': 'attempt move down', 'time': getTime()})
    if agent.position.y < session.levelHeight - 1:
        # move up is possible
        targetX = agent.position.x
        targetY = agent.position.y + 1
        return moveAgent(agent, session, targetX, targetY)


def moveLeft(agent, session):
    session.log.append({'type': 'attempt move left', 'time': getTime()})
    if agent.position.x > 0:
        # move up is possible
        targetX = agent.position.x - 1
        targetY = agent.position.y
        return moveAgent(agent, session, targetX, targetY)


def moveRight(agent, session):
    session.log.append({'type': 'attempt move right', 'time': getTime()})
    if agent.position.x < session.levelWidth - 1:
        # move up is possible
        targetX = agent.position.x + 1
        targetY = agent.position.y
        return moveAgent(agent, session, targetX, targetY)


def keyHandler(modelName, keypress):
    global expSession, keyMap, expWindow

    if keypress == 'Escape':
        expSession.state = 'finished'
        expSession.log.append({'type': 'escape pressed', 'score': expSession.score, 'time': getTime(),
                               'number of moves': expSession.numberOfMoves})

    if expSession.allowInput:
        if keypress == keyMap['up']:
            moveUp(expSession.agent, expSession)
        elif keypress == keyMap['down']:
            moveDown(expSession.agent, expSession)
        elif keypress == keyMap['left']:
            moveLeft(expSession.agent, expSession)
        elif keypress == keyMap['right']:
            moveRight(expSession.agent, expSession)
    if expSession.needsRedraw:
        expSession.needsRedraw = False
        redraw(expWindow)


def drawAgent(window):
    global expSession

    yOffset = expSession.xOffset
    xOffset = expSession.yOffset
    agent = expSession.agent
    if agent.renderObject is None:
        agent.renderObject = actr.add_button_to_exp_window(window,
                                                           x=agent.position.x * expSession.tileSize + xOffset,
                                                           y=agent.position.y * expSession.tileSize + yOffset,
                                                           height=agent.height, width=agent.width,
                                                           color=agent.color)
    else:
        # actr bridge currently does not support modify functions.
        actr.call_command("modify-button-for-exp-window", agent.renderObject,
                          [["x", agent.position.x * expSession.tileSize + xOffset],
                           ["y", agent.position.y * expSession.tileSize + yOffset],
                           ])


def redraw(window):
    global expSession

    yOffset = expSession.xOffset
    xOffset = expSession.yOffset

    for o in expSession.nowInvisibleObjects:
        if o.removeFlag:
            o.removeFlag = False
            actr.remove_items_from_exp_window(window, o.renderObject)
            o.renderObject = None

    for o in expSession.visibleObjects:
        if o.renderObject is None:
            o.renderObject = actr.add_button_to_exp_window(window,
                                                           x=o.position.x * expSession.tileSize + xOffset,
                                                           y=o.position.y * expSession.tileSize + yOffset,
                                                           height=o.height, width=o.width,
                                                           color=o.color)

    drawAgent(window)


def redrawTime():
    global expSession, humanExperimentRunning, timerObject, humanStartTime, endTime
    # random timer update interval
    if expSession.state != 'finished':
        scheduleEvent(random.randint(30, 120), 'lost-timer-update', redrawTime)
    expSession.experimentTime = getTime()

    # if expSession.experimentTime >= endTime:
    #     expSession.state = 'finished'

    # actr bridge currently does not support modify functions.
    timerText = str(expSession.experimentTime)
    actr.call_command("modify-text-for-exp-window", timerObject,
                      [["text", timerText]])


def redrawScore():
    global expSession, scoreObject
    actr.call_command("modify-text-for-exp-window", scoreObject,
                      [["text", str(int(expSession.score))]])


def positionToPixels(position):
    x = position.x * expSession.tileSize + expSession.xOffset
    y = position.y * expSession.tileSize + expSession.yOffset
    return [x, y]


def firstDraw(window):
    global expSession, timerObject, scoreObject
    yOffset = expSession.xOffset
    xOffset = expSession.yOffset
    # border
    actr.add_line_to_exp_window(window,
                                (xOffset, yOffset),
                                (xOffset + expSession.levelWidth * expSession.tileSize,
                                 yOffset),
                                'yellow')
    actr.add_line_to_exp_window(window,
                                (xOffset + expSession.levelWidth * expSession.tileSize, yOffset),
                                (xOffset + expSession.levelWidth * expSession.tileSize,
                                 yOffset + expSession.levelHeight * expSession.tileSize),
                                'yellow')
    actr.add_line_to_exp_window(window,
                                (xOffset + expSession.levelWidth * expSession.tileSize,
                                 yOffset + expSession.levelHeight * expSession.tileSize),
                                (xOffset,
                                 yOffset + expSession.levelHeight * expSession.tileSize),
                                'yellow')
    actr.add_line_to_exp_window(window,
                                (xOffset, yOffset + expSession.levelHeight * expSession.tileSize),
                                (xOffset, yOffset),
                                'yellow')

    # high score
    actr.add_text_to_exp_window(window, text='Score: ', x=5, y=2, color='black')

    scoreObject = actr.add_text_to_exp_window(window, text='0', x=50, y=2, color='black')

    # timer
    actr.add_text_to_exp_window(window, text='Time: ', x=140, y=2, color='black')

    timerObject = actr.add_text_to_exp_window(window, text='0', x=180, y=2, color='black')


def onEnterTarget(enteredObject, agent):
    global expSession
    redrawTime()
    redrawScore()
    expSession.score += 1000
    expSession.state = 'finished'
    expSession.allowInput = False
    expSession.log.append({'type': 'score changed', 'amount': 1000, 'time': getTime()})
    expSession.log.append({'type': 'success', 'score': expSession.score, 'time': getTime(), 'number of moves': expSession.numberOfMoves})


def rewardPoints(enteredObject, agent):
    global expSession
    expSession.score += 100
    expSession.log.append({'type': 'score changed', 'amount': 100, 'time': getTime()})
    position = positionToPixels(enteredObject.position)
    addScoreFeedback(position[0], position[1]-expSession.tileSize,
                     '+100!', 'red', 500)
    expSession.objects.remove(enteredObject)
    redrawScore()


def reducePoints(enteredObject, agent):
    global expSession
    expSession.score -= 20
    expSession.log.append({'type': 'score changed', 'amount': -20, 'time': getTime()})
    position = positionToPixels(enteredObject.position)
    addScoreFeedback(position[0], position[1]-expSession.tileSize,
                     '-100!', 'red', 500)
    expSession.objects.remove(enteredObject)
    redrawScore()


def reducePointsCollision(enteredObject, agent):
    global expSession
    expSession.score -= 20
    expSession.log.append({'type': 'score changed', 'amount': -20, 'time': getTime()})
    position = positionToPixels(enteredObject.position)
    addScoreFeedback(position[0], position[1]-expSession.tileSize,
                     '-100!', 'red', 500)
    redrawScore()


def addScoreFeedback(x, y, text, color, duration):
    global expWindow
    feedbackObject = actr.add_text_to_exp_window(expWindow, x=x, y=y, color=color, text=text)
    scheduleEvent(duration, 'lost-update-score-feedback', updateScoreFeedback, [feedbackObject])


def updateScoreFeedback(feedbackObject):
    global expWindow
    actr.remove_items_from_exp_window(expWindow, feedbackObject)


def importModel(pathToModel):
    global modelPath
    if pathToModel is not None:
        modelPath = pathToModel
    if modelPath is None:
        modelPath = os.getcwd() + os.sep + 'model.lisp'
    actr.load_act_r_model(modelPath)


def parseLine(line, y, expSession):
    # S spaceship position, x empty space, O obstacle, R reward points, C collision reduce points, T target
    x = 0
    tileSize = expSession.tileSize
    for c in line:
        if c == 'S':
            expSession.agent = Agent(Position(x, y), tileSize, tileSize, expSession.agentColor)
        if c == 'O':
            expSession.objects.append(Object(Position(x, y), tileSize, tileSize, expSession.obstacleColor, False, None, None))
        if c == 'R':
            expSession.objects.append(Object(Position(x, y), tileSize, tileSize, expSession.helpfulColor, True, rewardPoints, None))
        if c == 'C':
            expSession.objects.append(Object(Position(x, y), tileSize, tileSize, expSession.harmfulColor, True, reducePoints, None)) # Now the agent walks through reduce point fields
        if c == 'T':
            expSession.objects.append(Object(Position(x, y), tileSize, tileSize, expSession.targetColor, True, onEnterTarget, None))
        x = x + 1

    return x


def parseParameter(parameter, expSession):
    actrColors = ['black', 'yellow', 'red', 'blue']  # todo add more actr colors..
    if parameter == 'random category colors':
        random.shuffle(actrColors)
        expSession.agentColor = actrColors[0]
        expSession.obstacleColor = actrColors[1]
        expSession.helpfulColor = actrColors[2]
        expSession.harmfulColor = actrColors[3]
        expSession.targetColor = 'green'


def parseLevel(level):
    global expSession
    expSession = ExperimentSession()
    expSession.tileSize = 25
    y = 0
    width = 0
    parameters = level['parameters']
    if parameters is not None:
        for p in parameters:
            parseParameter(p, expSession)
    levelData = level['layout']
    for line in levelData.splitlines():
        if line:    # skip empty lines
            width = parseLine(line, y, expSession)
            y = y + 1
    expSession.levelWidth = width
    expSession.levelHeight = y


def gameOverTest(currentTime):
    global expSession, endTime
    if expSession.state == 'finished':
        return True
    if currentTime >= endTime:
        expSession.state = 'finished'
        expSession.log.append({'type': 'out of time', 'score': expSession.score, 'time': currentTime,
                               'number of moves': expSession.numberOfMoves})
        return True
    return False


def startExperiment(who='model', real_time=False, time=120, level=levelToPlay, save_log=False, log_name='log'):
    global expSession, expWindow, windowIsVisible, humanExperimentRunning, modelPath, scheduler, humanStartTime, endTime

    parseLevel(level)
    endTime = time * 1000 # convert to ms

    if who == "human" or who == "Human":  # check if experiment is set to human play
        humanExperimentRunning = True
        expSession.log.append({'type': 'start',
                               'x': expSession.agent.position.x, 'y': expSession.agent.position.y,
                               'participant': 'human', 'time': getTime()})

    if not humanExperimentRunning:
        expSession.log.append({'type': 'start',
                               'x': expSession.agent.position.x, 'y': expSession.agent.position.y,
                               'participant': modelPath, 'time': getTime()})

    actr.reset()

    actr.add_command("lost-update-score-feedback", updateScoreFeedback, "update Lost experiment score feedback")
    actr.add_command("lost-timer-update", redrawTime, "update Lost experiment timer")
    actr.add_command("lost-key-event-handler", keyHandler, "Key monitor for Lost task")
    actr.add_command("lost-game-over-test", gameOverTest, "Game state monitor for Lost task")
    actr.monitor_command("output-key", "lost-key-event-handler")
    expWindow = actr.open_exp_window('Lost Game Experiment - {}'.format(log_name), visible=windowIsVisible,
                                     width=expSession.levelWidth * expSession.tileSize + expSession.xOffset * 2,
                                     height=expSession.levelHeight * expSession.tileSize + expSession.yOffset * 2)
    expSession.update()
    firstDraw(expWindow)
    redraw(expWindow)
    expSession.needsRedraw = False


    scheduleEvent(100, 'lost-timer-update', redrawTime)

    if who == "human":
        humanStartTime = actr.get_time(False)
        scheduler.run()
        while humanExperimentRunning:
            actr.process_events()
            if expSession.state == 'finished':
                break
    else:
        actr.install_device(expWindow)
        actr.run_until_condition("lost-game-over-test", real_time)

    actr.clear_exp_window(expWindow)
    actr.call_command("close-exp-window", expWindow)
    actr.remove_command_monitor("output-key", "lost-key-event-handler")
    actr.remove_command("lost-key-event-handler")
    actr.remove_command("lost-timer-update")
    actr.remove_command("lost-update-score-feedback")
    actr.remove_command("lost-game-over-test")

    if save_log:
        with open('{}.txt'.format(log_name), 'w') as outfile:
            jsonData = json.dumps(expSession.log, indent=4)
            outfile.write(jsonData)
        return True

    if printLog:
        return expSession.log
    else:
        return 'game over'


def run(who='model'):
    return startExperiment(who)
