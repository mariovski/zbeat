/*  Implemented the JPEG compression sketch by Jeff Thompson
    https://gist.github.com/jeffThompson/ea54b5ea40482ec896d1e6f9f266c731
    
    Default Processing save is 90% compression, for Azure 50% will be good enough and it's faster.
*/


import java.net.URI;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.entity.ContentType;

import org.apache.http.client.utils.URIBuilder;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;

// for saveJpeg
import java.awt.image.BufferedImage;
import javax.imageio.plugins.jpeg.*;
import javax.imageio.*;
import javax.imageio.stream.*;

class FaceAnalysis extends Thread {
  
  // Don't forget to fill in your API key!
  String subscriptionKey = "1ca9b63916014bd5ac3b552a3a9b4243"; // your free key here (7 days trial)
  String uriBase = "https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect"; // check your location endpoint!!!


  
  HttpClient httpclient = new DefaultHttpClient();
  URIBuilder builder;
  
  PImage image;
  
  String faceAPIData = "";
  boolean isDataAvailable = false;
  
  float jpegCompressionLevel = 0.5;
  
  FaceAnalysis(PImage _image) {
    this.image = _image;
    
    if(subscriptionKey == "") {
      println("Make sure you fill in your API key!");
      return;
    }
    super.start();
  }
  
  boolean isDataAvailable() {
    return isDataAvailable;
  }
  
  String getDataString() {
    return faceAPIData;
  }
  
  void run() {
    try {
      
      URIBuilder builder = new URIBuilder(uriBase);
  
      // Request parameters. All of them are optional.
      builder.setParameter("returnFaceId", "false");
      builder.setParameter("returnFaceLandmarks", "true");
      builder.setParameter("returnFaceAttributes", "age,gender,smile,emotion,glasses,hair,facialHair");
    
      // Prepare the URI for the REST API call.
      URI uri = builder.build();
      HttpPost request = new HttpPost(uri);
  
      // Request headers.
      request.setHeader("Content-Type", "application/octet-stream");
      request.setHeader("Ocp-Apim-Subscription-Key", subscriptionKey);
      
      File file = new File(dataPath("pictureToBeAnalysed.jpg"));
      
      // deleting an existing pictureToBeAnalysed first, before saving a new one.
      // otherwise filesize always stays the same...
      if (file.exists()) file.delete(); 
      
      // we just save it to disk and then upload that file to Azure. 
      // simpler that converting raw info to a jpeg bytestream
      // Processing save() will work, but the result is not very compressed (90%)
      
      saveJpeg(image,dataPath("pictureToBeAnalysed.jpg"));
      
      FileEntity reqEntity = new FileEntity(file, ContentType.APPLICATION_OCTET_STREAM);
   
      request.setEntity(reqEntity);
      
      // Execute the REST API call and get the response entity.
      HttpResponse response = httpclient.execute(request);
      
      HttpEntity entity = response.getEntity();
  
      if (entity != null) {
        
          // Format and display the JSON response.
          faceAPIData = EntityUtils.toString(entity).trim();
          isDataAvailable = true;
          
          //println("REST Response:\n"+faceAPIData);
      }
    }
    catch (Exception e) {  
      // Display error message.
      System.out.println(e.getMessage());
    } 
  }
  
  
  
  
  
  void saveJpeg(PImage img, String outputFilename) {
  
    try {
  
      // setup JPG output
      JPEGImageWriteParam jpegParams = new JPEGImageWriteParam(null);
      jpegParams.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
      jpegParams.setCompressionQuality(jpegCompressionLevel);
      final ImageWriter writer = ImageIO.getImageWritersByFormatName("jpg").next();
      writer.setOutput(new FileImageOutputStream(new File(outputFilename)));
  
      // native PImage is ARGB, this needs to be converted to RGB. 
      // https://blog.idrsolutions.com/2009/10/converting-java-bufferedimage-between-colorspaces/
      
      BufferedImage in  = (BufferedImage) img.getNative();
      BufferedImage out = new BufferedImage(img.width, img.height, BufferedImage.TYPE_INT_RGB);
      out.getGraphics().drawImage(in,0,0,null);
      
      // save it!
      writer.write(null, new IIOImage(out, null, null), jpegParams);
      //println("Saved!");
    }
    catch (Exception e) {
      println("Problem saving... :(");
      println(e);
    }
  }
  
}
