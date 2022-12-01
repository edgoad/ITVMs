###############################################################
# This program:
# - Asks the user to enter an access token or use the hard coded access token.
# - Lists the user's Webex rooms.
# - Asks the user which Webex room to monitor for "/seconds" of requests.
# - Monitors the selected Webex Team room every second for "/seconds" messages.
# - Discovers GPS coordinates of the ISS flyover using ISS API.
# - Display the geographical location using MapQuest API based on the GPS coordinates.
# - Formats and sends the results back to the Webex Team room.
#
# The student will:
# 1. Import libraries for API requests, JSON formatting, epoch time conversion, and iso3166.
# 2. Complete the if statement to ask the user for the Webex access token.
# 3. Provide the URL to the Webex room API.
# 4. Create a loop to print the type and title of each room.
# 5. Provide the URL to the Webex messages API.
# 6. Provide the URL to the ISS Current Location API.
# 7. Record the ISS GPS coordinates and timestamp.
# 8. Convert the timestamp epoch value to a human readable date and time.
# 9. Provide your MapQuest API consumer key.
# 10. Provide the URL to the MapQuest address API.
# 11. Store the location received from the MapQuest API in a variable.
# 12. Complete the code to format the response message.
# 13. Complete the code to post the message to the Webex room.
###############################################################
 
# 1. Import libraries for API requests, JSON formatting, epoch time conversion, and iso3166.

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
#######################################################################################

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
   
# 9. Provide your MapQuest API consumer key.
    
        mapsAPIGetParameters = { 
                                "lat": lat,
                                "lng": lng,
                                "key": "<!!!REPLACEME with your MapQuest API Key!!!>"
                               }
    
# 10. Provide the URL to the MapQuest Reverse GeoCode API.
    # Get location information using the MapQuest API reverse geocode service using the HTTP GET method
        r = requests.get("<!!!REPLACEME with URL!!!>", 
                             params = mapsAPIGetParameters
                        )

    # Verify if the returned JSON data from the MapQuest API service are OK
        json_data = r.json()
    # check if the status key in the returned JSON data is "0"
        if not json_data["info"]["statuscode"] == 0:
                raise Exception("Incorrect reply from MapQuest API. Status code: {}".format(r.statuscode))

# 11. Store the location received from the MapQuest API in a variable
        CountryResult = json_data["<!!!REPLACEME!!!> with path to adminArea1 key!!!>"]
        StateResult = json_data["<!!!REPLACEME!!!> with path to adminArea3 key!!!>"]
        CityResult = json_data["<!!!REPLACEME!!!> with path to adminArea4!!!>"]
        StreetResult = json_data["<!!!REPLACEME!!!> with path to street key!!!>"]

        #Find the country name using ISO3611 country code
        if not CountryResult == "XZ":
            CountryResult = countries.get(CountryResult).name

# 12. Complete the code to format the response message.
#     Example responseMessage result: In Austin, Texas the ISS will fly over on Thu Jun 18 18:42:36 2020 for 242 seconds.
        #responseMessage = "On {}, the ISS was flying over the following location: \n{} \n{}, {} \n{}\n({}\", {}\")".format(timeString, StreetResult, CityResult, StateResult, CountryResult, lat, lng)

        if CountryResult == "XZ":
            responseMessage = "On {}, the ISS was flying over a body of water at latitude {}° and longitude {}°.".format(timeString, lat, lng)
        
<!!!REPLACEME with if statements to compose the message to display the current ISS location in the Webex Team room!!!>
        elif
        else
       
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
                
