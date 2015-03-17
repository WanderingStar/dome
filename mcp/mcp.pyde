saveFrames = False
waitForClick = False
frameLimit = 0 #900

count = int(random(12) + 1)
spacing = 5 * int(random(4) + 1)
startingHue = random(360)
inOut = random(3)
inwards = inOut < 1
outwards = inOut > 2
newByRow = True # this distributes seeds more evenly
if random(10) < 1:
    upwardPercentage = 5 * int(random(21))
    downwardPercentage = min(5 * int(random(21)), 100-upwardPercentage)
else:
    upwardPercentage = 5 * int(random(5))
    downwardPercentage = 5 * int(random(5))
crashPercentage = 10 * int(random(11))
alphaBeam = 0 # / 360
luminanceBeam = 360 # / 360
rightPercentage = 10 * int(random(11))

print "count\tsize\thue\tdir\tup%\tdn%\tcrash%\tright%"
print "%d\t%d\t%d\t%s\t%d\t%d\t%d\t%d" % (
    count, spacing, startingHue, (inwards and "in") or (outwards and "out") or "rnd", 
    upwardPercentage, downwardPercentage, crashPercentage, rightPercentage)

# count 1  size 5  hue 211  out  up% 20  dn% 15  crash% 30  right% 90
# count 12  size 5  hue 235  in  up% 0  dn% 15  crash% 20  right% 80
# count 10  size 5  hue 66  out  up% 10  dn% 15  crash% 0  right% 0

grid = None
yRes = 60
sparks = []

def ticks(radius):
    circ = PI * radius
    ticks = floor(circ / spacing * 2)
    return max(ticks, count)

def cell(p):
    x, y = p
    return grid[y][x]

def put(p, value):
    x, y = p
    grid[y][x] = value

def left(p):
    x, y = p
    nx = (x - 1) % len(grid[y])
    return (nx, y)

def right(p):
    x, y = p
    nx = (x + 1) % len(grid[y])
    return (nx, y)

def down(p, direction):
    x, y = p
    if direction == right:
        f = ceil
    else:
        f = floor
    nx = f((float(x) / len(grid[y])) * len(grid[y+1]))
    #print "%d/%d %f => %d/%d %f" % (x, len(grid[y]), float(x)/len(grid[y]), nx, len(grid[y+1]), float(nx)/len(grid[y+1]))
    return (nx, y+1)

def up(p, direction):
    x, y = p
    if direction == right:
        f = ceil
    else:
        f = floor
    nx = min(len(grid[y-1]) - 1, f((float(x) / len(grid[y]) * len(grid[y-1]))))
    return (nx, y-1)

def new_spark(grid):
    gaps = []
    byRow = []
    for y, row in enumerate(grid):
        rowGaps = []
        for x, item in enumerate(row):
            if not cell((x, y)):
                gaps.append((x, y))
                rowGaps.append((x, y))
        if rowGaps:
            byRow.append(rowGaps)
    if not gaps:
        # print "Done."
        return None
    if newByRow:
        if inwards:
            row = byRow[-1]
        elif outwards:
            row = byRow[0]
        else:
            row = byRow[int(random(len(byRow)))]
        return row[int(random(len(row)))]
    else:
        if inwards:
            return gaps[-1]
        elif outwards:
            return gaps[0]
        else:
            return gaps[int(random(sqrt(len(gaps))))]

def step_spark(spark, grid, direction):
    x, y = spark
    canUp = y > 0 and not cell(up(spark, direction))
    canDown = y < yRes - 1 and not cell(down(spark, direction))
    canForward = not cell(direction(spark))
    # print "F %d U %d D %d" % (canForward, canUp, canDown)
    if not canForward:
        if random(100) < crashPercentage or (not canUp and not canDown):
            # print "crash"
            return None
        if canUp:
            if canDown:
                if random(100) < 50:
                    # print "blocked up (could down)"
                    return up(spark, direction)
                # print "blocked down (could up)"
                return down(spark, direction)
            # print "blocked up forced"
            return up(spark, direction)
        # print "blocked down forced"
        return down(spark, direction)
    chance = random(100)
    if canUp and chance < upwardPercentage:
        # print "chance up"
        return up(spark, direction)
    if canDown and chance > 100 - downwardPercentage:
        # print "chance down"
        return down(spark, direction)
    # print "forward " + direction.__name__
    return direction(spark)


def radius(y):
    return y * spacing * 2

def theta(x, y):
    return (x * TAU / len(grid[y])) % TAU

def locate(p):
    x, y = p
    r = radius(y)
    t = theta(x, y)
    return (r * cos(t), r * sin(t))

def trace(p1, p2):
    if p1[1] == p2[1]:
        r = radius(p1[1]) * 2
        t1 = theta(p1[0], p1[1])
        t2 = theta(p2[0], p1[1])
        if t1 == 0:
            if t2 > PI:
                arc(0,0, r,r, t2,TAU)
            else:
                arc(0,0, r,r, t1,t2)
        elif t2 == 0:
            if t1 > PI:
                arc(0,0, r,r, t1,TAU)
            else:
                arc(0,0, r,r, t2,t1)
        else:
            if t2 > t1:
                arc(0,0, r,r, t1,t2)
            else:
                arc(0,0, r,r, t2,t1)
    else:
        (x1, y1) = locate(p1)
        (x2, y2) = locate(p2)
        line(x1, y1, x2, y2)
    
def via(p):
    (x, y) = locate(p)
    r = spacing/2
    fill(0)
    ellipse(x, y, r, r)
    

def setup():
    if saveFrames:
        size(1024, 1024)
    else:
        frameRate(30)
        size(800, 800)
    background(0)
    if waitForClick:
        noLoop()
    
    colorMode(HSB, 360)
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    strokeWeight(spacing/3)
    strokeCap(ROUND)
    fill(0)
    
    yRes = height / spacing / 4
    grid = []
    for y in range(yRes):
        t = ticks(y * spacing)
        grid.append([0 for x in range(t)])
    
    h = startingHue
    for i in range(count):
        c = color((startingHue + i * float(360)/count) % 360, 360, 360)
        if inwards:
            p = (i * (len(grid[-1]) - 1)/ count, yRes - 1)
        else:
            p = (0, 0)
        if random(100) < rightPercentage:
            d = right
        else:
            d = left
        put(p, i+1)
        sparks.append([p, c, d])
        stroke(c)
        via(p)

    
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    
    for i, (spark, c, d) in enumerate(sparks):
        stroke(c)
        fill(hue(c), 360, luminanceBeam, alphaBeam)
        next = step_spark(spark, grid, d)
        #print "%d %s -> %s" % (i, spark, next)
        if next:
            trace(spark, next)
        else:
            via(spark)
            next = new_spark(grid)
            if next:
                via(next)
        if next and next[1] >= yRes:
            next = new_spark(grid)
            if next:
                via(next)
        if not next:
            noLoop()
        else:
            (x, y) = next
            put(next, i+1)
            #print "grid[%d]: %s" % (y, grid[y])
        sparks[i][0] = next

    if saveFrames:
        saveFrame("frames/####.png")
        print("Frame {}/{} @ {} fps".format(frameCount, frameLimit, frameRate))
    if frameLimit and frameCount >= frameLimit:
        noLoop()

        
def mouseClicked():
    if waitForClick:
        redraw()
    
