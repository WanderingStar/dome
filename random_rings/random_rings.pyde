saveFrames = True
waitForClick = False
frameLimit = 0 #900
n = 20
rings = []
rate = 10
h = 0

class Ring:
    def __init__(self, centerRadius, thickness, pattern=[1], c=color(255,255,255,128), rotation=0, zoom=0):
        self.cR = centerRadius
        self.t = thickness
        self.pat = pattern
        self.c = c
        self.r = rotation
        self.z = zoom
        self.angle = 0
    def display(self):
        sweep = 2 * PI / len(self.pat)
        s = self.angle
        e = s + sweep
        with pushStyle():
            stroke(self.c)
            strokeWeight(self.t)
            strokeCap(SQUARE)
            fill(0,0,0,0)
            for p in self.pat:
                if p:
                    arc(0,0, self.cR,self.cR, s,e)
                s = e
                e += sweep
    def step(self):
        self.angle += self.r
        self.cR += self.z

def setup():
    if saveFrames:
        size(1024, 1024, P3D)
    else:
        frameRate(30)
        size(1024, 1024, P3D)
    background(0)
    if waitForClick:
        noLoop()
    
    colorMode(HSB, 360)
    
    maxR = dist(0,0, width,height)
    r = maxR / n
    radius = r / 2
    while len(rings) < n:
        h = (h + random(30)) % 360
        c = color(h, 360, 360)
        rings.append(Ring(maxR - radius, .40 * r, randomPattern(), c, random(PI/24), r / rate))
        radius += r
    
def randomPattern():
    #pattern =  [1] + [int(random(2)) for i in range(random(24)+1)]
    pattern = [1, 0] * int(random(10) + 1) #+ [0] * int(random(5))
    print(pattern)
    return pattern
        
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    background(0)
    
    for ring in rings:
        ring.display()
        ring.step()
    
    if frameCount % rate == 0:
        rings.pop(0)
        maxR = dist(0,0, width,height)
        r = maxR / n
        radius = r / 2
        h = (h + random(30)) % 360
        c = color(h, 360, 360)
        rings.append(Ring(radius, .40 * r, randomPattern(), c, random(PI/15) - PI/30, r / rate))
        radius += r

    if saveFrames:
        saveFrame("frames/####.png")
        print("Frame {}/{} @ {} fps".format(frameCount, frameLimit, frameRate))
    if frameLimit and frameCount >= frameLimit:
        noLoop()
        
def mouseClicked():
    if waitForClick:
        redraw()
    
