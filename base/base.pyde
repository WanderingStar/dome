saveFrames = True
waitForClick = False
frameLimit = 5

class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    @staticmethod
    def fromPolar(r, theta):
        return Point(r * cos(theta), r * sin(theta))

def setup():
    if saveFrames:
        size(1920, 1080, "processing.core.PGraphicsRetina2D")
    else:
        size(960, 540, "processing.core.PGraphicsRetina2D")
    background(0)
    if waitForClick:
        noLoop()
        
def draw():
    translate(width/2, height/2) # center origin
    rotate(-PI/2) # 0 radians is up
    
    outer = max(width/2, height/2)
    ellipse(0, 0, outer * 2, outer *2)
    
    inner = min(width/2, height/2)
    ellipse(0, 0, inner * 2, inner * 2)
    p = Point.fromPolar(inner, (frameCount - 1) * 2 * PI / 5)
    line(0, 0, p.x, p.y); 

    if saveFrames:
        saveFrame()
    if frameLimit and frameCount >= frameLimit:
        noLoop()
        
def mouseClicked():
    if waitForClick:
        redraw()
    
