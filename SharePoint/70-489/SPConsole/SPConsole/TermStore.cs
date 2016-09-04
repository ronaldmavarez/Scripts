using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Taxonomy;
using System.IO;

namespace SPConsole
{
    class TermStoreCode
    {
        public static void ImportCSV(string csvPath, string SiteURL){
            SPSite oSite = new SPSite(SiteURL);
            SPWeb oWeb = oSite.OpenWeb();

            string groupName = "TermSetGroupImport";

            try
            {
                StreamReader reader = File.OpenText(csvPath);
                TaxonomySession session = new TaxonomySession(oSite);

                TermStore store = session.TermStores[0];
                var exist = from t in store.Groups where t.Name == groupName select t;

                Group group;
                
                if (exist == null) 
                    group = store.CreateGroup(groupName);
                else
                    group = exist.FirstOrDefault(); 

                ImportManager manager = store.GetImportManager();

                bool allTermsAdded = false;
                string errorMsg = string.Empty;

                manager.ImportTermSet(group, reader, out allTermsAdded, out errorMsg);

                if (errorMsg.Length > 0)
                    throw new Exception(errorMsg);
                
                
            }
            catch (Exception ex) {
                Console.WriteLine(ex);
            }


        }
    }

   
}
