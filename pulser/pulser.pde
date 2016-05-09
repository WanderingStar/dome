import themidibus.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Vector;
import java.util.regex.*;
import java.util.*;

boolean present = false;

final float DEFAULT_DOME_COVERAGE = 0.9;


HashMap<String, Float> config = new HashMap<String, Float>();
final String SECTIONS = "sections";
final String REPEAT = "repeat";

// dome distortion
PGraphics frame, targ;
DomeDistort dome;
NanoKontrol2 control;

int last_control_refresh = 0;
int start = 0; // millis
int lastCall = 0;

// mode flags
boolean line_mode = false; // just draws a vertical line, for setup
boolean grid_mode = false; // just draws polargrid.png, for setup
boolean img_mode  = false; // dump raw image to screen, no distortion

// dome mapping params
float dome_coverage = DEFAULT_DOME_COVERAGE; // radial extent of dome covered by texture


void resetDefaults() {
  dome_coverage = DEFAULT_DOME_COVERAGE;
  config.put(REPEAT, 5000.0); // millis
}

void settings() {
  if (present) {
    fullScreen(P3D);
  } else {
    size(1280, 720, P3D);
  }
}

void setup()
{
  frameRate(60);

  // set up source buffer for the actual frame data
  frame = createGraphics(2048, 2048);
  frame.ellipseMode(CENTER);
  frame.shapeMode(CENTER);

  // set up target buffer to render into
  targ = createGraphics(width, height, P3D);

  // create and configure the distortion object
  dome = new DomeDistort(targ, frame);
  dome.setTexExtent(dome_coverage); // set to < 1.0 to shrink towards center of dome

  //println(dataPath(""));

  colorMode(HSB, 127, 127, 127);

  // configure controller
  MidiBus.list();
  control = new NanoKontrol2(config);

  resetDefaults();
  start = millis();
}

// keyboard callback handler
void keyPressed()
{
  if (key == '\\')
  {
    targ.save("screenshot.png");
    return;
  }
  if (key == 'l') {
    println("line");
    line_mode = !line_mode;
    return;
  }
  if (key == 'i') {
    println("img");
    img_mode = !img_mode;
    return;
  }
  if (key == 'g') {
    //selectAnimation(dataPath("000polargrid.gif"));
    return;
  }
  if (key == 'r') {
    resetDefaults();
  }
}

class Pulse implements Comparable {
  int time = 0;
  PShape s = frame.createShape(RECT, 0, 0, 100, 100);
  color c = color(255, 255, 255);
  float theta = 0.0; // 0..TWO_PI
  float dTheta = 0.0;
  float radius = 0.0; // 1.0 = full frame
  float dRadius = 1.0/300.0;
  float width = 10;

  void drawPulse(PGraphics g) {
    g.pushMatrix();
    g.rotate(theta);
    float size = g.width * radius;
    s.setStroke(1);
    g.fill(0, 0, 127, 127);
    g.ellipse(0, 0, size, size);
    s.setFill(0, 0);
    s.setStroke(c);
    s.setStrokeCap(PROJECT);
    //s.setStrokeJoin(MITER);
    s.setStrokeWeight(width);
    g.shapeMode(CORNERS);
    g.shape(s, 0,0, size,size);
    theta += dTheta % TWO_PI;
    radius += dRadius;
    g.popMatrix();
  }

  int compareTo(Object other) {
    return 0;
  }

  int compareTo(Pulse other) {
    return time - other.time;
  }
}

class Ring extends Pulse {
  public Ring() {
    PShape ring = frame.createShape(ELLIPSE, 0, 0, 100, 100);
    println(ring.width + ", " + ring.height);
    ring.width = 100;
    ring.height = 100;
    println(ring.width + ", " + ring.height);
    s = ring;
  }
}

class Polygon extends Pulse {
  public Polygon(int sides) {
    PShape polygon = frame.createShape();
    float theta = TWO_PI / sides;
    polygon.beginShape();
    polygon.noFill();
    for (int i=0; i<sides; i++) {
      polygon.vertex(100 * cos(theta * i), 100 * sin(theta * i));
    }
    polygon.endShape(CLOSE);
    println(polygon.width + ", " + polygon.height);
    polygon.width = 100;
    polygon.height = 100;
    println(polygon.width + ", " + polygon.height);

    s = polygon;
  }
}

ArrayList<Pulse> pulses = new ArrayList<Pulse>();

void drawFrame(PGraphics g, int progress, int lastCall) {
  g.beginDraw();
  g.background(0);
  g.pushMatrix();
  g.translate(g.width/2, g.height/2);
  synchronized (pulses) {
    for (Pulse p : pulses) {
      // if this pulse should appear at this point in the cycle, set it up to appear
      if (p.time > lastCall && p.time <= progress) {
        p.radius = 0.0;
      }
      p.drawPulse(g);
    }
  }
  g.popMatrix();
  g.endDraw();
}

void draw()
{
  int progress = millis() - start;
  // reset every repeat millis
  if (progress > config.get(REPEAT)) {
    start = millis();
    progress = 0;
    lastCall = 0;
    control.kontrol.sendControllerChange(0, control.CYCLE, 127);
  } else {
    control.kontrol.sendControllerChange(0, control.CYCLE, 0);
  }

  // draw into source texture
  drawFrame(frame, progress, lastCall);
  lastCall = progress;

  // update texture params
  dome.setTexExtent(dome_coverage);

  // ready to draw
  background(0);

  if (line_mode) {
    // override image if we're in line mode, just draw a line
    stroke(255);
    line(width/2, 0, width/2, height);
  } else if (img_mode) {
    // just blit source to target in image mode
    imageMode(CENTER);
    image(frame, width/2, height/2, height, height);
  } else {
    // do actual distortion in regular mode

    // distort into target image
    dome.update();

    // draw distorted image to screen
    imageMode(CORNER);
    image(targ, 0, 0);
  }
}