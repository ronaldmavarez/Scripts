'use strict';

var clientContext = new SP.ClientContext.get_current();
var peopleManager = new SP.UserProfiles.PeopleManager(clientContext);
var userProfileProperties = peopleManager.getMyProperties()
var managerProfileProperties = [];
var profilePropertyNames = [];
var targetUser;

clientContext.load(userProfileProperties);
clientContext.executeQueryAsync(GetManagerObject, failure);

function GetManagerObject() {
    var profilePropertyNames = ["Manager"];
    targetUser = userProfileProperties.get_accountName();
    //var targetUser = "administrator";
    var userProfilePropertiesForUser = new SP.UserProfiles.UserProfilePropertiesForUser(clientContext, targetUser, profilePropertyNames);

    managerProfileProperties = peopleManager.getUserProfilePropertiesFor(userProfilePropertiesForUser);

    clientContext.load(userProfilePropertiesForUser);
    clientContext.executeQueryAsync(GetManagerDetails, failure);
};


function GetManagerDetails() {
    profilePropertyNames = ["PreferredName", "WorkPhone", "Title"];
    //var targetUser = managerProfileProperties[0];

    var userProfilePropertiesForUser = new SP.UserProfiles.UserProfilePropertiesForUser(clientContext, targetUser, profilePropertyNames);

    managerProfileProperties = peopleManager.getUserProfilePropertiesFor(userProfilePropertiesForUser);

    clientContext.load(userProfilePropertiesForUser);
    clientContext.executeQueryAsync(showDetails, failure);  
}

function showDetails() {

    for(var i=0; i < managerProfileProperties.length; i++){
        console.log("The value is: " + managerProfileProperties[i]);
    }
    
    //console.log(managerProfileProperties[0] + " - " + managerProfileProperties[1] + " - " + managerProfileProperties[2]);
    //console.log("The user is: " + );
}

function failure() {
    console.log("Failed");
};

