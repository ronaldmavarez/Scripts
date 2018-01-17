//SharePoint JSOM 
//Run from the browser console 

var cc = SP.ClientContext.get_current();
var web = cc.get_web();
var user = web.get_currentUser();
var list = web.get_lists().getByTitle("Chemical Applications");
var item = list.getItemById(1); 
var targetUser = "domain\\user";

var newUser = web.ensureUser(targetUser);

cc.load(item);
cc.load(newUser);

cc.executeQueryAsync(function () {
    console.log("Found item, updating...");   
	
	item.set_item('Author', newUser);
	item.set_item('Editor', newUser);
	
    item.update();
    cc.executeQueryAsync(function() { console.log("Success"); }, function() { console.log("Error saving properties"); });
}, function() {
    console.log('Error loading item.');
});