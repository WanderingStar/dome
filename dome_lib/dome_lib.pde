import themidibus.*;
import gifAnimation.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Vector;
import java.util.regex.*;
import java.util.*;

int refresh = 60;
boolean shuffle = true;
int initial = 0;
boolean present = false;

String[] KEYWORDS = { 
  "chill", "energetic", "monochrome", "colorful", "whoah", 
  "breathing", "falling", "organic", "blinky", "creepy"
};

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

// animation & playback
Pattern idGifPattern = Pattern.compile("post_(\\d{3,}).*\\.gif$");
ArrayList<String> playlist = new ArrayList<String>();
HashMap<String, ArrayList<PImage>> loaded = new HashMap<String, ArrayList<PImage>>();
PImage[] anim_frames;
int cur_anim = 0;
int cur_frame = 0;
float cur_floatframe = 0.0; // higher-resolution frame number, truncated to get cur_frame
float cur_framerate = DEFAULT_CUR_FRAMERATE; // can be fractional or negative
int reps = 0;
long started;
int last_control_refresh = 0;

// mode flags
boolean line_mode = false; // just draws a vertical line, for setup
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

boolean sketchFullScreen() {
  return present;
}

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

void setup()
{
  if (present) {
    size(displayWidth, displayHeight, P3D);
  } else {
    //size(1024, 1024, P3D);
    //size(1920, 1080, P3D);
    size(1280, 720, P3D);
    //size(854, 480, P3D);
    //size(960, 540, P3D);
  }

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

  // make list of animations
  addDirectory(dataPath("content"));
  cur_anim = initial;
  nextAnim(0);

  new File(dataPath("Trash")).mkdir();
  new File(dataPath("Fix")).mkdir();
}

public void addDirectory(String path) {
  println("adding content from " + path);
  File dir = new File(path);
  int i = 0;
  for (String filename : dir.list ()) {
    String filepath = path + "/" + filename;
    Matcher m = idGifPattern.matcher(filename);
    if (m.find()) {
      playlist.add(filepath);
      i++;
    } else if (new File(filepath).isDirectory()) {
      addDirectory(filepath);
    }
  }
  println("Found " + i + " images in " + path);
}

void loadAnimations() {
  // this is called in a background thread to load an unloaded animations
  synchronized(loaded) {
    for (String filename : loaded.keySet ()) {
      if (loaded.get(filename) == null) {
        try {
          // println("Loading " + filename + "...");
          PImage[] frames = Gif.getPImages(this, filename);
          loaded.put(filename, new ArrayList<PImage>(Arrays.asList(frames)));
          // println("Loaded " + filename + ".");
        } 
        catch (Exception e) {
          println("Failed to load " + filename + ": " + e.getMessage());
        }
      }
    }
  }
}

void selectAnimation(String filename) {
  ArrayList<PImage> frames;
  synchronized(loaded) {
    if (!loaded.containsKey(filename)) {
      loaded.put(filename, null);
    }
    if (loaded.get(filename) == null) {
      loadAnimations();
    }
    frames = loaded.get(filename);
  }
  anim_frames = frames.toArray(new PImage[1]);
  cur_frame = 0;
  cur_floatframe = 0.0;
  reps = 0;

  started = System.currentTimeMillis() / 1000;
  println(String.format("%d/%d %s", cur_anim, playlist.size(), filename));
}

int bound(int n) {
  return (n < 0 ? playlist.size() : 0) + (n % playlist.size());
}

void nextAnim(int num) {
  if (num > 0) {
    cur_anim = bound(cur_anim + 1);
  } else if (num < 0) {
    cur_anim = bound(cur_anim - 1);
  } else {
    cur_anim = bound(cur_anim);
  }
  selectAnimation(playlist.get(cur_anim));
  HashSet<String> adjacent = new HashSet<String>(4);
  for (int i = cur_anim - 2; i < cur_anim + 3; i++) {
    adjacent.add(playlist.get(bound(i)));
  }
  synchronized(loaded) {
    loaded.keySet().retainAll(adjacent);
    for (String filename : adjacent) {
      if (!loaded.containsKey(filename)) {
        loaded.put(filename, null);
      }
    }
  }
  thread("loadAnimations"); // background
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
    selectAnimation(dataPath("000polargrid.gif"));
    cur_anim--;
    return;
  }
  if (key == 'r') {
    resetDefaults();
  }
  if (key == 'x') {
    moveFile("Trash");
    nextAnim(0);
    return;
  }
  if (key == 'f') {
    moveFile("Fix");
    nextAnim(0);
    return;
  }
  if (key == CODED && keyCode == LEFT) {
    nextAnim(-1);
    return;
  }
  if (key == CODED && keyCode == RIGHT) {
    nextAnim(1);
    return;
  }
  if (key >= '1' && key <= '9') {
    // String keyword = KEYWORDS[((int)key) - 49];
    // client.toggleKeyword(playlist.get(cur_anim), keyword);
    return;
  }

  // fall through to move to the next animation
  nextAnim(1);
}

// stretches an image over the entire target canvas
void drawFullscreenQuad(PGraphics t, PImage i)
{
  float img_scale = max((float)t.width / (float)i.width, (float)t.height / (float)i.height);
  t.imageMode(CENTER);
  t.image(i, t.width/2, t.height/2, i.width * img_scale, i.height * img_scale);
}

void draw()
{
  // draw pattern into source texture
  // also, blend together adjacent frames (looks better at slow speeds)
  src.beginDraw();
  src.background(0);
  int next_frame = (cur_frame == anim_frames.length-1) ? 0 : cur_frame+1;
  float partial = cur_floatframe - (float)cur_frame;
  src.tint(255, 255);
  drawFullscreenQuad(src, anim_frames[cur_frame]);
  src.tint(255, 255 * partial);
  drawFullscreenQuad(src, anim_frames[next_frame]);
  src.endDraw();

  // update animation
  cur_floatframe += cur_framerate / 60.0;
  if (cur_floatframe >= (float)anim_frames.length) {
    cur_floatframe -= (float)anim_frames.length;
    reps++;
  } else if (cur_floatframe < 0.0) {
    cur_floatframe += (float)anim_frames.length;
    reps++;
  }
  cur_frame = (int)cur_floatframe;

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

  if (refresh < 300) {
    if (started + refresh < System.currentTimeMillis() / 1000) {
      nextAnim(1);
    }
  }
}

void moveFile(String folder) {
  try {
    File current = new File(playlist.get(cur_anim));
    Files.move(current.toPath(), new File(dataPath(folder+"/"+current.getName())).toPath());
    playlist.remove(cur_anim);
    print("moved to " + dataPath(folder+"/"+current.getName()));
  } 
  catch (IOException e) {
    print(e);
  }
}

