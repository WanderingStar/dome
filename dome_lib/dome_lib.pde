import themidibus.*;
import gifAnimation.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Vector;

int refresh = 60;
boolean shuffle = true;
int initial = 0;

// nanoKontrol 1
final int DIAL1 = 14;
final int DIAL2 = 15;
final int DIAL3 = 16;
final int DIAL4 = 17;
final int DIAL5 = 18;
final int DIAL6 = 19;
final int DIAL7 = 20;
final int DIAL8 = 21;
final int DIAL9 = 22;
final int SLIDER1 = 2;
final int SLIDER2 = 3;
final int SLIDER3 = 4;
final int SLIDER4 = 5;
final int SLIDER5 = 6;
final int SLIDER6 = 8;
final int SLIDER7 = 9;
final int SLIDER8 = 12;
final int SLIDER9 = 13;
final int RECORD = 44;
final int PLAY = 45;
final int STOP = 46;
final int REWIND = 47;
final int FASTFORWARD = 48;
final int RESET = 49;

// nanoKontrol 2
/*final int DIAL1 = 16;
 final int DIAL2 = 17;
 final int DIAL3 = 18;
 final int DIAL4 = 19;
 final int DIAL5 = 20;
 final int DIAL6 = 21;
 final int DIAL7 = 22;
 final int DIAL8 = 23;
 final int SLIDER1 = 0;
 final int SLIDER2 = 1;
 final int SLIDER3 = 2;
 final int SLIDER4 = 3;
 final int SLIDER5 = 4;
 final int SLIDER6 = 5;
 final int SLIDER7 = 6;
 final int SLIDER8 = 7;
 final int REWIND = 43;
 final int FASTFORWARD = 44;
 final int RESET = 46;*/

final float DEFAULT_CUR_FRAMERATE = 30.0;
final float DEFAULT_DOME_ANGVEL = 0.0;
final float DEFAULT_HUE_SHIFT_DEG = 0.0;
final float DEFAULT_SAT_SCALE = 1.0;
final float DEFAULT_VAL_SCALE = 1.0;
final float DEFAULT_INVERT = 0.0;
final float DEFAULT_DOME_COVERAGE = 0.9;
final int DEFAULT_REFRESH = 60;

// dome distortion
PGraphics src, targ;
DomeDistort dome;

// animation & playback
//ArrayList<String> anims = new ArrayList<String>();
ProjectApiClient client = new ProjectApiClient("http://localhost:8000");
List<String> playlist = new ArrayList<String>();
HashMap<String, ArrayList<PImage>> loaded = new HashMap<String, ArrayList<PImage>>();
PImage[] anim_frames;
int cur_anim = 0;
int cur_frame = 0;
float cur_floatframe = 0.0; // higher-resolution frame number, truncated to get cur_frame
float cur_framerate = DEFAULT_CUR_FRAMERATE; // can be fractional or negative
int reps = 0;
long started;

// MIDI control
MidiBus kontrol;

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

void setup()
{
  //size(1024, 1024, P3D);
  //size(1920, 1080, P3D);
  //size(1280, 720, P3D);
  //size(854, 480, P3D);
  size(960, 540, P3D);

  // Framerate set to 61, since apparently Processing's timing is sometimes
  // off and we get judder when set to 60.
  // Animation playback speed is controlled by cur_framerate.
  frameRate(15);

  // set up source buffer for the actual frame data
  src = createGraphics(1024, 1024, P3D);

  // set up target buffer to render into
  targ = createGraphics(width, height, P3D);

  // create and configure the distortion object
  dome = new DomeDistort(targ, src);
  dome.setTexExtent(0.9); // set to < 1.0 to shrink towards center of dome
  dome.setTexRotation(0); // set to desired rotation angle in radians

  println(dataPath(""));

  // make list of animations
  client.addDirectory(dataPath("content"));
  updatePlaylist();
  cur_anim = initial;
  nextAnim(0);

  // configure nanokontrol, if it exists
  MidiBus.list();
  kontrol = new MidiBus(this, "SLIDER/KNOB", "CTRL");

  new File(dataPath("Trash")).mkdir();
  new File(dataPath("Fix")).mkdir();
}

void updatePlaylist() {
  List<String> nextPlaylist = client.updatePlaylist();
  if (nextPlaylist != null) {
    playlist = nextPlaylist;
    if (shuffle) {
      Collections.shuffle(playlist);
    }
    cur_anim = 0;
  }
}

void loadAnimations() {
  // this is called in a background thread to load an unloaded animations
  for (String filename : loaded.keySet ()) {
    synchronized(loaded) {
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
  HashMap<String, Float> settings = client.getSettings(filename);
  if (settings != null) {
    println(settings);
    if (settings.get("cur_framerate") != null) {
      println(settings.get("cur_framerate"));
      println(cur_framerate);
      cur_framerate = settings.get("cur_framerate");
      println(cur_framerate);
    }
    if (settings.get("dome_angvel") != null)
      cur_framerate = settings.get("dome_angvel");
    if (settings.get("hue_shift_deg") != null)
      cur_framerate = settings.get("hue_shift_deg");
    if (settings.get("sat_scale") != null) 
      cur_framerate = settings.get("sat_scale");
    if (settings.get("val_scale") != null)
      cur_framerate = settings.get("val_scale");
    if (settings.get("invert") != null)
      cur_framerate = settings.get("invert");
    if (settings.get("dome_coverage") != null)
      cur_framerate = settings.get("dome_coverage");
  }
  started = System.currentTimeMillis() / 1000;
  client.addToHistory(filename, started, 0, 0);
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
  updatePlaylist();
  selectAnimation(playlist.get(cur_anim));
  HashSet<String> adjacent = new HashSet<String>(4);
  for (int i = cur_anim - 2; i < cur_anim + 3; i++) {
    // print(bound(i) + " ");
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
    cur_framerate = DEFAULT_CUR_FRAMERATE;
    dome_angvel = DEFAULT_DOME_ANGVEL;
    hue_shift_deg = DEFAULT_HUE_SHIFT_DEG;
    sat_scale = DEFAULT_SAT_SCALE;
    val_scale = DEFAULT_VAL_SCALE;
    invert = DEFAULT_INVERT;
    dome_coverage = DEFAULT_DOME_COVERAGE;
    refresh = DEFAULT_REFRESH;
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
  if (key == '1') {
    client.toggleKeyword(playlist.get(cur_anim), "chill");
    return;
  }
  if (key == '2') {
    client.toggleKeyword(playlist.get(cur_anim), "energetic");
    return;
  }
  if (key == '3') {
    client.toggleKeyword(playlist.get(cur_anim), "monochrome");
    return;
  }
  if (key == '4') {
    client.toggleKeyword(playlist.get(cur_anim), "colorful");
    return;
  }
  if (key == '9') {
    client.toggleKeyword(playlist.get(cur_anim), "creepy");
    return;
  }

  // fall through to move to the next animation
  nextAnim(1);
}

// midi input callback
void controllerChange(int channel, int number, int value) {
  println("Controller Change: "+channel+", "+number+": "+value );

  float fval = (float)value/127.0;

  // all number are in scene 1
  switch (number) {
  case DIAL1:
  case SLIDER1:
    cur_framerate = lerp(-60.0, 60.0, fval);
    println("Framerate: "+cur_framerate+" fps");
    break;
  case DIAL2:
  case SLIDER2:
    if (value >= 61 && value <= 67)
      dome_angvel = 0.0;
    else
      dome_angvel = lerp(-0.2, 0.2, fval);

    println("Dome rotation: "+degrees(dome_angvel)+" deg/s");
    break;
  case DIAL3:
  case SLIDER3:
    hue_shift_deg = lerp(0.0, 360.0, fval);
    println("Hue shift: "+hue_shift_deg+" deg");
    break;
  case DIAL4:
  case SLIDER4:
    sat_scale = 2.0*fval;
    println("Saturation scale: "+sat_scale);
    break;
  case DIAL5:
  case SLIDER5:
    val_scale = 2.0*fval;
    println("Value scale: "+val_scale);
    break;
  case DIAL6:
  case SLIDER6:
    invert = fval;
    println("Invert: "+invert);
    break;
  case DIAL7:
  case SLIDER7:
    dome_coverage = lerp(0.01, 1.0, fval);
    println("Radial dome coverage: "+dome_coverage);
    break;
  case DIAL9:
  case SLIDER9:
    refresh = (int) lerp(10, 300, fval);
    println("Refresh rate: "+refresh);
    break;
  case REWIND:
    if (value > 0)
      nextAnim(-1);
    break;
  case FASTFORWARD:
    if (value > 0)
      nextAnim(1);
    break;
  case RESET:
    if (value > 0)
    {

      cur_framerate = DEFAULT_CUR_FRAMERATE;
      dome_angvel = DEFAULT_DOME_ANGVEL;
      hue_shift_deg = DEFAULT_HUE_SHIFT_DEG;
      sat_scale = DEFAULT_SAT_SCALE;
      val_scale = DEFAULT_VAL_SCALE;
      invert = DEFAULT_INVERT;
      dome_coverage = DEFAULT_DOME_COVERAGE;
      refresh = DEFAULT_REFRESH;
    }
    break;
  case RECORD:
    if (value > 0)
    {
      HashMap<String, Float> settings = new HashMap<String, Float>();
      if (cur_framerate != DEFAULT_CUR_FRAMERATE)
        settings.put("cur_framerate", cur_framerate);
      if (dome_angvel != DEFAULT_DOME_ANGVEL)
        settings.put("dome_angvel", dome_angvel);
      if (hue_shift_deg != DEFAULT_HUE_SHIFT_DEG)
        settings.put("hue_shift_deg", hue_shift_deg);
      if (sat_scale != DEFAULT_SAT_SCALE)
        settings.put("sat_scale", sat_scale);
      if (val_scale != DEFAULT_VAL_SCALE)
        settings.put("val_scale", val_scale);
      if (invert != DEFAULT_INVERT)
        settings.put("invert", invert);
      if (dome_coverage != DEFAULT_CUR_FRAMERATE)
        settings.put("dome_coverage", dome_coverage);
      println(settings);
      client.setSettings(playlist.get(cur_anim), settings);
    }
    break;
  case STOP:
    if (value > 0)
    {
      moveFile("Trash");
      nextAnim(0);
    }
    break;
  default:
    break;
  }
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

  // update texture params
  dome_rotation += dome_angvel / 60.0;
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
  } 
  catch (IOException e) {
    print(e);
  }
}

