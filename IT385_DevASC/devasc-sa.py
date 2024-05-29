######################################################################################
# This program:
# - Asks the user to enter an access token or use the hard coded access token.
# - Lists the user's Webex rooms.
# - Asks the user which Webex room to monitor for "/seconds" of requests.
# - Monitors the selected Webex Team room every second for "/seconds" messages.
# - Discovers GPS coordinates of the ISS flyover using ISS API.
# - Display the geographical location using Graphhopper API based on the GPS coordinates.
# - Formats and sends the results back to the Webex Team room.
#
# The student will:
# 1. Import libraries for API requests, JSON formatting, parsing URLs into components, and epoch time conversion.
# 2. Complete the if statement to ask the user for the Webex access token.
# 3. Provide the URL to the Webex room API.
# 4. Create a loop to print the type and title of each room.
# 5. Provide the URL to the Webex messages API.
# 6. Provide the URL to the ISS Current Location API.
# 7. Record the ISS GPS coordinates and timestamp.
# 8. Convert the timestamp epoch value to a human readable date and time.
# 9. Provide your Graphhopper API consumer key.
# 10. Provide the URL to the Graphhopper GeoCoding API.
# 11. Store the location received from the Graphhopper API in a variable.
# 12. Complete the code to format the response message.
# 13. Complete the code to post the message to the Webex room.
###############################################################
 
#######################################################################################
# 1. Import libraries for API requests, JSON formatting, parsing URLs into components, and epoch time conversion.

<!!!REPLACEME with code for libraries>

# 2. Complete the if statement to ask the user for the Webex access token.
choice = input("Do you wish to use the hard-coded Webex token? (y/n) ")

<!!!REPLACEME with if statements to ask user for the Webex Access Token!!!>
else:
    accessToken = "Bearer <!!!REPLACEME with hard-coded token!!!>"

# 3. Provide the URL to the Webex room API.
r = requests.get(   "<!!!REPLACEME with URL!!!>",
                    headers = {"Authorization": accessToken}
                )

#######################################################################################
# DO NOT EDIT ANY BLOCKS WITH r.status_code
if not r.status_code == 200:
    raise Exception("Incorrect reply from Webex API. Status code: {}. Text: {}".format(r.status_code, r.text))
######################################################################################
#
# 4. Create a loop to print the type and title of each room.
print("\nList of available rooms:")
rooms = r.json()["items"]
for room in rooms:
    <!!!REPLACEME with print code to finish the loop>

#######################################################################################
# SEARCH FOR WEBEX ROOM TO MONITOR
#  - Searches for user-supplied room name.
#  - If found, print "found" message, else prints error.
#  - Stores values for later use by bot.
# DO NOT EDIT CODE IN THIS BLOCK
#######################################################################################

while True:
    roomNameToSearch = input("Which room should be monitored for the /seconds messages? ")
    roomIdToGetMessages = None
    
    for room in rooms:
        if(room["title"].find(roomNameToSearch) != -1):
            print ("Found rooms with the word " + roomNameToSearch)
            print(room["title"])
            roomIdToGetMessages = room["id"]
            roomTitleToGetMessages = room["title"]
            print("Found room: " + roomTitleToGetMessages)
            break

    if(roomIdToGetMessages == None):
        print("Sorry, I didn't find any room with " + roomNameToSearch + " in it.")
        print("Please try again...")
    else:
        break
        
######################################################################################
# WEBEX BOT CODE
#  Starts Webex bot to listen for and respond to /seconds messages.
######################################################################################

while True:
    time.sleep(1)
    GetParameters = {
                            "roomId": roomIdToGetMessages,
                            "max": 1
                    }
# 5. Provide the URL to the Webex messages API.    
    r = requests.get("<!!!REPLACEME with URL!!!>", 
                         params = GetParameters, 
                         headers = {"Authorization": accessToken}
                    )
    # verify if the retuned HTTP status code is 200/OK
    if not r.status_code == 200:
        raise Exception( "Incorrect reply from Webex API. Status code: {}. Text: {}".format(r.status_code, r.text))

    json_data = r.json()
    if len(json_data["items"]) == 0:
        raise Exception("There are no messages in the room.")
    
    messages = json_data["items"]
    message = messages[0]["text"]
    print("Received message: " + message)  
    
    if message.find("/") == 0:    
        if (message[1:].isdigit()):
            seconds = int(message[1:])  
        else:
            raise Exception("Incorrect user input.")
    
    #for the sake of testing, the max number of seconds is set to 5.
        if seconds > 5:
            seconds = 5    
            
        time.sleep(seconds)     
    
# 6. Provide the URL to the ISS Current Location API.         
        r = requests.get("<!!!REPLACEME with URL!!!>")
        
        json_data = r.json()
        
        if not json_data["message"] == "success":
            raise Exception("Incorrect reply from Open Notify API. Status code: {}".format(r.statuscode))

# 7. Record the ISS GPS coordinates and timestamp.

        lat = json_data["<!!!REPLACEME!!!> with path to latitude key!!!>"]
        lng = json_data["<!!!REPLACEME!!!> with path to longitude key!!!>"]
        timestamp = json_data["<!!!REPLACEME!!!> with path to timestamp key!!!>"]
        
# 8. Convert the timestamp epoch value to a human readable date and time.
        # Use the time.ctime function to convert the timestamp to a human readable date and time.
        timeString = <!!!REPLACEME with conversion code!!!>       
   
# 9. Provide your Graphhopper API consumer key.
    
        key = "<!!!RREPLACEME with your Graphhopper API key>"

# 10. Provide the URL to the Graphhopper GeoCoding API.
    # Get location information using the Graphhopper GeoCoding API service using the HTTP GET method
        GeoURL = "<!!! REPLACEME with Graphhopper GeoCoding API URL>"

        loc="&point="+lat+","+lng
        url = GeoURL + urllib.parse.urlencode({"key":key, "reverse":"true"}) + loc
        r = requests.get(url)

    # Verify if the returned JSON data from the Graphhopper API service are OK
        json_data = r.json()
    # check if the status key in the returned JSON data is "200"
        if not r.status_code == 200:
            raise Exception("Graphhopper Error message: " + json_data["message"])

# 11. Store the location received from the Graphhopper.
        if len(json_data["hits"]) != 0:
            CountryResult = json_data["<!!!REPLACEME!!!> with path to country key!!!>"]
            NameResult = json_data["<!!!REPLACEME!!!> with path to name key!!!>"]
            If "state" in json_data["hits"][0]:
                StateResult = json_data["<!!!REPLACEME!!!> with path to state key!!!>"]
            If "city" in json_data["hits"][0]:
                CityResult = json_data["<!!!REPLACEME!!!> with path to city key!!!>"]
            If "street" in json_data["hits"][0]:
                StreetResult = json_data["<!!!REPLACEME!!!> with path to street key!!!>"]
            If "housenumber" in json_data["hits"][0]:
                HouseResult = json_data["<!!!REPLACEME!!!> with path to housenumber key!!!>"]

# 12. Complete the code to format the response message.
#     Example responseMessage result: On Tue Mar 12 00:16:04 2024 (GMT), the ISS was flying over Mobert Creek, Canada. (47.4917°, -37.3643°)
        #responseMessage = "On {} (GMT), the ISS was flying over {}, {}. ({}\", {}\")".format(timeString, NameResult, CountryResult, lat, lng)

        if len(json_data["hits"]) == 0:
            responseMessage = "On {} (GMT), the ISS was flying over a body of water or unpopulated area at latitude {}° and longitude {}°.".format(timeString, lat, lng)

<!!!REPLACEME with if statements to compose the message to display the current ISS location in the Webex Team room!!!>
        else
        elif
       
        # print the response message
        print("Sending to Webex: " +responseMessage)

# 13. Complete the code to post the message to the Webex room.         
        # the Webex HTTP headers, including the Authoriztion and Content-Type
        HTTPHeaders = { 
                             "Authorization": <!!!REPLACEME!!!>,
                             "Content-Type": "application/json"
                           }
        
        PostData = {
                            "roomId": <!!!REPLACEME!!!>,
                            "text": <!!!REPLACEME!!!>
                        }
        # Post the call to the Webex message API.
        r = requests.post( "<!!!REPLACEME with URL!!!>", 
                              data = json.dumps(<!!!REPLACEME!!!>), 
                              headers = <!!!REPLACEME!!!>
                         )
        if not r.status_code == 200:
            raise Exception("Incorrect reply from Webex API. Status code: {}. Text: {}".format(r.status_code, r.text))
