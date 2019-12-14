# Project4 :- Twitter-Engine-Simulation (Part 2)   
Demo for the project: https://youtu.be/YQF5jQfP_aA   

NAME 1: Rahul Wahi  
UFID: 3053-6162  
  
NAME 2: Wins Goyal  
UFID: 7357-1559  
  
*************************************************************************************************************************
1. **STEPS to run the code**
   
__step1:__ Unzip the file and enter into the "Project4.2" folder through terminal **($cd Project4)** or where *mix.exs* file is present.    
 Before you start the Phoenix server, run following commands to install some required dependencies:

  * `mix deps.get` (Install Required Dependecies)
  * Go to `cd assets && npm install` (Install Node.js dependencies)
  * `mix phx.server` (Start Phoenix Server, it's start point is at the Application creating Endpoint as the Supervisor.)

Go to `localhost:4000` (http://localhost:4000) from browser to access the web interface for the Twitter Engine.
  * Can't login if new to Twitter Engine. Create your User account from the given form and login.
  * Create new other user opening a new browser window or tab, and start interacting with the already simulated 100 users and/or web users just created.  
  * If the user subscribes to other user, he can see that user's tweets on his own wall, with corresponding timestamp and the user's name mentioned with it. 

*************************************************************************************************
2. **Functionalities Used in the Simulator**  

	* User can register and login, and then can logout.
	* After logout, if user login again, will find his wall as he left.
	* User can post his tweet on the walls.
	* If the user is subscribed by other user, his tweets are also visible to that user.
	* Tweets can be done with @USer and #HAshtag.
	* If @user being mentioned doesn't exist, the tweet will not be viable.
	* User can follow other users and can check his tweets in real time on his own wall.
	* User can retweet the subscribed user's tweets being shown on his wall.
	* User can seach tweets in which he is mentioned (MyMentions).
	* Uset can look for specific tweets with specific hashtags if they were used.
	* User can search other's simulated user's tweets using hashtag_<n>.

*************************************************************************************************
3. **Our Testing**  
  
This is the Umbrella Application. First 100 Users will be simulated in parallel while you can access the web-interface as explained above. And, check all the basic functionalities.  

The corresponding demo of the Project is below:  
** https://youtu.be/YQF5jQfP_aA **