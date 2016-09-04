using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SharePoint;
using Microsoft.Office.Server.UserProfiles;
using Microsoft.Office.Server.SocialData;
using System.Web;
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Social;
using Microsoft.SharePoint.Client.Publishing;
using Microsoft.SharePoint.Client.UserProfiles;
using System.IO;

//using Microsoft.SharePoint.Client;


namespace SPConsole
{
    public class ProfilePropertiesCode
    {
        static void AddProfileProperty(string name, string displayName, bool isMultidValue)
        {
            using (SPSite oSite = new SPSite("http://servername"))
            {
                //SPServiceContext oServContext = SPServiceContext.GetContext(oSite);
                ClientContext clientContext = new ClientContext("http://svg-ronald:8080/");

                ProfilePropertyManager prfPropMgr;
                ProfileSubtypeManager prfTypeMgr;
                ProfileSubtypePropertyManager prftypePropMgr;
                ProfileTypePropertyManager typPropMgr;
                ProfileSubtypeProperty prfTypeProp;
                ProfileTypeProperty prfProp;
                ProfileSubtype prfType;
                CorePropertyManager corePropMgr;
                CoreProperty coreProp;

                //prfPropMgr = new UserProfileConfigManager(oServContext).ProfilePropertyManager;
                prfPropMgr = new UserProfileConfigManager().ProfilePropertyManager;
                //prfProp.Name = name;

                corePropMgr = prfPropMgr.GetCoreProperties();
                coreProp = corePropMgr.Create(false);
                coreProp.Name = name;
                coreProp.DisplayName = displayName;
                coreProp.IsMultivalued = isMultidValue;
                coreProp.Type = PropertyDataType.StringMultiValue;
                coreProp.Length = 1024;
                corePropMgr.Add(coreProp);

                typPropMgr = prfPropMgr.GetProfileTypeProperties(ProfileType.User);

                prfProp = typPropMgr.Create(coreProp);
                prfProp.IsVisibleOnViewer = true;
                typPropMgr.Add(prfProp);


                
                //prftypePropMgr.Add(prfTypeProp);

                prftypePropMgr = prfPropMgr.GetProfileSubtypeProperties(name);

                prfTypeProp = prftypePropMgr.Create(prfProp);
                prfTypeProp.IsUserEditable = true;
                prfTypeProp.DefaultPrivacy = Privacy.Public;
                prfTypeProp.UserOverridePrivacy = true;
                

                
                
            }
        }

        public static void ChangePicture(string userAccount){
            var clientContext = new ClientContext("http://svg-ronald:8080/");

            //var peopleManager = new PeopleManager();

            var peopleManager = new Microsoft.SharePoint.Client.UserProfiles.PeopleManager(clientContext);
            var personProperties = peopleManager.GetPropertiesFor(userAccount);

            clientContext.Load(personProperties);

            var sr = new System.IO.FileStream("C:/Users/Administrator/Desktop/Temp/SharePoint-2013-logo.png",FileMode.Open);
            peopleManager.SetMyProfilePicture(sr);

            clientContext.Load(peopleManager);
            clientContext.ExecuteQuery();

            //var up = upm.GetUserProfile(userAccount);
            //up.Commit();

        }

        public static void GettingUserProfileProperties() {
            var clientContext = new ClientContext("http://svg-ronald:8080");
            var peopleManager = new Microsoft.SharePoint.Client.UserProfiles.PeopleManager(clientContext);
            var accountName = "spdev\\administrator";

//            string[] prfProps = new string[] { "DisplayName", "Title" };
            //string[] prfProps = new string[] { "Manager", "FirstName" };


            //var usrPrfProps = new Microsoft.SharePoint.Client.UserProfiles.UserProfilePropertiesForUser(clientContext, accountName, prfProps);
            var profilePropertyValues = peopleManager.GetPropertiesFor(accountName);
            //var profilePropertyValues = peopleManager.GetMyProperties();

            clientContext.Load(profilePropertyValues);
            clientContext.ExecuteQuery();

            // Iterate through the property values.
            foreach (var property in profilePropertyValues.UserProfileProperties)
            {
                Console.Write(property.Key + ": " + property.Value + "\n");
            }
            Console.ReadKey(false);
        }

        public static void GettingSomeUserProfileProperties()
        {
            const string serverUrl = "http://svg-ronald";
            const string targetUser = "spdev\\administrator";

            // Connect to the client context.
            ClientContext clientContext = new ClientContext(serverUrl);

            // Get the PeopleManager object.
            Microsoft.SharePoint.Client.UserProfiles.PeopleManager peopleManager = new Microsoft.SharePoint.Client.UserProfiles.PeopleManager(clientContext);

            

            // Retrieve specific properties by using the GetUserProfilePropertiesFor method. 
            // The returned collection contains only property values.
            string[] profilePropertyNames = new string[] { "PreferredName", "DisplayName23", "Department", "Title", "AboutMe" };
            Microsoft.SharePoint.Client.UserProfiles.UserProfilePropertiesForUser profilePropertiesForUser = new Microsoft.SharePoint.Client.UserProfiles.UserProfilePropertiesForUser(
                clientContext, targetUser, profilePropertyNames);
            IEnumerable<string> profilePropertyValues = peopleManager.GetUserProfilePropertiesFor(profilePropertiesForUser);

            // Load the request and run it on the server.
            clientContext.Load(profilePropertiesForUser);
            clientContext.ExecuteQuery();

            // Iterate through the property values.
            foreach (var value in profilePropertyValues)
            {
                Console.Write(value + "\n");
            }
            Console.ReadKey(false);
        }

        public static void ReadingSocialFeed() {
            const string serverUrl = "http://svg-ronald";
            const string targetUser = "spdev\\administrator";

            // Connect to the client context.
            ClientContext clientContext = new ClientContext(serverUrl);

            SocialFeedManager sfm = new Microsoft.SharePoint.Client.Social.SocialFeedManager(clientContext);
            
        }
    }
}
