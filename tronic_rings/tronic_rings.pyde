saveFrames = True
waitForClick = False
frameLimit = 0 #900

count = 12  # random(12)
spacing = 5 # 5 * int(random(4) + 1)
startingHue = 60 # random(360)
newByRow = False # this distributes seeds more evenly

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

def right(p):
    x, y = p
    nx = (x + 1) % len(grid[y])
    return (nx, y)

def down(p):
    x, y = p
    nx = ceil((float(x) / len(grid[y])) * len(grid[y+1]))
    #print "%d/%d %f => %d/%d %f" % (x, len(grid[y]), float(x)/len(grid[y]), nx, len(grid[y+1]), float(nx)/len(grid[y+1]))
    return (nx, y+1)

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
    if newByRow and byRow:
        row = byRow[int(random(len(byRow)))]
        return row[int(random(len(row)))]
    if gaps:
        return gaps[int(random(len(gaps)/1000))]
    print "Done."

def step_spark(spark, grid):
    x, y = spark
    if y < yRes - 1 and not cell(down(spark)):
        # 10% chance move down
        if random(100) < 10:
            return down(spark)
    if cell(right(spark)):
        if y == yRes - 1 or cell(down(spark)):
            # boxed in
            return None
        if random(100) < 25:
            # via
            return None
        # dodge down
        return down(spark)
    return right(spark)



def radius(y):
    return y * spacing * 2

def theta(x, y):
    return x * TAU / len(grid[y])

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
        if t2 == 0:
            t2 = TAU
        fill(0, 360, 360, 0)
        arc(0,0, r,r, t1,t2)
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
        size(600, 600)
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
    c = color(h, 360, 360)
    p = (0, 0)
    put(p, 1)
    sparks.append([p, c])
    stroke(c)
    via(p)
    
    while len(sparks) < count:
        p = new_spark(grid)
        h = (h + float(360)/count) % 360
        c = color(h, 360, 360)
        put(p, len(sparks) + 1)
        sparks.append([p, c])
        stroke(c)
        via(p)

    
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    
    for i, (spark, c) in enumerate(sparks):
        stroke(c)
        next = step_spark(spark, grid)
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
    
