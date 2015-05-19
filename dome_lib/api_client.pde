import http.requests.*;
import java.io.File;
import java.util.regex.*;
import java.util.*;


class ProjectApiClient {
  public final Pattern idGifPattern = Pattern.compile("(\\d{3,}).*\\.gif$");

  private String baseUrl = "http://localhost:8000";
  private HashMap<Long, String> idFilename = new HashMap<Long, String>();
  private List<String> playlist = new ArrayList<String>();
  private Set<String> keywords = new HashSet<String>();
  private int current = 0;

  public double lastUpdated = 0;

  public ProjectApiClient(String baseUrl) {
    this.baseUrl = baseUrl;
  }

  public void addDirectory(String path) {
    println(path);
    File dir = new File(path);
    for (String filename : dir.list ()) {
      Matcher m = idGifPattern.matcher(filename);
      if (m.find()) {
        idFilename.put(new Long(m.group(1)), path + "/" + filename);
        playlist.add(path + "/" + filename);
      }
    }
  }

  private JSONObject get(String urlPath) {
    GetRequest get = new GetRequest(baseUrl + urlPath);
    get.send();
    return JSONObject.parse(get.getContent());
  }

  public void updatePlaylist() {
    try {
      GetRequest get = new GetRequest(baseUrl + "/play");
      get.send();
      JSONObject response = JSONObject.parse(get.getContent());
      
      double updated = response.getDouble("updated");
      if (updated <= lastUpdated)
        return;
      lastUpdated = updated;

      String[] keywordArray = response.getJSONArray("keywords").getStringArray();
      keywords = new HashSet<String>();
      keywords.addAll(Arrays.asList(keywordArray));

      // ignore any items in the playlist that we don't have files for
      playlist = new ArrayList<String>();
      for (long id : response.getJSONArray("ids").getLongArray()) {
        if (idFilename.get(id) != null) {
          playlist.add(idFilename.get(id));
        }
      }
      current = current % playlist.size();
    }
    catch (Exception e) {
      //print("Couldn't update playlist: " + e);
    }
  }
 
   public String getCurrentFilename() {
     return playlist.get(current);
   }
   
   public String next() {
     current = (current + 1) % playlist.size();
     return getCurrentFilename();
   }
   
   public String prev() {
     current = (current - 1) % playlist.size();
     return getCurrentFilename();
   }
   
   public void addToHistory(long startedAt, long stoppedAt, int repetitions) {
      Matcher m = idGifPattern.matcher(getCurrentFilename());
      m.find();
      Long id = new Long(m.group(1));
      PostRequest post = new PostRequest(baseUrl + "/history");
      JSONObject history = new JSONObject();
      history.setLong("id", id);
      history.setLong("start", startedAt);
      history.setLong("end", stoppedAt);
      history.setInt("reps", repetitions);
      post.addData("json", history.toString());
      post.send();
   }
   
}  
     

