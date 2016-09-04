'use strict';

var clientContext = new SP.ClientContext.get_current();
var peopleManager = new SP.UserProfiles.PeopleManager(clientContext);
var userProfileProperties = peopleManager.getMyProperties()
var managerProfileProperties = [];

clientContext.load(userProfileProperties);
clientContext.executeQueryAsync(GetManagerObject, failure);

function GetManagerObject() {
    var profilePropertyNames = ["Manager"];
    //var targetUser = userProfileProperties.get_accountName();
    var targetUser = "administrator";
    var userProfilePropertiesForUser = new SP.UserProfiles.UserProfilePropertiesForUser(clientContext, targetUser, profilePropertyNames);

    managerProfileProperties = peopleManager.getUserProfilePropertiesFor(userProfilePropertiesForUser);

    clientContext.load(userProfilePropertiesForUser);
    clientContext.executeQueryAsync(GetManagerDetails, failure);
};


function GetManagerDetails() {
    var profilePropertyNames = ["PreferredName", "WorkPhone", "Title"];
    var targetUser = managerProfileProperties[0];
    var userProfilePropertiesForUser = new SP.UserProfiles.UserProfilePropertiesForUser(clientContext, targetUser, profilePropertyNames);

    managerProfileProperties = peopleManager.getUserProfilePropertiesFor(userProfilePropertiesForUser);

    clientContext.load(userProfilePropertiesForUser);
    clientContext.executeQueryAsync(showDetails, failure);  
}

function showDetails() {
    console.log(managerProfileProperties[0] + " - " + managerProfileProperties[1] + " " + managerProfileProperties[2]);
}


function failure() {
    console.log("Failed");
};



function GetManagerDetails() {
    var clientContext = new SP.ClientContext.get_current();
    var peopleManager = new SP.UserProfiles.PeopleManager(clientContext);

    var profilePropertyNames = ["PreferredName", "WorkPhone", "Title"];
    var targetUser = "administrator";
    var userProfilePropertiesForUser = new SP.UserProfiles.UserProfilePropertiesForUser(clientContext, targetUser, profilePropertyNames);

    managerProfileProperties = peopleManager.getUserProfilePropertiesFor(userProfilePropertiesForUser);

    clientContext.load(userProfilePropertiesForUser);
    clientContext.executeQueryAsync(userProfilePropertiesForUser);
}