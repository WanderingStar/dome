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

  public double lastUpdated = 0;

  public ProjectApiClient(String baseUrl) {
    this.baseUrl = baseUrl;
  }

  public void addDirectory(String path) {
    println("adding content from " + path);
    File dir = new File(path);
    for (String filename : dir.list ()) {
      String filepath = path + "/" + filename;
      Matcher m = idGifPattern.matcher(filename);
      if (m.find()) {
        idFilename.put(new Long(m.group(1)), filepath);
        playlist.add(filepath);
      } else if (new File(filepath).isDirectory()) {
        addDirectory(filepath);
      }
    }
  }

  private JSONObject get(String urlPath) {
    GetRequest get = new GetRequest(baseUrl + urlPath);
    get.send();
    return JSONObject.parse(get.getContent());
  }

  public List<String> updatePlaylist() {
    try {
      GetRequest get = new GetRequest(baseUrl + "/play");
      get.send();
      JSONObject response = JSONObject.parse(get.getContent());

      double updated = response.getDouble("updated");
      if (updated <= lastUpdated)
        return null;
      lastUpdated = updated;

      String[] keywordArray = response.getJSONArray("keywords").getStringArray();
      keywords = new HashSet<String>(Arrays.asList(keywordArray));
      
      // ignore any items in the playlist that we don't have files for
      playlist = new ArrayList<String>();
      for (long id : response.getJSONArray ("ids").getLongArray()) {
        if (idFilename.get(id) != null) {
          playlist.add(idFilename.get(id));
        }
      }
    }
    catch (Exception e) {
      //print("Couldn't update playlist: " + e);
    }
    return playlist;
  }

  public long getGifId(String filename) {
    Matcher m = idGifPattern.matcher(filename);
    m.find();
    return new Long(m.group(1));
  }

  public void addToHistory(String filename, long startedAt, long stoppedAt, int repetitions) {
    long id = getGifId(filename);
    PostRequest post = new PostRequest(baseUrl + "/history");
    JSONObject history = new JSONObject();
    history.setLong("id", id);
    history.setLong("start", startedAt);
    history.setLong("end", stoppedAt);
    history.setInt("reps", repetitions);
    post.addData("json", history.toString());
    post.send();
  }

  public HashSet<String> getKeywords(String filename) {
    String url = String.format("%s/%d/keywords", baseUrl, getGifId(filename));
    GetRequest get = new GetRequest(url);
    get.send();
    try {
      JSONObject response = JSONObject.parse(get.getContent());
      String[] keywords = response.getJSONArray("keywords").getStringArray();
      return new HashSet<String>(Arrays.asList(keywords));
    } 
    catch (Exception e) {
      return new HashSet<String>();
    }
  }

  public void setKeywords(String filename, Set<String> keywords) {
    StringBuffer joined = new StringBuffer();
    for (String k : keywords) {
      joined.append(k);
      joined.append(",");
    }
    String url = String.format("%s/%d/keywords?keywords=%s", baseUrl, getGifId(filename), joined);
    GetRequest get = new GetRequest(url);
    get.send();
  }

  public void toggleKeyword(String filename, String keyword) {
    HashSet<String> keywords = getKeywords(filename);
    if (keywords.contains(keyword)) {
      keywords.remove(keyword);
    } else {
      keywords.add(keyword);
    }
    setKeywords(filename, keywords);
    println("keywords: " + keywords);
  }
}

