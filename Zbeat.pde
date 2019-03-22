//import processing.sound.*;
import processing.video.*;
import java.awt.*;





PImage screenshot;
Capture cam;

PImage webcamPicture;
PGraphics faceDataOverlay;
int cw=640;
int ch=480;
int indexEmotion=4;
int indexEmotionOld=4;
String onScreenText;
PFont SourceCodePro;

// camera in the setup in combination with other code, sometimes gives a
// Waited for 5000s error: "java.lang.RuntimeException: Waited 5000ms for: <"...
// so we will do init in the draw loop
boolean cameraInitDone = false;

// Face API – free: Up to 20 transactions per minute (so interval 3000ms)
// Face API - standard: Up to 10 transactions per second (so interval 100ms)
int minimalAzureRequestInterval = 3000; 

boolean isAzureRequestRunning = false;
int lastAzureRequestTime = 0; 

String azureFaceAPIData;

FaceAnalysis azureFaceAnalysis;


// SOM
import ddf.minim.*;
Minim minim;
AudioPlayer[] soundEmotions=new AudioPlayer[7];
//SoundFile[] soundEmotions = new SoundFile[7];
float volume = 0.0, speed = 0.01;
boolean processa=false;
int emotionAudioOut=4;
int emotionAudioIn=4;



 void setup() {

  size(640,480,P2D);
  

  SourceCodePro = createFont("SourceCodePro-Regular.ttf",12);
  textFont(SourceCodePro);
  
  onScreenText = "Press space to take a picture and sent to Azure.";
  

  screenshot();
  
  // SOM
    minim = new Minim(this);
  processa = false;
  // Load a soundfile
  soundEmotions[0] = minim.loadFile("raiva.mp3");
  soundEmotions[1] = minim.loadFile("triste.mp3");
  soundEmotions[2] = minim.loadFile("raiva.mp3");
  soundEmotions[3] = minim.loadFile("feliz.mp3");
  soundEmotions[4] = minim.loadFile("neutro.mp3");
  soundEmotions[5] = minim.loadFile("triste.mp3");
  soundEmotions[6] = minim.loadFile("surpresa.mp3");
  println("carregando sons");
  for(int i = 0; i < 7; i++) {
    println(i);
    while(soundEmotions[i] == null){println(i);}
    if (soundEmotions[i]!=null){
      //soundEmotions[i].loop();
      //  soundEmotions[i].setGain(-100);
    }

  } 
}





void draw() {
  
  background(0);
 
  if(!cameraInitDone) {
    fill(255);
    onScreenText = "Waiting for the camera to initialize...";
    initCamera();
  }
  else {
    
    startFaceAnalysis();
    //println("emotion=" + indexEmotion);
    if (indexEmotionOld!=indexEmotion){
      if (indexEmotion>=0) dalhe(indexEmotion);
      println(emotionAudioOut + " " + emotionAudioIn);
        
    }
    indexEmotionOld=indexEmotion;
 
        
    

    if (webcamPicture!=null) image(webcamPicture,0,0,cw,ch);
    if (faceDataOverlay!=null) image(faceDataOverlay,0,0,cw,ch);
  }
  
  text(onScreenText,20,380,width-40,height-20);
  
  if(azureFaceAnalysis!=null) {
    if(azureFaceAnalysis.isDataAvailable()) {
      parseAzureFaceAPIResponse(azureFaceAnalysis.getDataString());
      onScreenText = azureFaceAnalysis.getDataString();
      isAzureRequestRunning = false;
    }
  }
 

}


//------------------------------------------------------
//              SOM
//------------------------------------------------------






void dalhe(int index){
  emotionAudioOut=emotionAudioIn;
  emotionAudioIn=index;
  println("----------------" + emotionAudioIn );
  soundEmotions[emotionAudioOut].play();
  soundEmotions[emotionAudioOut].shiftGain(50, -100, 3000);
  soundEmotions[emotionAudioIn].play();
  soundEmotions[emotionAudioIn].shiftGain(-100, 50, 3000);
}








//------------------------------------------------------









void screenshot() {
  try {
    screenshot = new PImage(new Robot().createScreenCapture(new Rectangle(0, 0, displayWidth, displayHeight)));
  } catch (AWTException e) { }
  screenshot.resize(cw,ch);
}


void keyPressed() {
  // space-bar
  if(keyCode == 32) {
    startFaceAnalysis();  
  }
}

void startFaceAnalysis() {
  if(isAzureRequestRunning == false) {
    if((millis() - minimalAzureRequestInterval) > lastAzureRequestTime) {
      screenshot();
      webcamPicture = screenshot.get();
      onScreenText = "The request is sent to Azure.";
      isAzureRequestRunning = true;
      azureFaceAnalysis = new FaceAnalysis(webcamPicture);
    }
    else {
      onScreenText = "The request is sent to fast based on transactions per minute (free version every 3 seconds)";  
    }
  }
  else {
    onScreenText = "Previous data is still requested.";
  }
          
}

void parseAzureFaceAPIResponse(String azureFaceAPIData) {
  
    // we don't parse all the data
    // check the reference on other data that is available
    // https://westus.dev.cognitive.microsoft.com/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236
    
    indexEmotion=4; //neutro
          
    if(azureFaceAPIData.charAt(0)!='[') return;
  
    JSONArray jsonArray = parseJSONArray(azureFaceAPIData);
    
    faceDataOverlay.beginDraw();
    faceDataOverlay.clear();
    
    for (int i=0; i < jsonArray.size(); i++) {
      JSONObject faceObject = jsonArray.getJSONObject(i);
      
      JSONObject faceRectangle  = faceObject.getJSONObject("faceRectangle");
      JSONObject faceLandmarks  = faceObject.getJSONObject("faceLandmarks");
      JSONObject faceAttributes = faceObject.getJSONObject("faceAttributes");
      
      int rectX = faceRectangle.getInt("left");   
      int rectY = faceRectangle.getInt("top");    
      int rectW = faceRectangle.getInt("width");  
      int rectH = faceRectangle.getInt("height"); 
      
      float puppilLeftX = faceLandmarks.getJSONObject("pupilLeft").getFloat("x");
      float puppilLeftY = faceLandmarks.getJSONObject("pupilLeft").getFloat("y");
      float puppilRightX = faceLandmarks.getJSONObject("pupilRight").getFloat("x");
      float puppilRightY = faceLandmarks.getJSONObject("pupilRight").getFloat("y");
      
      float age = faceAttributes.getFloat("age");
      String gender = faceAttributes.getString("gender");
      
      String faceInfo = "age: " + str(age) + "\n" + gender;
      JSONObject emotion = faceAttributes.getJSONObject("emotion");
      
      String [] emotions = { "anger", "contempt", "disgust", "happiness", "neutral", "sadness", "surprise" };
      
      float highestEmotionPercentage = 0.0;
      String highestEmotionString = "";
      

      for(int j = 0; j<emotions.length; j++) {
       float thisEmotionPercentage = emotion.getFloat(emotions[j]);
       
       if(thisEmotionPercentage > highestEmotionPercentage) {
        highestEmotionPercentage = thisEmotionPercentage; 
        highestEmotionString = emotions[j];
        indexEmotion=j;
       }
      }
      
      String faceEmotion = highestEmotionString + "("+str(highestEmotionPercentage)+")";

      
      faceDataOverlay.stroke(0,255,0);
      faceDataOverlay.strokeWeight(4);
      
      //faceDataOverlay.noFill();
      faceDataOverlay.fill(255,128);
      
      faceDataOverlay.rect(rectX,rectY,rectW,rectH);
      
      faceDataOverlay.fill(255,0,0);
      faceDataOverlay.noStroke();
      faceDataOverlay.ellipse(puppilLeftX,puppilLeftY,8,8);
      faceDataOverlay.ellipse(puppilRightX,puppilRightY,8,8);
      
      faceDataOverlay.fill(0,255,0);
      faceDataOverlay.stroke(0);
      faceDataOverlay.textSize(32);
      faceDataOverlay.textAlign(LEFT, BOTTOM);
      
      faceDataOverlay.text(faceInfo,rectX+5,rectY,rectW,rectH-5);
      //faceDataOverlay.text(faceInfo,rectX,rectY+rectH);
       
      if(rectY<((faceDataOverlay.height-rectH)/2)) { 
        // face on upperhalf of picture
        faceDataOverlay.textAlign(LEFT, TOP);
        faceDataOverlay.text(faceEmotion,rectX,rectY+rectH+10);
      } 
      else {
        faceDataOverlay.textAlign(LEFT, BOTTOM);
        faceDataOverlay.text(faceEmotion,rectX,rectY);
      }
      
    }
    
    faceDataOverlay.endDraw();
  
}


void initCamera(){
    if(frameCount<2) return;
    
    cameraInitDone = true;
    onScreenText = "";
    
    // create the overlay PGraphics here
    // so it's exactly the   size of the camera
    faceDataOverlay = createGraphics(cw,ch);
    faceDataOverlay.beginDraw();
    faceDataOverlay.clear();
    faceDataOverlay.endDraw(); 
    
}












/*
void initCamera() { 
  
  // make sure the draw runs one time to display the "waiting" text
  if(frameCount<2) return;
  
   String[] cameras = Capture.list();
  

      
   if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
   } 
   else {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    cam = new Capture(this, cameras[5]);
    
    
    // Start capturing the images from the camera
    cam.start();
    
    delay(2000);
    
    while(cam.available() != true) {
      delay(1);//println("waiting for camera !!!");
    }
    
    // read once to get correct width, height
    cam.read();
    

    
    // create the overlay PGraphics here
    // so it's exactly the   size of the camera
    faceDataOverlay = createGraphics(cam.width,cam.height);
    faceDataOverlay.beginDraw();
    faceDataOverlay.clear();
    faceDataOverlay.endDraw();  
    
    cameraInitDone = true;
    
    onScreenText = "";

  }
   
}
*/