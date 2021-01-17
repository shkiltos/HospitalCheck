# Hospital Check
A simple system that sends you notification when a person presses the emergency button on a simple device.  
  
This was developed when I had to look after a person with COVID-19.  
Since a patient is contagious, a contact is undesirable, but sometimes he/she needs help and feels to weak to call for help or make a phone call,  
so pressing just a one button is a good solution and feels kinda cool, right?  
  
Check the exapmle of work by clicking on video below or [here](https://www.youtube.com/watch?v=Su9PxsEquyQ&feature=youtu.be).  

<a href="https://www.youtube.com/watch?v=Su9PxsEquyQ&feature=youtu.be" target="_blank"><img src="https://img.youtube.com/vi/Su9PxsEquyQ/0.jpg" 
alt="IoT button press sends push notification to phone" width="500" height="400" border="10" /></a>
  
  
An iOS app was developed and it successfully connects to mqtt, sends push notifications, but doesn't work in background mode, so it was put aside.

Eventually it was decided to use an existing app that has a phone application and an API to send the mesage,  
there is a number of such, but I stopped at [Pushy](https://pushy.me/).

## How to use
You will need to change the script constants:
* fingerprint
* post data(got from from Pushy):
  * app key
  * app secret
* STASSID and STAPSK(wifi credentials)
  
After this, upload the script to a ESP8266(or another device with WiFi module).  
Make sure that your scheme has a button in it and it's on the same pin as in script.
