import themidibus.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Vector;
import java.util.regex.*;
import java.util.*;

boolean present = false;
int refresh = 60;

final float DEFAULT_CUR_FRAMERATE = 15.0;
final float DEFAULT_DOME_ANGVEL = 0.0;
final float DEFAULT_HUE_SHIFT_DEG = 0.0;
final float DEFAULT_SAT_SCALE = 1.0;
final float DEFAULT_VAL_SCALE = 1.0;
final float DEFAULT_INVERT = 0.0;
final float DEFAULT_DOME_COVERAGE = 0.9;
final float DEFAULT_ROTATION = 0.0;
final int DEFAULT_REFRESH = 60;

// dome distortion
PGraphics src, targ;
DomeDistort dome;
ArrayList<Controller> controls = new ArrayList<Controller>();

float cur_framerate = DEFAULT_CUR_FRAMERATE; // can be fractional or negative
int last_control_refresh = 0;

// mode flags
boolean line_mode = false; // just draws a vertical line, for setup
boolean grid_mode = false; // just draws polargrid.png, for setup
boolean img_mode  = false; // dump raw image to screen, no distortion

// color params
float hue_shift_deg = DEFAULT_HUE_SHIFT_DEG;
float sat_scale = DEFAULT_SAT_SCALE;
float val_scale = DEFAULT_VAL_SCALE;
float invert = DEFAULT_INVERT;

// dome mapping params
float dome_rotation = 0.0; // current rotation of dome (radians)
float dome_angvel = DEFAULT_DOME_ANGVEL; // rotation speed of dome, in rad / s
float dome_coverage = DEFAULT_DOME_COVERAGE; // radial extent of dome covered by texture

void resetDefaults() {
  cur_framerate = DEFAULT_CUR_FRAMERATE;
  dome_angvel = DEFAULT_DOME_ANGVEL;
  hue_shift_deg = DEFAULT_HUE_SHIFT_DEG;
  sat_scale = DEFAULT_SAT_SCALE;
  val_scale = DEFAULT_VAL_SCALE;
  invert = DEFAULT_INVERT;
  dome_coverage = DEFAULT_DOME_COVERAGE;
  refresh = DEFAULT_REFRESH;
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
  // Framerate set to 61, since apparently Processing's timing is sometimes
  // off and we get judder when set to 60.
  // Animation playback speed is controlled by cur_framerate.
  frameRate(61);

  // set up source buffer for the actual frame data
  src = createGraphics(1024, 1024, P3D);

  // set up target buffer to render into
  targ = createGraphics(width, height, P3D);

  // create and configure the distortion object
  dome = new DomeDistort(targ, src);
  dome.setTexExtent(dome_coverage); // set to < 1.0 to shrink towards center of dome
  dome.setTexRotation(dome_rotation); // set to desired rotation angle in radians

  //println(dataPath(""));

  // configure controller
  MidiBus.list();
  String[] inputs = MidiBus.availableInputs();
  Arrays.sort(inputs);
  //control = new NanoKontrol1();
  if (Arrays.binarySearch(inputs, "SLIDER/KNOB") > 0) {
    controls.add(new NanoKontrol2());
  }
  //control = new NanoKontrol2();
  //control = new XTouchMidi();
  if (Arrays.binarySearch(inputs, "X-TOUCH MINI") > 0) {
    controls.add(new XTouchMidi());
  }

  // load pre-created list of animations
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
    line_mode = !line_mode;
    return;
  }
  if (key == 'i') {
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

// stretches an image over the entire target canvas
void drawFullscreenQuad(PGraphics t, PImage i)
{
  float img_scale = max((float)t.width / (float)i.width, (float)t.height / (float)i.height);
  t.imageMode(CENTER);
  t.image(i, t.width/2, t.height/2, i.width * img_scale, i.height * img_scale);
}

void drawFrame(PGraphics g) {
  g.beginDraw();
  g.background(0);

  g.endDraw();
}

void draw()
{
  // draw into source texture
  drawFrame(src);

  // animate rotating dome
  dome_rotation += dome_angvel / 60.0;
  if (dome_rotation < 0.0)
    dome_rotation += 2.0*PI;
  else if (dome_rotation > 2.0*PI)
    dome_rotation -= 2.0*PI;

  // update texture params
  dome.setTexRotation(dome_rotation);
  dome.setTexExtent(dome_coverage);

  // update color transform
  dome.setColorTransformHSVShiftInvert(hue_shift_deg, sat_scale, val_scale, invert);

  // ready to draw
  background(0);

  if (line_mode)
  {
    // override image if we're in line mode, just draw a line
    stroke(255);
    line(width/2, 0, width/2, height);
  } else if (img_mode)
  {
    // just blit source to target in image mode
    imageMode(CENTER);
    image(src, width/2, height/2, height, height);
  } else
  {
    // do actual distortion in regular mode

    // distort into target image
    dome.update();

    // draw distorted image to screen
    imageMode(CORNER);
    image(targ, 0, 0);
  }

  // call the controller's refresh callback every 0.1s
  if (millis() - last_control_refresh > 100)
  {
    for (Controller control : controls) {
      control.refresh();
    }
    last_control_refresh = millis();
  }
}