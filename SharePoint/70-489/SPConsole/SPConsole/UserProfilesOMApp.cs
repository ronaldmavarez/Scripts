using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Office.Server;
using Microsoft.Office.Server.Administration;
using Microsoft.Office.Server.UserProfiles;
using Microsoft.SharePoint;
using System.Web;
using Microsoft.SharePoint.Client;

namespace SPConsole
{
    class UserProfilesOMApp
    {
        static void Main(string[] args)
        {

            //string currentPath = System.IO.Path.GetDirectoryName("");

            //To get the location the assembly normally resides on disk or the install directory
            //string path = System.Reflection.Assembly.GetExecutingAssembly().CodeBase;

            //once you have the path you get the directory with:
            //var directory = System.IO.Path.GetDirectoryName(path);

            string directory = @"C:\Users\Administrator\Desktop\Temp\SPConsole\SPConsole\csv\ImportTermSet.csv";

            TermStoreCode.ImportCSV(directory, "http://svg-ronald");
            //TermStoreCode.GettingUserProfileProperties();
        }

        static void MaritalStatus() {
            
            //Code example adds a new property called Marital Status.
            using (SPSite site = new SPSite("http://servername"))
            {
                //SPServiceContext context = SPServiceContext.GetContext(site);
                //ClientContext context = new ClientContext(site);
                //ServerContext context = ServerContext.GetContext(site);
                UserProfileConfigManager upcm = new UserProfileConfigManager();

                try
                {
                    ProfilePropertyManager ppm = upcm.ProfilePropertyManager;

                    // create core property
                    CorePropertyManager cpm = ppm.GetCoreProperties();
                    CoreProperty cp = cpm.Create(false);
                    cp.Name = "MaritalStatus";
                    cp.DisplayName = "Marital Status";
                    cp.Type = PropertyDataType.StringSingleValue;
                    cp.Length = 100;

                    cpm.Add(cp);

                    // create profile type property
                    ProfileTypePropertyManager ptpm = ppm.GetProfileTypeProperties(ProfileType.User);
                    ProfileTypeProperty ptp = ptpm.Create(cp);

                    ptpm.Add(ptp);

                    // create profile subtype property
                    ProfileSubtypeManager psm = ProfileSubtypeManager.Get();
                    ProfileSubtype ps = psm.GetProfileSubtype(ProfileSubtypeManager.GetDefaultProfileName(ProfileType.User));
                    ProfileSubtypePropertyManager pspm = ps.Properties;
                    ProfileSubtypeProperty psp = pspm.Create(ptp);

                    psp.PrivacyPolicy = PrivacyPolicy.OptIn;
                    psp.DefaultPrivacy = Privacy.Organization;

                    pspm.Add(psp);
                }
                catch (DuplicateEntryException e)
                {
                    Console.WriteLine(e.Message);
                    Console.Read();
                }
                catch (System.Exception e2)
                {
                    Console.WriteLine(e2.Message);
                    Console.Read();
                }
            }
        }
    }
}
